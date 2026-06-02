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
