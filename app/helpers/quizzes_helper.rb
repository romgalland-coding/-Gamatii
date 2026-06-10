module QuizzesHelper
  # Points awarded per rank — mirrors QuizScoring::POINTS_BY_RANK so the answer
  # rows display the same values the scoring logic awards.
  RANK_POINTS = QuizScoring::POINTS_BY_RANK

  def quiz_rank_points(index)
    RANK_POINTS[index]
  end

  # The topic word(s) from a quiz name, for placeholder copy like
  # "Find a cozy game…". Quiz names look like "Top 5 cozy games"; we strip the
  # leading "Top N" and trailing "games", falling back to "" when it doesn't match.
  def quiz_topic(quiz)
    name = quiz&.name.to_s
    name.sub(/\Atop\s+\d+\s+/i, "").sub(/\s+games?\z/i, "").strip
  end
end
