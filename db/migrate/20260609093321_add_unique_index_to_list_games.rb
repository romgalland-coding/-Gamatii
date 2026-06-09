class AddUniqueIndexToListGames < ActiveRecord::Migration[8.1]
  def change
    add_index :list_games, [:list_id, :game_id], unique: true, if_not_exists: true
  end
end
