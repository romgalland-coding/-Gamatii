class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :gamer_tag
      t.string :platform, array: true, default: []

      t.timestamps
    end
  end
end
