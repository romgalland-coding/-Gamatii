class ListGamesController < ApplicationController
  skip_after_action :verify_authorized

  def create
    @list = List.find(params[:list_id])
    @game = Game.find(params[:game_id])
    @list_game = ListGame.new(list: @list, game: @game)

    respond_to do |format|
      if @list_game.save
        format.html { redirect_to request.referrer || discover_path }
        format.json { render json: { success: true } }
      else
        format.html { redirect_to request.referrer }
        format.json { render json: { success: false }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @list_game = ListGame.find(params[:id])
    list_id = @list_game.list_id
    @list_game.destroy
    redirect_to list_path(list_id)
  end
end
