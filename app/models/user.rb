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

  has_one_attached :avatar

  has_many :lists, dependent: :destroy
  has_many :list_likes, dependent: :destroy
  has_many :quiz_games, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :quizzes, through: :quiz_games
  has_many :chats, dependent: :destroy
  has_many :messages, through: :chats

  # Following / followers (self-referential through `follows`)
  has_many :outgoing_follows, class_name: "Follow", foreign_key: :follower_id, dependent: :destroy
  has_many :following, through: :outgoing_follows, source: :followed

  has_many :incoming_follows, class_name: "Follow", foreign_key: :followed_id, dependent: :destroy
  has_many :followers, through: :incoming_follows, source: :follower

  validates :gamer_tag, presence: true, uniqueness: true, length: { maximum: 20 }
  validates :bio, length: { maximum: 500 }, allow_blank: true

  def follow(other_user)
    return if self == other_user

    outgoing_follows.find_or_create_by(followed: other_user)
  end

  def unfollow(other_user)
    outgoing_follows.find_by(followed: other_user)&.destroy
  end

  def following?(other_user)
    following.include?(other_user)
  end

  # Top lists by likes; used for the profile's "top lists" section.
  def top_lists(limit = 3)
    lists.order(votes_count: :desc).limit(limit)
  end
end
