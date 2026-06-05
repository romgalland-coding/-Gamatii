class QuizzesController < ApplicationController
  POINTS_BY_RANK = [50, 40, 30, 20, 10].freeze

  def daily
    # Capture a single timestamp so the quizzes and the countdown all agree on
    # which rotation window we're in (they'd otherwise each read the clock and
    # could straddle a boundary).
    now             = Time.current
    schedule        = QuizSchedule.instance
    @today_quiz     = schedule.today_quiz(now: now)
    @yesterday_quiz = schedule.yesterday_quiz(now: now)
    @seconds_remaining = schedule.seconds_until_next_rotation(now: now)

    authorize @today_quiz
    authorize @yesterday_quiz

    # Answer pools — derived from Game via the quiz's theme filter, not stored in quiz_games
    @today_pool        = @today_quiz.answer_pool(10)
    @yesterday_answers = @yesterday_quiz.answer_pool(5)

    return unless current_user

    load_user_progress
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
    @found = @yesterday_answers.count { |g| @guessed_titles.include?(normalize_title(g.title)) }

    load_leaderboard
  end

  # Ranks everyone who guessed on yesterday's quiz by score (then found-count as
  # tiebreaker). The current user is always included, even with no guesses, so
  # they see their own rank. Scores compute live from the same answer pool.
  def load_leaderboard
    rows = QuizGame.guesses.where(quiz: @yesterday_quiz).includes(:game, :user)
                   .group_by(&:user)
                   .map { |user, qgs| leaderboard_row(user, qgs) }

    rows << leaderboard_row(current_user, []) if rows.none? { |r| r[:user] == current_user }

    @leaderboard = rows.sort_by { |r| [-r[:score], -r[:found]] }
                       .each_with_index.map { |r, i| r.merge(rank: i + 1) }
    me = @leaderboard.find { |r| r[:user] == current_user }
    @my_rank = me[:rank]
    @total_players = @leaderboard.size
  end

  def leaderboard_row(user, quiz_games)
    titles = quiz_games.to_set { |qg| normalize_title(qg.game.title) }
    found  = @yesterday_answers.count { |g| titles.include?(normalize_title(g.title)) }
    { user: user, score: score_for(@yesterday_answers, titles), found: found }
  end

  def score_for(answers, guessed_titles)
    answers.each_with_index.sum do |game, rank|
      guessed_titles.include?(normalize_title(game.title)) ? POINTS_BY_RANK[rank] : 0
    end
  end

  # Shared by the view (the green "revealed" check) so both normalize identically.
  helper_method def normalize_title(title)
    title.to_s.downcase.strip
  end
end
