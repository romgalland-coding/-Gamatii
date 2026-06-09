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

  # Fallback palette for users with no avatar_color set, keyed off the record id
  # so each user gets a stable tile color even without seeded data.
  AVATAR_COLORS = %w[#F6C453 #A7D7A0 #9EC5FE #F4A8C0 #C4B5FD #FCD9A8 #9AE6D5].freeze

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]

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

  # Every new account starts with an empty Played list and Wishlist. Covers
  # both the Devise sign-up and Google OmniAuth paths (both persist via create).
  after_create :create_default_lists

  # Finds or creates the user behind a Google OmniAuth response. Matches an
  # existing record by provider+uid, then by email (so password users can also
  # sign in with Google), and otherwise creates a new account with a random
  # password and an auto-generated unique gamer_tag the user can edit later.
  def self.from_omniauth(auth)
    user = find_by(provider: auth.provider, uid: auth.uid) ||
           find_by(email: auth.info.email)

    user ||= new(email: auth.info.email, password: Devise.friendly_token[0, 20],
                 gamer_tag: generate_unique_gamer_tag(auth.info.name || auth.info.email))

    user.update(provider: auth.provider, uid: auth.uid)
    user
  end

  # Builds a gamer_tag (max 20 chars) from a name/email seed and appends a
  # numeric suffix until it's unique.
  def self.generate_unique_gamer_tag(seed)
    base = seed.to_s.split("@").first.gsub(/[^a-zA-Z0-9]/, "")
    base = "gamer" if base.blank?
    base = base[0, 16]

    candidate = base
    suffix = 0
    while exists?(gamer_tag: candidate)
      suffix += 1
      candidate = "#{base[0, 16 - suffix.to_s.length]}#{suffix}"
    end
    candidate
  end

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

  # The colored tile background for the emoji avatar; falls back to a stable
  # palette pick when no color was seeded.
  def avatar_background
    avatar_color.presence || AVATAR_COLORS[id % AVATAR_COLORS.size]
  end

  # The glyph shown on the avatar tile: the seeded emoji, or the first two
  # letters of the gamer_tag as a fallback.
  def avatar_glyph
    avatar_emoji.presence || gamer_tag.to_s.first(2).upcase
  end

  private

  def create_default_lists
    lists.create!(name: "Played",   list_type: "played")
    lists.create!(name: "Wishlist", list_type: "wishlist")
  end
end
