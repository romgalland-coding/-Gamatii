class Game < ApplicationRecord
  has_many :list_games, dependent: :destroy
  has_many :lists, through: :list_games

  has_many :quiz_games, dependent: :destroy
  has_many :quizzes, through: :quiz_games
end
