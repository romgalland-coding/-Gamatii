class QuizGame < ApplicationRecord
  ROLES = %w[pick guess].freeze

  belongs_to :game
  belongs_to :quiz
  belongs_to :user

  validates :role, inclusion: { in: ROLES }

  scope :picks,   -> { where(role: "pick") }
  scope :guesses, -> { where(role: "guess") }
end
