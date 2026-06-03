class ListGamesController < ApplicationController
  def create
    @list = List.find(params[:list_id])
    rawg_data = RawgService.new.find(params[:rawg_id].to_i)

    @game = Game.find_or_create_by(rawg_id: params[:rawg_id].to_i) do |g|
      g.title        = rawg_data["name"]
      g.cover_img    = rawg_data["background_image"]
      g.genre        = rawg_data["genres"]&.first&.dig("name")
      g.platforms    = rawg_data["platforms"]&.map { |p| p.dig("platform", "name") } || []
      g.rating       = rawg_data["rating"]
      g.release_date = rawg_data["released"]
      g.publisher    = rawg_data["publishers"]&.first&.dig("name")
      g.developer    = rawg_data["developers"]&.first&.dig("name")
      g.description  = rawg_data["description_raw"]&.slice(0, 2000)
      g.game_mode    = rawg_data["tags"]&.map { |t| t["slug"] }&.select { |s| RawgService::GAME_MODE_SLUGS.include?(s) } || []
    end

    @list_game = ListGame.new(list: @list, game: @game)
    authorize @list_game

    filter_params = params.permit(:genre, :publisher, :game_mode, :rating, :from, :to, platforms: [])

    if @list_game.save
      redirect_to list_path(@list, **filter_params)
    else
      redirect_to list_path(@list, **filter_params), alert: "Could not add game to list."
    end
  end

  def destroy
    @list_game = ListGame.find(params[:id])
    @list = @list_game.list
    authorize @list, :update?
    @list_game.destroy
    redirect_to list_path(@list)
  end
end
