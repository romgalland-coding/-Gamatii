class AddAnswerGameIdsToQuizzes < ActiveRecord::Migration[8.1]
  def change
    # The frozen top-5 answer game ids, in rank order. Set once when the quiz is
    # created (see Quiz#freeze_answer_pool! / seeds) so later RAWG imports from
    # guessing can't leak into and reshuffle the pool.
    add_column :quizzes, :answer_game_ids, :integer, array: true, default: [], null: false
  end
end
