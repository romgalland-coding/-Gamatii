class MessagesController < ApplicationController
  SYSTEM_PROMPT = <<~PROMPT
    You are a video game recommendation assistant. Your job is to recommend one game for the user to add to one of their lists.

    Follow these steps in order, asking one question at a time:
    1. Ask if they want to play solo, against friends, or team up with friends online.
    2. Ask which device they want to play on (only ask this if they mention or imply they have multiple devices).
    3. Ask what genre of game they're in the mood for and give some examples like RPG, FPS, open world, action, etc.

    Once you have all the answers, you MUST call the search_game tool before naming any game. Never mention a game title without calling the tool first.
    The game cannot already be in one of the user's lists.
    If the user skips a recommendation, or you receive an ACTION:ADDED or ACTION:SKIPPED message, call the search_game tool immediately to find a different game — no preamble, no apology, never repeat a game already mentioned or in the user's collection.
    Treat different editions, versions, or director's cuts of the same game as the same game (e.g. "Ghost of Tsushima Director's Cut" and "Ghost of Tsushima" are the same).
    Keep your responses short and conversational.
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
    owned    = titles_in_lists_of_type("played")
    wishlist = titles_in_lists_of_type("wishlist")
    devices  = current_user.platform.to_a.join(", ")

    <<~CONTEXT
      Here is what you know about the user:
        - Games they already own: #{owned.presence || 'none'}
        - Games on their wishlist: #{wishlist.presence || 'none'}
        - Devices they own: #{devices.presence || 'unknown'}
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
