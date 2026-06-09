class QuizzesController < ApplicationController
  include QuizScoring
  helper_method :normalize_title
  skip_before_action :authenticate_user!, only: :daily
  before_action :require_login_or_redirect, only: :daily

  def daily
    # Capture a single timestamp so the quizzes and the countdown all agree on
    # which rotation window we're in (they'd otherwise each read the clock and
    # could straddle a boundary).
    now             = Time.current
    schedule        = QuizSchedule.instance
    @today_quiz     = schedule.today_quiz(now: now)
    @yesterday_quiz = schedule.yesterday_quiz(now: now)
    @seconds_remaining = schedule.seconds_until_next_rotation(now: now)

    # When the timer hits zero it reloads with ?ended=<quiz_id> to freeze on the
    # quiz that just closed (rotation is time-derived, so it would otherwise show
    # the new window). We show that quiz's results until the user moves on.
    if params[:ended].present? && (ended = Quiz.find_by(id: params[:ended]))
      @yesterday_quiz = ended
      @round_ended = true
    end

    authorize @today_quiz
    authorize @yesterday_quiz

    # Answer pools — derived from Game via the quiz's theme filter, not stored in quiz_games
    @today_pool        = @today_quiz.answer_pool(10)
    @yesterday_answers = @yesterday_quiz.answer_pool(5)

    return unless current_user

    load_user_progress
    @guesses_remaining = 0 if @round_ended # force reveal-all + score screen
  end

  def autocomplete_games
    @quiz = Quiz.find(params[:id])
    authorize @quiz, :daily?
    @query = params[:query]
    @results = RawgService.new.search(@query)

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def load_user_progress
    @my_submissions = current_user.quiz_games.picks.where(quiz: @today_quiz).includes(:game)
    @my_guesses     = current_user.quiz_games.guesses.where(quiz: @yesterday_quiz).includes(:game)
    @guesses_remaining = 5 - @my_guesses.count

    # The picks this user made when yesterday's quiz was "today" — shown below
    # the guesses as a reference so they can re-enter them as guesses.
    @my_yesterday_picks = current_user.quiz_games.picks.where(quiz: @yesterday_quiz).includes(:game)

    # Guesses are matched to answers by title: picks are imported fresh from
    # RAWG, so they are different Game records than the seeded answer pool.
    @guessed_titles = @my_guesses.to_set { |qg| normalize_title(qg.game.title) }
    @score = score_for(@yesterday_answers, @guessed_titles)
    @found = found_count(@yesterday_answers, @guessed_titles)

    @leaderboard = leaderboard_for(@yesterday_quiz, @yesterday_answers)
  end
end
