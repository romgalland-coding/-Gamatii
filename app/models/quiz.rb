class Quiz < ApplicationRecord
  has_many :quiz_games, dependent: :destroy
  has_many :games, through: :quiz_games
end
