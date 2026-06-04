class QuizGamesController < ApplicationController
  def create
    @quiz = Quiz.find(params[:quiz_id])
    game  = Game.import_from_rawg(params[:rawg_id])

    authorize QuizGame

    redirect_to daily_quizzes_path(tab: tab_for(@quiz)), alert: "Game not found." and return if game.nil?

    already_picked = current_user.quiz_games.exists?(quiz: @quiz, game: game)
    limit_reached  = current_user.quiz_games.where(quiz: @quiz).count >= 5

    if already_picked
      redirect_to daily_quizzes_path(tab: tab_for(@quiz)), alert: "You already picked that game." and return
    end

    if limit_reached
      redirect_to daily_quizzes_path(tab: tab_for(@quiz)), alert: "You've reached the limit of 5." and return
    end

    current_user.quiz_games.create!(quiz: @quiz, game: game)
    redirect_to daily_quizzes_path(tab: tab_for(@quiz))
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
    quiz.name == "Top 5 Zelda games" ? "yesterday" : nil
  end
end
