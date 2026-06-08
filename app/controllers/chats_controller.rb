class ChatsController < ApplicationController
  def show
    @chat = current_user.chats.find(params[:id])
    authorize @chat
    @messages = @chat.messages
    @limit_reached = @messages.where(role: "user").count >= Message::MAX_USER_MESSAGES
  end

  def create
    @chat = current_user.chats.build(title: Chat::DEFAULT_TITLE)
    authorize @chat

    if @chat.save
      opening = RubyLLM.chat
                       .with_instructions(MessagesController::SYSTEM_PROMPT)
                       .ask("start") rescue nil

      @chat.messages.create!(
        role: "assistant",
        content: opening&.content.presence || "What are you in the mood for today?"
      )

      redirect_to chat_path(@chat)
    else
      redirect_to discover_path, alert: "Could not start a new chat."
    end
  end
end
