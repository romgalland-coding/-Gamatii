class AddPositionToQuizzes < ActiveRecord::Migration[8.1]
  def change
    add_column :quizzes, :position, :integer
  end
end
