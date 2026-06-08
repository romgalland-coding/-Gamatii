class MessagesController < ApplicationController
  SYSTEM_PROMPT = <<~PROMPT

  You are a video game recommendation assistant. Your job is to recommend games for the user to add to one of their lists.

  At the start of the conversation, ask a single discovery question that gathers all of the following:

  * Whether they want to play solo, compete against friends, or team up with friends online.
  * Which device they want to play on (PC, PlayStation, Xbox, Switch, Steam Deck, etc.).
  * What kind of game they're in the mood for, with examples such as RPG, FPS, open world, action-adventure, strategy, survival, racing, simulation, indie, etc.
  * Whether they are looking for a game similar to another game they enjoyed.

  Example opening question:

  "What are you in the mood for today? Are you looking to play solo, compete with friends, or team up online? What platform are you playing on, and what kind of game sounds fun right now (RPG, FPS, open world, action, strategy, etc.)? Or are you looking for something similar to a game you already love?"

  After the user's answer, reason about:

  * Preferred play style (solo, competitive, co-op).
  * Platform availability.
  * Genre preferences.
  * Similar games they mention.
  * The games already present in their lists.

  Once you have enough information, you MUST call the search_game tool before naming any game. Never mention a game title without calling the tool first.

  The recommended game cannot already exist in one of the user's lists.

  If the user skips a recommendation, or you receive an ACTION:ADDED or ACTION:SKIPPED message, immediately call the search_game tool to find another game:

  * No preamble.
  * No apology.
  * No additional questions unless absolutely necessary.
  * Never repeat a game already mentioned.
  * Never recommend a game already present in the user's collection.

  Treat different editions, remasters, versions, or director's cuts of the same game as the same game (for example, "Ghost of Tsushima" and "Ghost of Tsushima Director's Cut" are the same game).

  Keep responses short, conversational, and focused on helping the user discover their next game.
  PROMPT

  def create
    @chat = current_user.chats.find(params[:chat_id])
    authorize @chat, :show? # ownership check; satisfies Pundit's verify_authorized

    @ruby_llm_chat = RubyLLM.chat
    build_conversation_history
    @message = @chat.messages.create!(message_params.merge(role: "user"))
    @assistant_message = @chat.messages.create!(role: "assistant", content: "")
    @search_game_tool = SearchGameTool.new
    ask_llm
    finalize_assistant_message
    @chat.generate_title_from_conversation
    notify_limit_if_reached
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end

  # Feed prior messages to the LLM as context. Runs before the new user message
  # is persisted, so it only ever sees the conversation up to this point.
  def build_conversation_history
    @chat.messages.each do |message|
      next if message.content.blank?

      @ruby_llm_chat.add_message(role: message.role, content: message.content)
    end
  end

  def ask_llm
    @ruby_llm_chat.with_instructions(instructions)
    @ruby_llm_chat.with_tool(@search_game_tool)
    @ruby_llm_chat.ask(@message.content) do |chunk|
      next if chunk.content.blank?

      @assistant_message.content += chunk.content
      broadcast_content(@assistant_message)
    end
  end

  def finalize_assistant_message
    @assistant_message.update(
      content: @assistant_message.content,
      game: @search_game_tool.found_game
    )
    broadcast_full_replace(@assistant_message)
  end

  def notify_limit_if_reached
    return unless @chat.messages.where(role: "user").count >= Message::MAX_USER_MESSAGES

    @limit_reached = true
    @chat.messages.create!(
      role: "assistant",
      content: "You've reached your #{Message::MAX_USER_MESSAGES} messages limit for this chat."
    )
  end

  # During streaming: update only the text (target _content) so we never wipe
  # out a recommendation card that has already been rendered.
  def broadcast_content(message)
    Turbo::StreamsChannel.broadcast_update_to(
      @chat,
      target: helpers.dom_id(message, :content),
      partial: "messages/message_content",
      locals: { message: message }
    )
  end

  # After streaming: replace the whole message (text + recommendation card).
  def broadcast_full_replace(message)
    Turbo::StreamsChannel.broadcast_replace_to(
      @chat,
      target: helpers.dom_id(message),
      partial: "messages/message",
      locals: { message: message }
    )
  end

  # What the assistant knows about the user, drawn from their Lists (not a
  # per-user games table — that's matIA's model, not ours) and their platforms.
  def user_context
    played   = titles_in_lists_of_type("played")
    wishlist = titles_in_lists_of_type("wishlist")
    customs = titles_in_lists_of_type("custom")
    # devices  = current_user.platform.to_a.join(", ")

    <<~CONTEXT
      Here is what you know about the user:
        - Games they already own: #{played.presence || 'none'}
        - Games on their wishlist: #{wishlist.presence || 'none'}
        - Games on their custom lists: #{customs.presence || 'none'}
    CONTEXT
  end

  def titles_in_lists_of_type(list_type)
    Game.joins(list_games: :list)
        .where(lists: { user_id: current_user.id, list_type: list_type })
        .distinct
        .pluck(:title)
        .map { |title| Game.normalize_title(title) }
        .uniq
        .join(", ")
  end

  def instructions
    [SYSTEM_PROMPT, user_context].compact.join("\n\n")
  end
end
