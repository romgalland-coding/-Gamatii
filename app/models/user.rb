class User < ApplicationRecord
  PLATFORMS = [
    "PC",
    "PlayStation 5",
    "PlayStation 4",
    "PlayStation 3",
    "Xbox Series S/X",
    "Xbox One",
    "Xbox 360",
    "Nintendo Switch",
    "Nintendo 3DS",
    "iOS",
    "Android",
    "macOS",
    "Linux"
  ].freeze

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :lists, dependent: :destroy
  has_many :quiz_games, dependent: :destroy
  has_many :quizzes, through: :quiz_games

  validates :gamer_tag, presence: true, uniqueness: true, length: { maximum: 20 }
end
