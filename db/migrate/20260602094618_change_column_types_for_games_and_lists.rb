class ChangeColumnTypesForGamesAndLists < ActiveRecord::Migration[8.1]
  def change
    # game_mode: string[] → string
    change_column :games, :game_mode, :string

    # platforms: string → string[]
    remove_column :games, :platforms, :string

    # list_type: string[] → string
    change_column :lists, :list_type, :string

    add_column :games, :platforms, :string, array: true, default: [], null: false
  end
end
