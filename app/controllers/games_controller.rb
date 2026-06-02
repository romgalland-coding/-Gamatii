class GamesController < ApplicationController
  def show
    @game = Game.find(params[:id])
    authorize @game
    return unless current_user

    @user_lists = current_user.lists.joins(:list_games).where(list_games: { game_id: @game.id })
  end
end
