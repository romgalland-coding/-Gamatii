class CreateQuizzGames < ActiveRecord::Migration[8.1]
  def change
    create_table :quizz_games do |t|
      t.references :quizz, null: false, foreign_key: true
      t.references :game, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
