class CreateQuizGames < ActiveRecord::Migration[8.1]
  def change
    create_table :quiz_games do |t|
      t.references :game, null: false, foreign_key: true
      t.references :quiz, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
