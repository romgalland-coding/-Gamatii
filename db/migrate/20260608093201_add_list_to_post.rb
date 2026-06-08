class AddListToPost < ActiveRecord::Migration[8.1]
  def change
    add_reference :posts, :list, null: true, foreign_key: true
  end
end
