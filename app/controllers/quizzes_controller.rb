class QuizzesController < ApplicationController
  def daily
    @today_quiz     = Quiz.find_by!(name: "Top 5 PC games")
    @yesterday_quiz = Quiz.find_by!(name: "Top 5 Zelda games")

    authorize @today_quiz
    authorize @yesterday_quiz

    # Answer pools — derived from Game, not stored in quiz_games
    @today_pool = Game.where("platforms ILIKE '%PC%'").order(rating: :desc).limit(10)
    @yesterday_answers = Game.where("title ILIKE '%zelda%'").order(rating: :desc).limit(5)

    return unless current_user

    @my_submissions = current_user.quiz_games.where(quiz: @today_quiz).includes(:game)
    @my_guesses     = current_user.quiz_games.where(quiz: @yesterday_quiz).includes(:game)
    @guesses_remaining = 5 - @my_guesses.count
    @score = @my_guesses.sum do |qg|
      rank = @yesterday_answers.index(qg.game)
      rank ? [50, 40, 30, 20, 10][rank] : 0
    end
  end

  def show
  end
end
