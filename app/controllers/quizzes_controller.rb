class QuizzesController < ApplicationController
  POINTS_BY_RANK = [50, 40, 30, 20, 10].freeze

  def daily
    schedule        = QuizSchedule.instance
    @today_quiz     = schedule.today_quiz
    @yesterday_quiz = schedule.yesterday_quiz

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

  def show
  end

  private

  def load_user_progress
    @my_submissions = current_user.quiz_games.where(quiz: @today_quiz).includes(:game)
    @my_guesses     = current_user.quiz_games.where(quiz: @yesterday_quiz).includes(:game)
    @guesses_remaining = 5 - @my_guesses.count

    # Guesses are matched to answers by title: picks are imported fresh from
    # RAWG, so they are different Game records than the seeded answer pool.
    @guessed_titles = @my_guesses.to_set { |qg| normalize_title(qg.game.title) }
    @score = score_for(@yesterday_answers, @guessed_titles)
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
