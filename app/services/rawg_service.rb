# app/services/rawg_service.rb
class RawgService
  BASE_URL = "https://api.rawg.io/api"
  GAME_MODE_SLUGS = ["singleplayer", "multiplayer", "co-op", "split-screen", "online-multiplayer", "local-multiplayer"]

  def initialize
    @api_key = ENV["RAWG_API_KEY"]
  end

  def search(query)
    # search_precise prioritizes strong title matches; we deliberately omit an
    # explicit ordering so RAWG sorts by relevance rather than date added.
    response = HTTParty.get("#{BASE_URL}/games", query: {
      key: @api_key,
      search: query,
      search_precise: true,
      page_size: 15
    })
    response["results"]
  end

  def find(id)
    response = HTTParty.get("#{BASE_URL}/games/#{id}", query: {
      key: @api_key
    })
    response.parsed_response
  end

  # The four "filter option" lists below are effectively static (RAWG's catalog
  # of genres/platforms/publishers/tags rarely changes), so we cache them for a
  # day to keep them out of the request path. See ApplicationController#load_rawg_filter_options.
  FILTER_OPTIONS_TTL = 1.day

  def genres_discovery
    Rails.cache.fetch("rawg/genres_discovery", expires_in: FILTER_OPTIONS_TTL) do
      response = HTTParty.get("#{BASE_URL}/genres", query: { key: @api_key })
      response["results"].map { |g| { id: g["slug"], name: g["name"] } }
    end
  end

  def platforms
    Rails.cache.fetch("rawg/platforms_v2", expires_in: FILTER_OPTIONS_TTL) do
      response = HTTParty.get("#{BASE_URL}/platforms", query: { key: @api_key })
      response["results"].map { |p| { id: p["id"], name: p["name"], year: p["year_start"].to_i } }
    end
  end

  def publishers
    Rails.cache.fetch("rawg/publishers", expires_in: FILTER_OPTIONS_TTL) do
      response = HTTParty.get("#{BASE_URL}/publishers", query: { key: @api_key, page_size: 40 })
      response["results"].map { |p| { id: p["slug"], name: p["name"] } }
    end
  end

  def tags
    Rails.cache.fetch("rawg/tags", expires_in: FILTER_OPTIONS_TTL) do
      response = HTTParty.get("#{BASE_URL}/tags", query: { key: @api_key, page_size: 40 })
      response["results"]
      .select { |t| GAME_MODE_SLUGS.include?(t["slug"]) }
        .map { |t| { id: t["slug"], name: t["name"] } }
    end
  end

  def search_games(filters = {})
    query = { key: @api_key, page_size: 20 }
    query[:genres]     = Array(filters[:genres]).join(",")     if filters[:genres].present?
    query[:platforms]  = Array(filters[:platforms]).join(",")  if filters[:platforms].present?
    query[:publishers] = Array(filters[:publishers]).join(",") if filters[:publishers].present?
    query[:tags]       = Array(filters[:game_modes]).join(",") if filters[:game_modes].present?
    query[:metacritic] = "#{filters[:rating]},100"                               if filters[:rating].present?
    query[:dates]      = "#{filters[:from]},#{filters[:to]}"                     if filters[:from].present? && filters[:to].present?

    response = HTTParty.get("#{BASE_URL}/games", query: query)
    response["results"] || []
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
