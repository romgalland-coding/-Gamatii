class AddStoreLinksToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :store_links, :jsonb, default: []
  end
end
