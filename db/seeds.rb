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

# RAWG platform name → numeric id (mirrors RawgService#platform_ids_for).
PLATFORM_IDS = {
  "PC" => 4, "PlayStation 5" => 187, "PlayStation 4" => 18,
  "Xbox Series S/X" => 186, "Xbox One" => 1, "Nintendo Switch" => 7
}.freeze

# Fetch a theme's candidate games from RAWG.
#
# RAWG's "-rating" sort is driven by its user rating, which a handful of votes
# can inflate — so it surfaces obscure junk (a 4.8-rated game with 6 ratings and
# no Metascore) above famous titles. We avoid it two ways:
#   * filter themes (genre/platform/publisher) sort by "-added" (library adds, a
#     reliable popularity signal) and require a Metascore, dropping unreviewed junk.
#   * search themes (franchises) can't be server-sorted under search_precise, so
#     we fetch wide and clean locally: keep only Metascored games, most-added first.
def fetch_for_theme(fetch_spec)
  if fetch_spec[:search]
    results = rawg_get("/games", search: fetch_spec[:search], search_precise: true, page_size: 40)["results"] || []
    return results.select { |g| g["metacritic"] }.sort_by { |g| -(g["added"] || 0) }.first(12)
  end

  query = { ordering: "-added", metacritic: "1,100", page_size: 12 }
  if fetch_spec[:publisher]
    query[:publishers] = fetch_spec[:publisher]
  elsif fetch_spec[:platform]
    query[:platforms] = PLATFORM_IDS.fetch(fetch_spec[:platform])
  elsif fetch_spec[:genre]
    query[:genres] = fetch_spec[:genre]
  end
  (rawg_get("/games", query)["results"] || [])
end

# Create (or reuse) a Game record from a RAWG list entry, fetching detail for
# the fields the list endpoint omits. Returns the Game or nil on failure.
def upsert_game(g)
  existing = Game.find_by(rawg_id: g["id"])
  return existing if existing

  detail = rawg_get("/games/#{g['id']}")
  sleep 0.2
  platforms_arr = g["platforms"]&.map { |p| p.dig("platform", "name") } || []

  Game.create!(
    rawg_id:      g["id"],
    title:        g["name"],
    cover_img:    g["background_image"],
    in_game_img:  g.dig("short_screenshots", 1, "image"),
    screenshots:  (g["short_screenshots"] || []).filter_map { |s| s["image"] }[1..3].to_a,
    genre:        g.dig("genres", 0, "name"),
    platforms:    platforms_arr,
    # `rating` stores the Metascore (0–100), not RAWG's user rating — the UI
    # already labels this column "Metacritic" (lists filter) and the quiz ranks
    # the top 5 by it. RAWG's user rating is too easily inflated by a few votes.
    rating:       g["metacritic"] || detail["metacritic"],
    release_date: g["released"],
    description:  detail["description_raw"]&.slice(0, 2000),
    developer:    detail.dig("developers", 0, "name"),
    publisher:    detail.dig("publishers", 0, "name"),
    game_mode:    game_modes_from_tags(detail["tags"])
  )
rescue ActiveRecord::RecordNotUnique
  Game.find_by(rawg_id: g["id"]) || Game.find_by(title: g["name"])
rescue StandardError => e
  puts "\n  [skip] #{g['name']}: #{e.message}"
  nil
end

# ── Clean slate ───────────────────────────────────────────────────────────────

puts "Cleaning previous seed data…"
curated_emails = %w[pixelknight@gmail.com neonbyte@gmail.com vortexcaster@gmail.com]
# Generated users all share the @seed.gamatii domain so we can wipe them by pattern,
# however many there are this run.
User.where(email: curated_emails).or(User.where("email LIKE ?", "%@seed.gamatii")).each do |u|
  u.lists.each { |l| l.list_games.destroy_all }
  u.lists.destroy_all
  u.destroy
end
Game.destroy_all

# ── Fetch games for each of the 14 quiz themes ────────────────────────────────
# Drive seeding from Quiz::THEMES so every quiz has a full answer pool. Each
# theme contributes ~12 candidates; the union becomes the catalogue the rest of
# the seed (users' lists) draws from too.

puts "Fetching games for each quiz theme from RAWG…"
games = []
Quiz::THEMES.each do |theme|
  candidates = fetch_for_theme(theme[:fetch])
  sleep 0.3
  created = candidates.filter_map { |g| upsert_game(g) }
  games.concat(created)
  print "  #{theme[:name]}: #{created.size} games\n"
end
games.uniq!(&:id)
puts "  #{games.size} distinct Game records created."

# ── Verify every theme can fill a top-5 ───────────────────────────────────────

puts "\nVerifying answer pools…"
shortfalls = Quiz::THEMES.filter_map do |theme|
  count = Quiz.new(name: theme[:name]).answer_scope.count
  status = count >= 5 ? "ok" : "SHORT"
  puts "  [#{status}] #{theme[:name]}: #{count} eligible"
  theme[:name] if count < 5
end
puts "  ⚠️  Under-filled themes: #{shortfalls.join(', ')}" if shortfalls.any?

