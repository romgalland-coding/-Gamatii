class AddRoleToQuizGames < ActiveRecord::Migration[8.1]
  def change
    # "pick" = a game the user added to their own list of the day;
    # "guess" = a game the user guessed on yesterday's quiz.
    add_column :quiz_games, :role, :string, null: false, default: "guess"
    add_index :quiz_games, [:quiz_id, :role]
  end
end
