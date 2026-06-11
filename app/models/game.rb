class Game < ApplicationRecord
  has_many :list_games, dependent: :destroy
  has_many :lists, through: :list_games

  has_many :quiz_games, dependent: :destroy
  has_many :quizzes, through: :quiz_games

  # Strip edition/version suffixes so "Ghost of Tsushima Director's Cut" and
  # "Ghost of Tsushima" compare as the same game. Used by the recommendation
  # tool to pick the closest RAWG result to a requested title.
  EDITION_SUFFIXES = /
    \s*[:\-–]\s*
    (director'?s\ cut|definitive\ edition|complete\ edition|
     game\ of\ the\ year|goty|remastered|enhanced\ edition|
     ultimate\ edition|anniversary\ edition|\w+\ edition)
    \s*$
  /xi

  def self.normalize_title(title)
    title.to_s.sub(EDITION_SUFFIXES, "").strip
  end

  # Find the game with this RAWG id, or fetch it from RAWG and save it.
  # Returns the local Game record. Used when a user picks a game that may
  # not be in our DB yet (quiz picks, list adds).
  def self.import_from_rawg(rawg_id)
    rawg_id = rawg_id.to_i
    rawg_data = RawgService.new.find(rawg_id)

    find_or_create_by(rawg_id: rawg_id) do |g|
      g.assign_attributes(rawg_attributes(rawg_data))
    end
  end

  # Translates a RAWG game hash into our column values. Shared by every code
  # path that imports from RAWG — the future daily-sync job reuses this too.
  def self.rawg_attributes(rawg_data)
    {
      title: rawg_data["name"],
      cover_img: rawg_data["background_image"],
      genre: rawg_data["genres"]&.map { |g| g["name"] }&.join(", "),
      platforms: rawg_data["platforms"]&.map { |p| p.dig("platform", "name") } || [],
      rating: rawg_data["metacritic"], # column holds the Metascore (0–100); see db/seeds.rb
      release_date: rawg_data["released"],
      publisher: rawg_data["publishers"]&.first&.dig("name"),
      developer: rawg_data["developers"]&.first&.dig("name"),
      description: rawg_data["description_raw"]&.slice(0, 2000),
      game_mode: game_modes_from(rawg_data["tags"])
    }
  end

  # Keep only the RAWG tags that represent a game mode (singleplayer, co-op…).
  def self.game_modes_from(tags)
    slugs = Array(tags).map { |t| t["slug"] }
    slugs & RawgService::GAME_MODE_SLUGS
  end
end
