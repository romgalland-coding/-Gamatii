class ListGamesController < ApplicationController
  def create
    @list = List.find(params[:list_id])
    authorize @list, :update?

    game = Game.find_by(title: params[:game_title])

    unless game
      rawg_data = RawgService.new.find(params[:rawg_id].to_i)
      platforms = rawg_data["platforms"]&.map { |p| p.dig("platform", "name") } || []
      game = Game.create!(
        title:        rawg_data["name"],
        cover_img:    rawg_data["background_image"],
        genre:        rawg_data.dig("genres", 0, "name"),
        developer:    rawg_data.dig("developers", 0, "name"),
        publisher:    rawg_data.dig("publishers", 0, "name"),
        release_date: rawg_data["released"],
        rating:       rawg_data["rating"],
        description:  rawg_data["description_raw"]&.slice(0, 2000),
        platforms:    platforms,
        game_mode:    []
      )
    end

    ListGame.find_or_create_by(list: @list, game: game)
    redirect_to list_path(@list)
  end

  def destroy
    @list_game = ListGame.find(params[:id])
    @list = @list_game.list
    authorize @list, :update?
    @list_game.destroy
    redirect_to list_path(@list)
  end
end
