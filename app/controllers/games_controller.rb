class GamesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show]
  def show
    @game = Game.find(params[:id])
    authorize @game

    # Lazily fetch + cache buy links on first view. Guard on blank? (not nil?):
    # the column defaults to [], so nil? never fires for imported/seeded games.
    if @game.rawg_id.present? && @game.store_links.blank?
      links = RawgService.new.stores(@game.rawg_id)
      @game.update_columns(store_links: links)
    end

    return unless current_user

    @user_lists = current_user.lists.joins(:list_games).where(list_games: { game_id: @game.id })
    @all_user_lists = current_user.lists
    @game_list_games = ListGame.joins(:list)
                               .where(lists: { user_id: current_user.id }, game_id: @game.id)
                               .index_by(&:list_id)
  end

  def rawg_preview
    skip_authorization
    @rawg_id = params[:rawg_id]
    @game = RawgService.new.find(@rawg_id)
  end
end
