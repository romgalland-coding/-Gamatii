class Game < ApplicationRecord
  has_many :list_games, dependent: :destroy
  has_many :lists, through: :list_games

  has_many :quizz_games, dependent: :destroy
  has_many :quizzs, through: :quizz_games
end
