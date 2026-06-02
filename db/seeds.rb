require "httparty"

API_KEY = ENV.fetch("RAWG_API_KEY") { ENV.fetch("RAW_API_KEY", "") }
BASE_URL = "https://api.rawg.io/api"

# ── Helpers ──────────────────────────────────────────────────────────────────

def rawg_get(path, params = {})
  response = HTTParty.get("#{BASE_URL}#{path}", query: params.merge(key: API_KEY))
  response.parsed_response
rescue StandardError => e
  puts "  [RAWG error] #{e.message}"
  {}
end

def game_modes_from_tags(tags)
  mapping = { "singleplayer" => "Single Player", "multiplayer" => "Multiplayer",
              "co-op" => "Co-op", "online-co-op" => "Co-op", "local-co-op" => "Co-op" }
  (tags || []).filter_map { |t| mapping[t["slug"]] }.uniq
end

# ── Clean slate ───────────────────────────────────────────────────────────────

puts "Cleaning previous seed data…"
seed_emails = %w[pixelknight@gmail.com neonbyte@gmail.com vortexcaster@gmail.com]
User.where(email: seed_emails).each do |u|
  u.lists.each { |l| l.list_games.destroy_all }
  u.lists.destroy_all
  u.destroy
end
Game.destroy_all

# ── Fetch ~50 games from RAWG ─────────────────────────────────────────────────

puts "Fetching game catalogue from RAWG…"
rawg_list = []
[1, 2].each do |page|
  result = rawg_get("/games", ordering: "-metacritic", page_size: 25, page: page)
  rawg_list += (result["results"] || [])
  sleep 0.3
end
puts "  #{rawg_list.size} games fetched from catalogue."

# ── Fetch detail + create Game records ────────────────────────────────────────

puts "Fetching game details and creating records…"
games = rawg_list.filter_map do |g|
  detail = rawg_get("/games/#{g['id']}")
  sleep 0.2

  platforms_str = g["platforms"]&.map { |p| p.dig("platform", "name") }&.join(", ")
  modes         = game_modes_from_tags(detail["tags"])

  print "."
  Game.create!(
    title:        g["name"],
    cover_img:    g["background_image"],
    in_game_img:  g.dig("short_screenshots", 1, "image"),
    genre:        g.dig("genres", 0, "name"),
    platforms:    platforms_str,
    rating:       g["rating"],
    release_date: g["released"],
    description:  detail["description_raw"]&.slice(0, 2000),
    developer:    detail.dig("developers", 0, "name"),
    publisher:    detail.dig("publishers", 0, "name"),
    game_mode:    modes
  )
rescue ActiveRecord::RecordNotUnique
  Game.find_by(title: g["name"])
rescue StandardError => e
  puts "\n  [skip] #{g['name']}: #{e.message}"
  nil
end.compact
puts "\n  #{games.size} Game records created."

# ── Users + Lists ─────────────────────────────────────────────────────────────

SEED_USERS = [
  {
    email:    "pixelknight@gmail.com",
    password: "password",
    gamer_tag: "PixelKnight",
    platform: ["PC", "Nintendo Switch"],
    lists: [
      { name: "Wishlist",       list_type: "wishlist", range: 0..9  },
      { name: "Played",         list_type: "played",   range: 10..24 },
      { name: "Indie Gems",     list_type: "custom",   range: 25..33 }
    ]
  },
  {
    email:    "neonbyte@gmail.com",
    password: "password",
    gamer_tag: "NeonByte",
    platform: ["PlayStation 5", "PlayStation 4"],
    lists: [
      { name: "Wishlist",         list_type: "wishlist", range: 4..13  },
      { name: "Played",           list_type: "played",   range: 14..28 },
      { name: "Open World Picks", list_type: "custom",   range: 29..37 }
    ]
  },
  {
    email:    "vortexcaster@gmail.com",
    password: "password",
    gamer_tag: "VortexCaster",
    platform: ["Xbox Series S/X", "Xbox One", "PC"],
    lists: [
      { name: "Wishlist",          list_type: "wishlist", range: 2..11  },
      { name: "Played",            list_type: "played",   range: 12..26 },
      { name: "Multiplayer Favs",  list_type: "custom",   range: 27..35 }
    ]
  }
]

puts "\nCreating users and lists…"
SEED_USERS.each do |data|
  user = User.create!(
    email:    data[:email],
    password: data[:password],
    gamer_tag: data[:gamer_tag],
    platform: data[:platform]
  )

  data[:lists].each do |ldata|
    list = user.lists.create!(name: ldata[:name], list_type: ldata[:list_type])
    slice = games[ldata[:range]] || []
    slice.each { |game| list.list_games.create!(game: game) }
    puts "  #{user.gamer_tag} › #{list.name} (#{ldata[:list_type].first}): #{slice.size} games"
  end
end

puts "\nSeed complete!"
