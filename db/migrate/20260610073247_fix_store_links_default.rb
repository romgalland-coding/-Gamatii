class FixStoreLinksDefault < ActiveRecord::Migration[8.1]
  def up
    change_column_default :games, :store_links, nil
    Game.where(store_links: []).update_all(store_links: nil)
  end

  def down
    change_column_default :games, :store_links, []
  end
end
