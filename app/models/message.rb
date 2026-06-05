class Message < ApplicationRecord
  MAX_USER_MESSAGES = 10

  belongs_to :chat
  belongs_to :game, optional: true

  validate :user_message_limit, if: -> { role == "user" }

  after_create_commit :broadcast_append_to_chat

  # Hidden messages drive the conversation (e.g. "ACTION:ADDED …" sent when the
  # user acts on a recommendation) but are never rendered as a chat bubble.
  def hidden?
    content.to_s.start_with?("ACTION:")
  end

  private

  def user_message_limit
    if chat.messages.where(role: "user").count >= MAX_USER_MESSAGES
      errors.add(:content, "You've reached the limit of #{MAX_USER_MESSAGES} messages per chat.")
    end
  end

  def broadcast_append_to_chat
    broadcast_append_to chat, target: "chat-messages", partial: "messages/message", locals: { message: self }
  end
end
