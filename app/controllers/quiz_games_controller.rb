class QuizGamesController < ApplicationController
  def create
    @quiz = Quiz.find(params[:quiz_id])
    game  = Game.import_from_rawg(params[:rawg_id])

    authorize QuizGame

    redirect_to daily_quizzes_path(tab: tab_for(@quiz)), alert: "Game not found." and return if game.nil?

    # Dedupe and the 5-limit are per-role: a game picked yesterday must not block
    # guessing the same game today, and yesterday's picks don't fill today's slots.
    role  = role_for(@quiz)
    scope = current_user.quiz_games.where(quiz: @quiz, role: role)

    if scope.exists?(game: game)
      redirect_to daily_quizzes_path(tab: tab_for(@quiz)), alert: "You already picked that game." and return
    end

    if scope.count >= 5
      redirect_to daily_quizzes_path(tab: tab_for(@quiz)), alert: "You've reached the limit of 5." and return
    end

    current_user.quiz_games.create!(quiz: @quiz, game: game, role: role)

    # A wrong guess still counts, but we give inline feedback (shake + message)
    # without a reload. A correct guess reloads so the answer reveals and the
    # score/score-screen update through the existing daily flow.
    if role == "guess" && !correct_guess?(@quiz, game)
      @wrong_game = game
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to daily_quizzes_path(tab: "yesterday") }
      end
    else
      redirect_to daily_quizzes_path(tab: tab_for(@quiz))
    end
  end

  def destroy
    @quiz_game = current_user.quiz_games.find(params[:id])
    authorize @quiz_game
    quiz = @quiz_game.quiz

    @quiz_game.destroy
    redirect_to daily_quizzes_path(tab: tab_for(quiz))
  end

  private

  def tab_for(quiz)
    quiz == QuizSchedule.instance.yesterday_quiz ? "yesterday" : nil
  end

  # A game added on the "yesterday" quiz is a guess; on today's quiz it's a pick.
  def role_for(quiz)
    quiz == QuizSchedule.instance.yesterday_quiz ? "guess" : "pick"
  end

  # True if the guessed game is in the quiz's top-5 answer pool. Matches by
  # normalized title, the same way scoring does (picks are fresh RAWG imports,
  # so they're different Game records than the seeded answers).
  def correct_guess?(quiz, game)
    target = game.title.to_s.downcase.strip
    quiz.answer_pool(5).any? { |answer| answer.title.to_s.downcase.strip == target }
  end
end
