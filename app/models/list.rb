class List < ApplicationRecord
  LIST_TYPES = ["wishlist", "played", "custom"]

  belongs_to :user
  has_many :list_games, dependent: :destroy
  has_many :games, through: :list_games

  validates :name, presence: true
  validates :name, uniqueness: { scope: :user_id, message: "You already have a list with this name" }
  validates :name, length: { maximum: 25 }
  validates :user_id, presence: true
  validates :list_type, presence: true, inclusion: { in: LIST_TYPES }
end
