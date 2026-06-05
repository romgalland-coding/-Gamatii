class CreateListLikes < ActiveRecord::Migration[8.1]
  def change
    create_table :list_likes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :list, null: false, foreign_key: true
      t.timestamps
    end
    add_index :list_likes, [:user_id, :list_id], unique: true
  end
end
