class ListGame < ApplicationRecord
  belongs_to :list
  belongs_to :game

  validates :game_id, uniqueness: { scope: :list_id }
end
