class QuizzGame < ApplicationRecord
  belongs_to :quizz
  belongs_to :game
  belongs_to :user
end
