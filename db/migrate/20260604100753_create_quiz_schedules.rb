class CreateQuizSchedules < ActiveRecord::Migration[8.1]
  def change
    create_table :quiz_schedules do |t|
      t.integer :current_position, null: false, default: 0
      t.datetime :last_rotated_at

      t.timestamps
    end
  end
end
