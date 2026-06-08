# app/services/rawg_service.rb
class RawgService
  BASE_URL = "https://api.rawg.io/api"
  GAME_MODE_SLUGS = ["singleplayer", "multiplayer", "co-op", "split-screen", "online-multiplayer", "local-multiplayer"]

  CURATED_PUBLISHERS = [
    { id: "nintendo",                                                      name: "Nintendo" },
    { id: "sony-computer-entertainment,sony-interactive-entertainment",    name: "Sony" },
    { id: "microsoft-studios",                                             name: "Microsoft" },
    { id: "2k-games",                                                      name: "2K Games" },
    { id: "electronic-arts",                                               name: "Electronic Arts" },
    { id: "ubisoft-entertainment",                                         name: "Ubisoft" },
    { id: "activision-blizzard,activision",                                name: "Activision Blizzard" },
    { id: "bandai-namco-entertainment-us,bandai-namco-entertainment",      name: "Bandai Namco" },
    { id: "bethesda-softworks",                                            name: "Bethesda Softworks" },
    { id: "capcom",                                                        name: "Capcom" },
    { id: "cd-projekt-red",                                                name: "CD PROJEKT RED" },
    { id: "square-enix",                                                   name: "Square Enix" },
    { id: "eidos-interactive",                                             name: "Eidos Interactive" },
    { id: "konami",                                                        name: "Konami" },
    { id: "rockstar-games",                                                name: "Rockstar Games" },
    { id: "warner-bros-interactive",                                       name: "Warner Bros" },
    { id: "valve",                                                         name: "Valve" },
    { id: "thq,thq-nordic",                                                name: "THQ" },
    { id: "team17-digital",                                                name: "Team17" },
    { id: "telltale-games",                                                name: "Telltale Games" },
    { id: "disney-interactive",                                            name: "Disney Interactive" },
    { id: "devolver-digital",                                              name: "Devolver Digital" },
    { id: "505-games",                                                     name: "505 Games" },
    { id: "daedalic-entertainment",                                        name: "Daedalic Entertainment" },
    { id: "deep-silver",                                                   name: "Deep Silver" },
    { id: "paradox-interactive",                                           name: "Paradox Interactive" },
    { id: "1c-company,1c-softclub,aspyr,codemasters,feral-interactive,focus-home-interactive,kiss,lucasarts-entertainment,plug-in-digital,sega", name: "Other" },
  ].freeze

  CURATED_PLATFORMS = [
    { id: 187,    name: "PS5" },
    { id: 186,    name: "Xbox Series" },
    { id: 7,      name: "Nintendo Switch" },
    { id: 4,      name: "PC" },
    { id: "3,21", name: "Mobile" },
    { id: 18,     name: "PS4" },
    { id: 1,      name: "Xbox One" },
    { id: 8,      name: "3DS" },
    { id: 16,     name: "PS3" },
    { id: 14,     name: "Xbox 360" },
    { id: 10,     name: "Wii U" },
    { id: 19,     name: "PS Vita" },
    { id: 11,     name: "Wii" },
    { id: 9,      name: "DS" },
    { id: 15,     name: "PS2" },
    { id: 80,     name: "Xbox" },
    { id: 24,     name: "Game Boy Advance" },
    { id: 105,    name: "Gamecube" },
    { id: 17,     name: "PSP" },
    { id: 27,     name: "PS1" },
    { id: 83,     name: "Nintendo 64" },
    { id: 26,     name: "Game Boy" },
    { id: 79,     name: "SNES" },
    { id: 49,     name: "NES" },
  ].freeze

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
    base_query = { key: @api_key, page_size: 20 }
    base_query[:genres]     = Array(filters[:genres]).join(",")     if filters[:genres].present?
    base_query[:platforms]  = Array(filters[:platforms]).flat_map { |id| id.to_s.split(",") }.join(",") if filters[:platforms].present?
    base_query[:publishers] = Array(filters[:publishers]).flat_map { |id| id.to_s.split(",") }.join(",") if filters[:publishers].present?
    base_query[:tags]       = Array(filters[:game_modes]).join(",") if filters[:game_modes].present?
    base_query[:metacritic] = "#{filters[:rating]},100"                               if filters[:rating].present?
    base_query[:dates]      = "#{filters[:from]},#{filters[:to]}"                     if filters[:from].present? && filters[:to].present?

    if filters[:page]
      response = HTTParty.get("#{BASE_URL}/games", query: base_query.merge(page: filters[:page]))
      response["results"] || []
    else
      total = (filters[:limit].presence || 20).to_i
      pages = (total / 20.0).ceil
      (1..pages).flat_map do |page|
        response = HTTParty.get("#{BASE_URL}/games", query: base_query.merge(page: page))
        response["results"] || []
      end.first(total)
    end
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
