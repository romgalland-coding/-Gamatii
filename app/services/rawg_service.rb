# app/services/rawg_service.rb
class RawgService
  BASE_URL = "https://api.rawg.io/api"

  def initialize
    @api_key = ENV["RAWG_API_KEY"]
  end

  def search(query)
    response = HTTParty.get("#{BASE_URL}/games", query: {
      key: @api_key,
      search: query,
      search_precise: true,
      page_size: 5
    })
    response["results"]
  end

  def find(id)
    response = HTTParty.get("#{BASE_URL}/games/#{id}", query: {
      key: @api_key
    })
    response.parsed_response
  end

  def genres_discovery
    response = HTTParty.get("#{BASE_URL}/genres", query: { key: @api_key })
    response["results"].map { |g| { id: g["slug"], name: g["name"] } }
  end

  def platforms
    response = HTTParty.get("#{BASE_URL}/platforms", query: { key: @api_key })
    response["results"].map { |p| { id: p["id"], name: p["name"] } }
  end

  def publishers
    response = HTTParty.get("#{BASE_URL}/publishers", query: { key: @api_key, page_size: 40 })
    response["results"].map { |p| { id: p["slug"], name: p["name"] } }
  end

  def tags
    game_mode_slugs = ["singleplayer", "multiplayer", "co-op", "split-screen", "online-multiplayer", "local-multiplayer"]
    response = HTTParty.get("#{BASE_URL}/tags", query: { key: @api_key, page_size: 40 })
    response["results"]
      .select { |t| game_mode_slugs.include?(t["slug"]) }
      .map { |t| { id: t["slug"], name: t["name"] } }
  end

  def search_games(filters = {})
    query = { key: @api_key, page_size: 20 }
    query[:genres]     = filters[:genre]                                          if filters[:genre].present?
    query[:platforms]  = Array(filters[:platforms]).join(",")                       if filters[:platforms].present?
    query[:publishers] = filters[:publisher]                                      if filters[:publisher].present?
    query[:tags]       = filters[:game_mode]                                      if filters[:game_mode].present?
    query[:metacritic] = "#{filters[:rating]},100"                               if filters[:rating].present?
    query[:dates]      = "#{filters[:from]},#{filters[:to]}"                     if filters[:from].present? && filters[:to].present?

    response = HTTParty.get("#{BASE_URL}/games", query: query)
    response["results"] || []
  end

  def by_genre(genre_name, exclude_rawg_id:, devices: [])
    genre_slug = genre_name.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/-+\z/, '')
    platform_ids = platform_ids_for(devices)

    query = {
      key:      @api_key,
      genres:   genre_slug,
      ordering: "-metacritic",
      page_size: 10
    }
    query[:platforms] = platform_ids.join(",") if platform_ids.any?

    response = HTTParty.get("#{BASE_URL}/games", query: query)
    results = response["results"] || []
    results.reject { |g| g["id"] == exclude_rawg_id }
  end

  private

  def platform_ids_for(devices)
    mapping = {
      "PC"              => 4,
      "PlayStation 5"   => 187,
      "PlayStation 4"   => 18,
      "PlayStation 3"   => 16,
      "Xbox Series S/X" => 186,
      "Xbox One"        => 1,
      "Xbox 360"        => 14,
      "Nintendo Switch" => 7,
      "Nintendo 3DS"    => 8,
      "iOS"             => 3,
      "Android"         => 21,
      "macOS"           => 5,
      "Linux"           => 6
    }
    devices.filter_map { |d| mapping[d] }
  end
end
