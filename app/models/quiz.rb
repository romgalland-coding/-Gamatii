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
end
