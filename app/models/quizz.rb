class Quizz < ApplicationRecord
  has_many :quizz_games, dependent: :destroy
  has_many :games, through: :quizz_games
end
