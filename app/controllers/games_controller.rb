class GamesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show]
  def show
    @game = Game.find(params[:id])
    authorize @game
    return unless current_user

    @user_lists = current_user.lists.joins(:list_games).where(list_games: { game_id: @game.id })
  end

  def rawg_preview
    skip_authorization
    @rawg_id = params[:rawg_id]
    @game = RawgService.new.find(@rawg_id)
  end
end
