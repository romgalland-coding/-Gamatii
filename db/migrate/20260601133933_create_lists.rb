class CreateLists < ActiveRecord::Migration[8.1]
  def change
    create_table :lists do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.string :list_type, array: true, default: []
      t.integer :votes_count

      t.timestamps
    end
  end
end
