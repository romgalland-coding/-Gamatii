class Quiz < ApplicationRecord
  has_many :quiz_games, dependent: :destroy
  has_many :games, through: :quiz_games

  # Theme filter for each daily quiz, keyed by name. Both the answer pool
  # (QuizzesController#daily) and the in-quiz autocomplete derive from this,
  # so suggestions always match the games that can actually score.
  ANSWER_FILTERS = {
    "Top 5 PC games" => ->(scope) { scope.where("? = ANY(platforms)", "PC") },
    "Top 5 Zelda games" => ->(scope) { scope.where("title ILIKE ?", "%zelda%") }
  }.freeze

  # Games eligible for this quiz, highest-rated first.
  def answer_scope
    filter = ANSWER_FILTERS.fetch(name, ->(scope) { scope })
    filter.call(Game.all).order(rating: :desc)
  end

  # The top `limit` distinct games for this quiz. De-dupes by title because
  # picks imported from RAWG can create a second record for a game we already
  # seeded; ordered highest-rated first, so uniq keeps the best-rated copy.
  def answer_pool(limit)
    answer_scope.uniq { |game| game.title.to_s.downcase.strip }.first(limit)
  end
end
