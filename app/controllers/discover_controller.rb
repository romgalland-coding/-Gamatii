class DiscoverController < ApplicationController
  def index
    @lists = current_user.lists.order(created_at: :desc)
    @selected_list_id = params[:list_id]&.to_i

    session[:discover_skipped_ids] = [] if params[:start] == '1'

    @game = next_game if @selected_list_id&.positive?
  end

  def swipe
    game_id  = params[:game_id].to_i
    list_id  = params[:list_id].to_i
    direction = params[:direction]

    session[:discover_skipped_ids] ||= []
    session[:discover_skipped_ids] << game_id

    if direction == 'right'
      list = current_user.lists.find_by(id: list_id)
      ListGame.find_or_create_by(list: list, game_id: game_id) if list
    end

    @game = next_game
    @selected_list_id = list_id

    render turbo_stream: turbo_stream.update(
      'game-card-frame',
      partial: 'discover/game_card',
      locals: { game: @game, list_id: @selected_list_id }
    )
  end

  private

  def next_game
    skipped = session[:discover_skipped_ids] || []
    Game.where.not(id: skipped).order("RANDOM()").first
  end
end
