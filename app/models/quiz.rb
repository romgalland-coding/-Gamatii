class Quiz < ApplicationRecord
  has_many :quiz_games, dependent: :destroy
  has_many :games, through: :quiz_games

  # Single source of truth for the 14-day rotation. Each theme drives BOTH the
  # seed (how we fetch matching games from RAWG) and answer_scope (how we filter
  # the local Game table). Keeping fetch + filter side by side stops the two
  # from drifting apart. Order is the rotation order: array index == position.
  #
  #   :fetch  — args passed to the seed's RAWG fetch (see db/seeds.rb)
  #   :filter — lambda narrowing a Game scope to this theme's eligible games
  def self.title_like(needle)
    ->(s) { s.where("title ILIKE ?", "%#{needle}%") }
  end

  def self.studio_like(needle)
    ->(s) { s.where("publisher ILIKE :n OR developer ILIKE :n", n: "%#{needle}%") }
  end

  def self.platform_is(name)
    ->(s) { s.where("? = ANY(platforms)", name) }
  end

  def self.genre_is(name)
    ->(s) { s.where(genre: name) }
  end

  # ILIKE on genre — RAWG's first-genre can be a variant (e.g. "RPG"), so match
  # loosely rather than pinning to one exact string.
  def self.genre_like(needle)
    ->(s) { s.where("genre ILIKE ?", "%#{needle}%") }
  end

  THEMES = [
    { name: "Top 5 Zelda games", fetch: { search: "zelda" }, filter: title_like("zelda") },
    { name: "Top 5 Mario games", fetch: { search: "mario" }, filter: title_like("mario") },
    { name: "Top 5 Resident Evil games", fetch: { search: "resident evil" }, filter: title_like("resident evil") },
    { name: "Top 5 Final Fantasy games", fetch: { search: "final fantasy" }, filter: title_like("final fantasy") },
    { name: "Top 5 Grand Theft Auto games", fetch: { search: "grand theft auto" }, filter: title_like("grand theft auto") },
    { name: "Top 5 Ubisoft games", fetch: { publisher: "ubisoft-entertainment" }, filter: studio_like("ubisoft") },
    { name: "Top 5 Blizzard games", fetch: { publisher: "blizzard-entertainment" }, filter: studio_like("blizzard") },
    { name: "Top 5 Rockstar games", fetch: { publisher: "rockstar-games" }, filter: studio_like("rockstar") },
    { name: "Top 5 PC games", fetch: { platform: "PC" }, filter: platform_is("PC") },
    { name: "Top 5 Nintendo Switch games", fetch: { platform: "Nintendo Switch" }, filter: platform_is("Nintendo Switch") },
    { name: "Top 5 PlayStation 5 games", fetch: { platform: "PlayStation 5" }, filter: platform_is("PlayStation 5") },
    { name: "Top 5 RPGs", fetch: { genre: "role-playing-games-rpg" }, filter: genre_like("RPG") },
    { name: "Top 5 Shooters", fetch: { genre: "shooter" }, filter: genre_is("Shooter") },
    { name: "Top 5 Indie games", fetch: { genre: "indie" }, filter: genre_is("Indie") }
  ].freeze

  THEME_BY_NAME = THEMES.index_by { |t| t[:name] }.freeze

  # Games eligible for this quiz, highest-rated first.
  def answer_scope
    theme  = THEME_BY_NAME[name]
    filter = theme ? theme[:filter] : ->(scope) { scope }
    filter.call(Game.all).order(rating: :desc)
  end

  # The top `limit` distinct games for this quiz. De-dupes by title because
  # picks imported from RAWG can create a second record for a game we already
  # seeded; ordered highest-rated first, so uniq keeps the best-rated copy.
  def answer_pool(limit)
    answer_scope.uniq { |game| game.title.to_s.downcase.strip }.first(limit)
  end
end