# ── Users + Lists ─────────────────────────────────────────────────────────────
# Every user draws their lists from the *same* shared `games` array fetched above —
# no per-user API calls. Lists are filled with seeded-random samples so the home
# page looks varied while staying reproducible across re-seeds.

# Deterministic RNG: same seed in → same roster out, every time.
rng = Random.new(20_260_605)

# Each list spec gives a name, type, and how many games to sample for it.
LIST_SPECS = [
  { name: "Wishlist", list_type: "wishlist", count: 10 },
  { name: "Played",   list_type: "played",   count: 15 },
  { name: "Favorites", list_type: "custom",  count: 9 }
].freeze

# The 3 curated users keep their identities (handy for demoing a known login).
CURATED_USERS = [
  { email: "pixelknight@gmail.com",  gamer_tag: "PixelKnight",  platform: ["PC", "Nintendo Switch"] },
  { email: "neonbyte@gmail.com",     gamer_tag: "NeonByte",     platform: ["PlayStation 5", "PlayStation 4"] },
  { email: "vortexcaster@gmail.com", gamer_tag: "VortexCaster", platform: ["Xbox Series S/X", "Xbox One", "PC"] }
].freeze

# Generate the rest of the roster up to 15 total. Tags are picked from a pool so
# every user reads like a real gamer handle.
TAG_POOL = %w[
  ShadowFox GlitchWizard ByteRunner CrimsonAce FrostByte
  TurboNova PhantomDrift QuasarKid EmberWolf StarlitHex
  RogueCircuit ApexRaven LunarSpecter VoidStriker NitroGhost
]
generated_count = 15 - CURATED_USERS.size
generated_users = TAG_POOL.first(generated_count).map do |tag|
  {
    email:    "#{tag.downcase}@seed.gamatii",
    gamer_tag: tag,
    platform: User::PLATFORMS.sample(rng.rand(1..3), random: rng)
  }
end

ALL_USERS = CURATED_USERS + generated_users

puts "\nCreating #{ALL_USERS.size} users and their lists…"
ALL_USERS.each do |data|
  user = User.create!(
    email:    data[:email],
    password: "password",
    gamer_tag: data[:gamer_tag],
    platform: data[:platform]
  )

  LIST_SPECS.each do |ldata|
    list = user.lists.create!(name: ldata[:name], list_type: ldata[:list_type])
    sample = games.sample(ldata[:count], random: rng)
    sample.each { |game| list.list_games.create!(game: game) }
    puts "  #{user.gamer_tag} › #{list.name} (#{ldata[:list_type]}): #{sample.size} games"
  end
end

# ── Daily Quizzes (14-day rotation) ───────────────────────────────────────────
# One quiz per theme, positioned by its index in Quiz::THEMES — that index is
# the rotation order the daily job walks through.

puts "\nCreating daily quizzes…"
Quiz.destroy_all
Quiz::THEMES.each_with_index do |theme, position|
  Quiz.create!(name: theme[:name], position: position)
end
puts "  #{Quiz::THEMES.size} quizzes created (positions 0–#{Quiz::THEMES.size - 1})."

# ── Leaderboard guesses for EVERY quiz ────────────────────────────────────────
# In test mode the "yesterday" quiz changes each rotation window, so we seed the
# 3 users guesses on all 14 quizzes — whatever the rotation lands on, the score
# screen shows a populated leaderboard. The correct-count is varied per quiz (by
# position) so different quizzes produce different rankings. Scoring matches by
# title, so we point guesses at the real answer-pool games.

puts "\nSeeding leaderboard guesses + reference picks on every quiz…"
# Seed guesses for the whole roster so every leaderboard is full. Each user gets a
# base correct-count (0–5, spread across the roster), rotated by quiz position so
# the ranking shuffles from one quiz to the next.
seed_users  = User.where(email: curated_emails).or(User.where("email LIKE ?", "%@seed.gamatii")).to_a
base_counts = seed_users.each_index.map { |i| (i % 6) }  # cycles 0..5 across users

Quiz.order(:position).each do |quiz|
  answers = quiz.answer_pool(5)
  next if answers.empty?

  seed_users.each_with_index do |user, i|
    # GUESS rows — drive the leaderboard. Rotate which user does best per quiz.
    # Keyed on role too, so a pick and a guess for the same game stay separate.
    correct_count = base_counts[(i + quiz.position) % seed_users.size]
    answers.first(correct_count).each do |game|
      QuizGame.find_or_create_by!(user: user, quiz: quiz, game: game, role: "guess")
    end

    # PICK rows — the user's own list-of-the-day, shown as reference on the
    # "yesterday" tab. May overlap the answers; that's fine — a pick never counts
    # as a guess, and we still want to remind the user what they picked.
    answers.last(2).each do |game|
      QuizGame.find_or_create_by!(user: user, quiz: quiz, game: game, role: "pick")
    end
  end
end
puts "  #{seed_users.size} users seeded across #{Quiz.count} quizzes."

puts "\nSeed complete!"


# ── Random vote counts (placeholder until likes exist) ───────────────────────
puts "\nAssigning random vote counts to lists…"
List.find_each { |list| list.update_column(:votes_count, rand(0..200)) }
