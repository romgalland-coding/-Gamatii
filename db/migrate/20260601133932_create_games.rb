class CreateGames < ActiveRecord::Migration[8.1]
  def change
    create_table :games do |t|
      t.string :title
      t.text :description
      t.string :genre
      t.string :developer
      t.string :publisher
      t.date :release_date
      t.string :platforms
      t.string :game_mode, array: true, default: []
      t.float :rating
      t.string :cover_img
      t.string :in_game_img

      t.timestamps
    end
  end
end
