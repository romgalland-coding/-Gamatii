class QuizGame < ApplicationRecord
  belongs_to :game
  belongs_to :quiz
  belongs_to :user
end
