class SearchGameTool < RubyLLM::Tool
  description "Searches for a real video game by title using the RAWG database and imports it into the catalog so it can be recommended."
  param :title, desc: "The exact title of the game to search for"

  def initialize
    @found_game = nil
  end

  attr_reader :found_game

  def execute(title:)
    results = RawgService.new.search(title)
    return { error: "No game found for '#{title}'" } if results.blank?

    api_game = best_match(results, title)
    game = Game.import_from_rawg(api_game["id"])
    @found_game = game

    {
      title:        game.title,
      genre:        game.genre,
      platforms:    game.platforms,
      developer:    game.developer,
      rating:       game.rating,
      release_date: game.release_date&.to_s
    }
  rescue => e
    { error: e.message }
  end

  private

  # RAWG's relevance ranking isn't always exact, so pick the result whose title
  # is closest to what was asked for, ignoring edition/version suffixes.
  def best_match(results, title)
    normalized = Game.normalize_title(title).downcase
    results.min_by do |r|
      candidate = Game.normalize_title(r["name"].to_s).downcase
      levenshtein(normalized, candidate)
    end
  end

  def levenshtein(a, b)
    m, n = a.length, b.length
    dp = Array.new(m + 1) { |i| Array.new(n + 1) { |j| i.zero? ? j : j.zero? ? i : 0 } }
    (1..m).each do |i|
      (1..n).each do |j|
        dp[i][j] = a[i - 1] == b[j - 1] ? dp[i - 1][j - 1] : 1 + [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]].min
      end
    end
    dp[m][n]
  end
end
