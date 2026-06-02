class GamesController < ApplicationController
  def show
    authorize @games
    @game = Game.find(params[:id])
    return unless current_user

    @user_lists = current_user.lists.joins(:list_games).where(list_games: { game_id: @game.id })
  end
end
