class AddScreenshotsToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :screenshots, :string, array: true, default: []
  end
end
