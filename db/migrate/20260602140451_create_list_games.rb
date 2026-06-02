class CreateListGames < ActiveRecord::Migration[8.1]
  def change
    create_table :list_games do |t|
      t.references :list, null: false, foreign_key: true
      t.references :game, null: false, foreign_key: true

      t.timestamps
    end
    add_index :list_games, [:list_id, :game_id], unique: true
  end
end
