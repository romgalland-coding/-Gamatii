class FixScreenshotsToArray < ActiveRecord::Migration[8.1]
  def up
    add_column :games, :screenshots_arr, :string, array: true, default: []

    Game.find_each do |game|
      raw = game.read_attribute(:screenshots)
      next if raw.blank?
      begin
        urls = JSON.parse(raw)
        game.update_column(:screenshots_arr, urls)
      rescue JSON::ParserError
        # leave empty for malformed rows
      end
    end

    remove_column :games, :screenshots
    rename_column :games, :screenshots_arr, :screenshots
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
