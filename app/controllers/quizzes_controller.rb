class QuizzesController < ApplicationController
  def daily
    @today_quiz     = Quiz.find_by!(name: "Top 5 PC games")
    @yesterday_quiz = Quiz.find_by!(name: "Top 5 Zelda games")

    authorize @today_quiz
    authorize @yesterday_quiz

    # Answer pools — derived from Game via the quiz's theme filter, not stored in quiz_games
    @today_pool        = @today_quiz.answer_scope.limit(10)
    @yesterday_answers = @yesterday_quiz.answer_scope.limit(5)

    return unless current_user

    @my_submissions = current_user.quiz_games.where(quiz: @today_quiz).includes(:game)
    @my_guesses     = current_user.quiz_games.where(quiz: @yesterday_quiz).includes(:game)
    @guesses_remaining = 5 - @my_guesses.count
    @score = @my_guesses.sum do |qg|
      rank = @yesterday_answers.index(qg.game)
      rank ? [50, 40, 30, 20, 10][rank] : 0
    end
  end

  def autocomplete_games
    @quiz = Quiz.find(params[:id])
    authorize @quiz, :daily?
    @results = autocomplete_results(@quiz, params[:query])

    respond_to do |format|
      format.turbo_stream
    end
  end

  def show
  end

  private

  # Games matching the typed query, restricted to the quiz's theme so a
  # suggestion is always something that can actually score.
  def autocomplete_results(quiz, query)
    query = query.to_s.strip
    return Game.none if query.length < 2

    quiz.answer_scope.where("title ILIKE ?", "%#{Game.sanitize_sql_like(query)}%").limit(8)
  end
end
