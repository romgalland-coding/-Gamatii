class ListGamesController < ApplicationController
  def create
    @list = List.find(params[:list_id])
    rawg_data = RawgService.new.find(params[:rawg_id])
    @game = Game.find_or_create_by(rawg_id: params[:rawg_id].to_i) do |g|
      g.title        = rawg_data["name"]
      g.cover_img    = rawg_data["background_image"]
      g.genre        = rawg_data["genres"]&.first&.dig("name")
      g.platforms    = rawg_data["platforms"]&.map { |p| p.dig("platform", "name") } || []
      g.rating       = rawg_data["rating"]
      g.release_date = rawg_data["released"]
      g.publisher    = rawg_data["publishers"]&.first&.dig("name")
      g.developer    = rawg_data["developers"]&.first&.dig("name")
    end
    @list_game = ListGame.new(list: @list, game: @game)
    authorize @list_game
    filter_params = params.permit(:genre, :publisher, :game_mode, :rating, :from, :to, platforms: [])
    if @list_game.save
      redirect_to discover_list_path(@list, **filter_params)
    else
      redirect_to discover_list_path(@list, **filter_params), alert: "Could not add game to list."
    end
  end

  def destroy
  end
end
