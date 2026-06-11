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
  rawg_get("/games", query)["results"] || []
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
    rawg_id: g["id"],
    title: g["name"],
    cover_img: g["background_image"],
    in_game_img: g.dig("short_screenshots", 1, "image"),
    screenshots: (g["short_screenshots"] || []).filter_map { |s| s["image"] }[1..3].to_a,
    genre: g["genres"]&.map { |genre| genre["name"] }&.join(", "),
    platforms: platforms_arr,
    # `rating` stores the Metascore (0–100), not RAWG's user rating — the UI
    # already labels this column "Metacritic" (lists filter) and the quiz ranks
    # the top 5 by it. RAWG's user rating is too easily inflated by a few votes.
    rating: g["metacritic"] || detail["metacritic"],
    release_date: g["released"],
    description: detail["description_raw"]&.slice(0, 2000),
    developer: detail.dig("developers", 0, "name"),
    publisher: detail.dig("publishers", 0, "name"),
    game_mode: game_modes_from_tags(detail["tags"])
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
# Nullify list references on posts before lists are destroyed to avoid FK violations
# (posts from user A may reference lists owned by user B, which gets destroyed first).
Post.update_all(list_id: nil)
# Generated users all share the @seed.gamatii domain so we can wipe them by pattern,
# however many there are this run.
User.where(email: curated_emails).or(User.where("email LIKE ?", "%@seed.gamatii")).each do |u|
  u.lists.each { |l| l.list_games.destroy_all }
  u.lists.destroy_all
  u.destroy
end
# Chat messages reference recommended games via game_id (optional); nullify them
# so the catalogue can be wiped without tripping the messages→games foreign key.
Message.update_all(game_id: nil)
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
  { email: "pixelknight@gmail.com",  gamer_tag: "PixelKnight",  platform: ["PC", "Nintendo Switch"],
    avatar_emoji: "🦊", avatar_color: "#FFE599",
    bio: "Soulslike speedrunner. Will fight anyone about Hollow Knight." },
  { email: "neonbyte@gmail.com",     gamer_tag: "NeonByte",     platform: ["PlayStation 5", "PlayStation 4"],
    avatar_emoji: "👾", avatar_color: "#C4B5FD",
    bio: "Indie game hoarder. My backlog has its own backlog." },
  { email: "vortexcaster@gmail.com", gamer_tag: "VortexCaster", platform: ["Xbox Series S/X", "Xbox One", "PC"],
    avatar_emoji: "🎮", avatar_color: "#9FC5F8",
    bio: "Competitive shooters and a worrying amount of coffee." }
].freeze

