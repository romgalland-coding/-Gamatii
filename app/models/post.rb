class Post < ApplicationRecord
  belongs_to :user
  belongs_to :list, optional: true
  has_many :comments, dependent: :destroy
  has_many :likes, as: :likeable, dependent: :destroy
  validates :body, length: { maximum: 2000 }
  validates :url, format: { with: URI::regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true
  validates :photo_url, format: { with: URI::regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true
  validate :body_or_photo_or_url_present

  private

  def body_or_photo_or_url_present
    return if body.present? || photo_url.present? || url.present? || list_id.present?

    errors.add(:base, "A post must have text, a photo, or a URL")
  end
end
