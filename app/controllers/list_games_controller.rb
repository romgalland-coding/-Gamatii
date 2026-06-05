class ListGamesController < ApplicationController
  def create
    @list = List.find(params[:list_id])
    rawg_data = RawgService.new.find(params[:rawg_id].to_i)

    @game = Game.find_or_create_by(rawg_id: params[:rawg_id].to_i) do |g|
      g.title        = rawg_data["name"]
      g.cover_img    = rawg_data["background_image"]
      g.genre        = rawg_data["genres"]&.first&.dig("name")
      g.platforms    = rawg_data["platforms"]&.map { |p| p.dig("platform", "name") } || []
      g.rating       = rawg_data["metacritic"] # column holds the Metascore (0–100); see db/seeds.rb
      g.release_date = rawg_data["released"]
      g.publisher    = rawg_data["publishers"]&.first&.dig("name")
      g.developer    = rawg_data["developers"]&.first&.dig("name")
      g.description  = rawg_data["description_raw"]&.slice(0, 2000)
      g.game_mode    = rawg_data["tags"]&.map { |t| t["slug"] }&.select { |s| RawgService::GAME_MODE_SLUGS.include?(s) } || []
    end

    @list_game = ListGame.new(list: @list, game: @game)
    authorize @list_game

    saved = @list_game.save

    if params[:origin] == "build"
      filter_params = params.permit(:rating, :from, :to, genres: [], platforms: [], publishers: [], game_modes: [])
      redirect_to build_list_path(@list, **filter_params),
                  alert: (saved ? nil : "Could not add game to list.")
    elsif params[:origin].in?(%w[game_show chat swipe])
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to game_path(@game) }
      end
    else
      redirect_to list_path(@list),
                  alert: (saved ? nil : "Could not add game to list.")
    end
  end

  def destroy
    @list_game = ListGame.find(params[:id])
    @list = @list_game.list
    @game = @list_game.game
    authorize @list, :update?
    @list_game.destroy

    if params[:origin].in?(%w[game_show chat])
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to game_path(@game) }
      end
    else
      redirect_to list_path(@list)
    end
  end
end
