class QuizGamesController < ApplicationController
  include QuizScoring
  helper_method :normalize_title

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

    # Picks (today tab) just redirect. Guesses respond inline via turbo_stream so
    # both right and wrong feel smooth: a wrong guess shakes + shows a message; a
    # right one reveals the row (green fill), counts up the score, and opens the
    # score screen on the 5th. See create.turbo_stream.erb.
    return redirect_to daily_quizzes_path(tab: tab_for(@quiz)) unless role == "guess"

    @game = game
    @correct = correct_guess?(@quiz, game)
    load_guess_state(previous_score: @correct ? score_before(@quiz, game) : nil)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to daily_quizzes_path }
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

  # The guess quiz is the default tab (nil); the pick quiz is the "pick" tab.
  def tab_for(quiz)
    quiz == QuizSchedule.instance.yesterday_quiz ? nil : "pick"
  end

  # A game added on the "yesterday" quiz is a guess; on today's quiz it's a pick.
  def role_for(quiz)
    quiz == QuizSchedule.instance.yesterday_quiz ? "guess" : "pick"
  end

  # True if the guessed game is in the quiz's top-5 answer pool. Matches by
  # normalized title, the same way scoring does (picks are fresh RAWG imports,
  # so they're different Game records than the seeded answers).
  def correct_guess?(quiz, game)
    target = normalize_title(game.title)
    quiz.answer_pool(5).any? { |answer| normalize_title(answer.title) == target }
  end

  # Loads everything the create.turbo_stream partials need: the answer pool, the
  # user's guesses, score/found, remaining count, and the leaderboard.
  # `previous_score` (when given) lets the score line animate a count-up.
  def load_guess_state(previous_score: nil)
    @yesterday_quiz    = @quiz
    @yesterday_answers = @quiz.answer_pool(5)
    @guesses           = current_user.quiz_games.guesses.where(quiz: @quiz).includes(:game)
    @guessed_titles    = @guesses.to_set { |qg| normalize_title(qg.game.title) }
    @guesses_remaining = 5 - @guesses.count
    @score             = score_for(@yesterday_answers, @guessed_titles)
    @found             = found_count(@yesterday_answers, @guessed_titles)
    @previous_score    = previous_score || @score

    board = leaderboard_for(@quiz, @yesterday_answers)
    @leaderboard   = board[:rows]
    @my_rank       = board[:my_rank]
    @total_players = board[:total_players]
  end

  # The score the user had BEFORE the just-created guess, so the count-up starts
  # from the old total. Recomputes excluding the new game's title.
  def score_before(quiz, game)
    answers = quiz.answer_pool(5)
    titles  = current_user.quiz_games.guesses.where(quiz: quiz)
                          .reject { |qg| qg.game_id == game.id }
                          .to_set { |qg| normalize_title(qg.game.title) }
    score_for(answers, titles)
  end
end
