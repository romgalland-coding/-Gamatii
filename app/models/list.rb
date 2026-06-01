class List < ApplicationRecord
  belongs_to :user
  has_many :list_games, dependent: :destroy
  has_many :games, through: :list_games
end