# Pools the generated roster draws from so every profile feels lived-in.
EMOJI_POOL = %w[🐉 🦄 🤖 👻 🐙 🦅 🌙 🔥 🐺 ⚡️ 🍄 🦝 🛸 🧙 🐱].freeze
AVATAR_COLOR_POOL = %w[#F6C453 #A7D7A0 #9EC5FE #F4A8C0 #C4B5FD #FCD9A8 #9AE6D5].freeze
BIO_POOL = [
  "Just here for the loot.",
  "RPG enjoyer. Probably AFK in a menu somewhere.",
  "Cozy games by day, horror games by night.",
  "100% completionist or nothing.",
  "Retro collector. Cartridges only, fight me.",
  "Co-op partner wanted. Must tolerate friendly fire.",
  "Lore nerd. I read every codex entry.",
  "Speedrun curious, casually competitive.",
  "Building the ultimate wishlist one sale at a time.",
  "Will quit my job for a good open world.",
  "Tactics and turn-based, all day.",
  "Pixel art appreciator and rhythm game addict."
].freeze

# Generate the rest of the roster up to 15 total. Tags are picked from a pool so
# every user reads like a real gamer handle.
TAG_POOL = %w[
  ShadowFox GlitchWizard ByteRunner CrimsonAce FrostByte
  TurboNova PhantomDrift QuasarKid EmberWolf StarlitHex
  RogueCircuit ApexRaven LunarSpecter VoidStriker NitroGhost
  CosmicRift IronPulse ZenithByte NebulaDrift CipherWolf
]
generated_count = 20 - CURATED_USERS.size
generated_users = TAG_POOL.first(generated_count).each_with_index.map do |tag, i|
  {
    email: "#{tag.downcase}@seed.gamatii",
    gamer_tag: tag,
    platform: User::PLATFORMS.sample(rng.rand(1..3), random: rng),
    avatar_emoji: EMOJI_POOL[i % EMOJI_POOL.size],
    avatar_color: AVATAR_COLOR_POOL[i % AVATAR_COLOR_POOL.size],
    bio: BIO_POOL[i % BIO_POOL.size]
  }
end

ALL_USERS = CURATED_USERS + generated_users

puts "\nCreating #{ALL_USERS.size} users and their lists…"
created_users = ALL_USERS.map do |data|
  user = User.create!(
    email: data[:email],
    password: "password",
    gamer_tag: data[:gamer_tag],
    platform: data[:platform],
    avatar_emoji: data[:avatar_emoji],
    avatar_color: data[:avatar_color],
    bio: data[:bio]
  )

  LIST_SPECS.each do |ldata|
    # New users already get empty "Played" and "Wishlist" lists from the
    # User after_create callback, so reuse those by name and only create the
    # rest (e.g. "Favorites") fresh — then fill each with sample games.
    list = user.lists.find_or_create_by!(name: ldata[:name]) do |l|
      l.list_type = ldata[:list_type]
    end
    sample = games.sample(ldata[:count], random: rng)
    sample.each { |game| list.list_games.create!(game: game) }
    puts "  #{user.gamer_tag} › #{list.name} (#{ldata[:list_type]}): #{sample.size} games"
  end

  user
end

# ── Follow graph ──────────────────────────────────────────────────────────────
# Each user follows a random subset of the others, so every profile shows real
# follower/following counts and populated modals.

puts "\nWiring up the follow graph…"
follow_count = 0
created_users.each do |user|
  others = created_users - [user]
  others.sample(rng.rand(3..9), random: rng).each do |target|
    follow_count += 1 if user.follow(target)&.persisted?
  end
end
puts "  #{follow_count} follow relationships created."

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
base_counts = seed_users.each_index.map { |i| i % 6 } # cycles 0..5 across users

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

# ── Random vote counts (placeholder until likes exist) ───────────────────────
puts "\nAssigning random vote counts to lists…"
List.find_each { |list| list.update_column(:votes_count, rand(0..200)) }

# ── Activity Feed: follows + posts + comments + likes ────────────────────────
require "open-uri"

puts "\nSeeding activity feed (follows, posts, comments, likes)…"

pixel_knight  = User.find_by!(gamer_tag: "PixelKnight")
neon_byte     = User.find_by!(gamer_tag: "NeonByte")
vortex_caster = User.find_by!(gamer_tag: "VortexCaster")
shadow_fox    = User.find_by!(gamer_tag: "ShadowFox")
glitch_wizard = User.find_by!(gamer_tag: "GlitchWizard")
turbo_nova    = User.find_by!(gamer_tag: "TurboNova")

# PixelKnight follows these 4
[neon_byte, vortex_caster, shadow_fox, glitch_wizard].each do |u|
  pixel_knight.follow(u)
end
puts "  PixelKnight now follows 4 users."

# Lists belonging to the followed users (for sharing)
nb_played   = neon_byte.lists.find_by(list_type: "played")
sf_wishlist = shadow_fox.lists.find_by(list_type: "wishlist")
sf_custom   = shadow_fox.lists.find_by(list_type: "custom")
gw_played   = glitch_wizard.lists.find_by(list_type: "played")

POST_SPECS = [
  {
    author: neon_byte,
    body: "Just finished The Last of Us for the third time. Every single playthrough hits differently. Ellie's arc in Part II is criminally underrated storytelling.",
    url: nil, list: nil,
    photo_url: "https://images.lanouvellerepublique.fr/image/upload/t_1020w/f_auto/5f05c781990e2d6f048b4578.jpg"
  },
  # 3 — text + URL + list
  {
    author: shadow_fox,
    body: "007: First Light — open world Bond game confirmed. IO Interactive might actually pull this off. Already on my wishlist, link has all the details.",
    url: "https://www.ign.com/articles/007-first-light-everything-we-know",
    list: sf_wishlist, photo_url: nil
  },
  # 4 — list share only
  {
    author: shadow_fox,
    body: nil, url: nil,
    list: sf_custom, photo_url: nil
  },
  # 5 — text + list
  {
    author: glitch_wizard,
    body: "Wrapped these up this year. My taste is immaculate, don't @ me.",
    url: nil,
    list: gw_played, photo_url: nil
  },
  # 6 — text + photo (Hollow Knight)
  {
    author: vortex_caster,
    body: "Hollow Knight: Silksong watch begins again. Replaying the original to cope. No notes, the atmosphere is untouchable.",
    url: nil, list: nil,
    photo_url: "https://cdn.shopify.com/s/files/1/0570/8280/6468/files/product_silksong_pharloom_champion_poster_EU_designview.png?v=1762467232"
  },
  # 7 — text + URL
  {
    author: vortex_caster,
    body: "Clair Obscur: Expedition 33 is the most interesting JRPG in years. French studio, Belle Époque aesthetic, real-time parry mechanics — it has no right being this good. Review below.",
    url: "https://static.wikia.nocookie.net/clair-obscur/images/2/2a/COE33_Lorieniso.jpg/revision/latest/thumbnail/width/360/height/450?cb=20250524161002",
    list: nil, photo_url: nil
  },
  # 8 — photo + list (Clair Obscur)
  {
    author: glitch_wizard,
    body: "Clair Obscur: Expedition 33 visuals are something else. Screenshots don't do it justice — sharing my played list while I wait for a sequel.",
    url: nil,
    list: gw_played,
    photo_url: "https://image.jeuxvideo.com/medias-md/174136/1741361048-6233-card.jpg"
  },
  # 9 — text + photo + URL (Clair Obscur OST)
  {
    author: neon_byte,
    body: "The Clair Obscur: Expedition 33 OST has been on loop for days. Lorien Testard composed something genuinely special — link below. The combat theme alone is insane.",
    url: "https://www.youtube.com/watch?v=0TqPMFHqiGo",
    list: nil,
    photo_url: "https://static.wikia.nocookie.net/clair-obscur/images/2/2a/COE33_Lorieniso.jpg/revision/latest/thumbnail/width/360/height/450?cb=20250524161002"
  },
  # 10 — long text + list
  {
    author: vortex_caster,
    body: "Gaming confession: I have a backlog of 200+ games and I keep buying more. Every sale on Steam I tell myself 'just one more'. My played list is embarrassingly short compared to my wishlist. Anyone else living this nightmare?",
    url: nil,
    list: nb_played, photo_url: nil
  }
].freeze

COMMENTS_POOL = [
  "This is so real 😭",
  "100% agree with this take.",
  "No way, I disagree completely. Counter-argument: skill issue.",
  "I've been meaning to play this for ages, thanks for the reminder!",
  "The list is 🔥🔥🔥",
  "Bro same, I have like 300 in my backlog and I keep adding more.",
  "That URL goes hard, thanks for sharing.",
  "The visuals are insane, what game is this?",
  "Your taste is unreal fr.",
  "Adding this to my wishlist right now.",
  "I finished that yesterday actually, what a ride.",
  "Silksong will drop when we least expect it. I believe.",
  "Controversial opinion but I liked Part I more honestly.",
  "Peak gaming moment.",
  "007: First Light has so much potential, IO Interactive won't miss.",
  "Expedition 33 OST is genuinely one of the best in years.",
  "How many hours do you have in this? Because same."
].freeze

all_commenters = [pixel_knight, neon_byte, vortex_caster, shadow_fox, glitch_wizard, turbo_nova]
all_likers     = [pixel_knight, neon_byte, vortex_caster, shadow_fox, glitch_wizard, turbo_nova]

POST_SPECS.each_with_index do |spec, i|
  post = spec[:author].posts.build(body: spec[:body], url: spec[:url], list: spec[:list], photo_url: spec[:photo_url])
  post.save!

  # Spread posts over ~14 days (index 0 = most recent, last index = oldest)
  post_time = (i * 36 + rng.rand(0..12)).hours.ago
  post.update_columns(created_at: post_time, updated_at: post_time)

  # 2–4 comments from random users (not the author), each after the post
  commenters = (all_commenters - [spec[:author]]).sample(rng.rand(2..4), random: rng)
  commenters.each do |commenter|
    comment = post.comments.create!(user: commenter, body: COMMENTS_POOL.sample(random: rng))
    comment_time = post_time + rng.rand(10..120).minutes
    comment.update_columns(created_at: comment_time, updated_at: comment_time)
  end

  # 1–5 likes from random users (not the author)
  likers = (all_likers - [spec[:author]]).sample(rng.rand(1..5), random: rng)
  likers.each { |liker| post.likes.find_or_create_by!(user: liker) }

  puts "  Post #{i + 1}/#{POST_SPECS.size} by #{spec[:author].gamer_tag} — #{post.comments.count} comments, #{post.likes.count} likes"
end

# Add 007: First Light to ShadowFox's wishlist (shared in the activity feed post).
puts "\nFetching 007: First Light for ShadowFox's wishlist…"
results_007 = rawg_get("/games", search: "007 First Light", search_precise: true, page_size: 5)["results"] || []
game_007 = results_007.first
if game_007
  record_007 = upsert_game(game_007)
  sf_wishlist.list_games.find_or_create_by!(game: record_007) if record_007
  puts "  Added #{game_007['name']} to ShadowFox's wishlist."
else
  puts "  007: First Light not found on RAWG — skipping."
end

# Any real (non-seed) account in the DB gets auto-followed to the 4 content
# creators so their activity feed is populated immediately after seeding.
content_creators = [neon_byte, vortex_caster, shadow_fox, glitch_wizard]
seed_emails = curated_emails + TAG_POOL.map { |t| "#{t.downcase}@seed.gamatii" }
external_users = User.where.not(email: seed_emails)
if external_users.any?
  external_users.each do |user|
    content_creators.each { |creator| user.follow(creator) }
  end
  puts "  Auto-followed content creators for #{external_users.count} external user(s): #{external_users.pluck(:gamer_tag).join(', ')}"
end

puts "\nSeed complete!"
