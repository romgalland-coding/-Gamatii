class ListsController < ApplicationController
  before_action :authenticate_user!, only: %i[new create edit update destroy build like]
  before_action :require_login_or_redirect, only: :index
  before_action :set_list, only: %i[show edit update destroy like]

  def index
    @lists = current_user.lists.includes(:games, :user).order(created_at: :desc)
  end

  def show
    @list_games = @list.list_games
    authorize @list
  end

  def new
    @list = List.new
    authorize @list
    load_rawg_filter_options
  end

  def create
    @list = current_user.lists.build(list_params.merge(list_type: "custom"))
    authorize @list

    # From the Discover chatbot: create the list and drop the recommended game
    # into it in one shot. The card's JS then asks for the next recommendation.
    if params[:origin] == "chat"
      if @list.save
        ListGame.find_or_create_by(list: @list, game: Game.find(params[:game_id]))
        head :ok
      else
        head :unprocessable_entity
      end
      return
    end

    if @list.save
      redirect_to build_list_path(@list,
        genres:     params[:genres],
        platforms:  params[:platforms],
        publishers: params[:publishers],
        game_modes: params[:game_modes],
        rating:     params[:rating],
        from:       params[:from],
        to:         params[:to]
      )
    else
      load_rawg_filter_options
      render :new, status: :unprocessable_entity
    end
  end

  def build
    @list = List.find(params[:id])
    authorize @list
    load_rawg_filter_options
    rawg = RawgService.new
    @games = rawg.search_games(
      genres:     params[:genres],
      platforms:  params[:platforms],
      publishers: params[:publishers],
      game_modes: params[:game_modes],
      rating:     params[:rating],
      from:       params[:from],
      to:         params[:to],
      limit:      params[:limit],
      page:       params[:page]&.to_i
    )
    @games_in_list = @list.games.pluck(:rawg_id)
    @next_page = params[:page].present? ? params[:page].to_i + 1 : nil

    respond_to do |format|
      format.turbo_stream if params[:page].present?
      format.html
    end
  end

  def edit
    authorize @list
  end

  def search
    skip_authorization
    @query = params[:query].to_s.strip
    @page  = (params[:page] || 1).to_i

    if @query.length >= 2
      results = List.includes(:user, :games)
                    .where("name ILIKE ?", "%#{@query}%")
                    .order(Arel.sql("COALESCE(votes_count, 0) DESC"))
                    .offset((@page - 1) * 10)
                    .limit(11)
      @has_more = results.size == 11
      @lists    = results.first(10)
    else
      @lists    = []
      @has_more = false
    end

    respond_to do |format|
      format.turbo_stream
    end
  end

  def search_games
    skip_authorization
    @query = params[:query]
    @list_id = params[:list_id]
    list = List.includes(list_games: :game).find(@list_id)
    @existing_by_rawg_id = list.list_games.to_h { |lg| [lg.game.rawg_id, lg] }
    @results = RawgService.new.search(@query)

    respond_to do |format|
      format.turbo_stream
    end
  end

  def update
    authorize @list
    if @list.update(list_params)
      redirect_to @list
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @list
    @list.destroy
    redirect_to lists_path
  end

  def like
    authorize @list
    like = current_user.list_likes.find_by(list: @list)
    if like
      like.destroy
      @list.decrement!(:votes_count)
    else
      current_user.list_likes.create!(list: @list)
      @list.increment!(:votes_count)
    end
    respond_to { |f| f.turbo_stream }
  end

  private

  def set_list
    @list = List.includes(:list_games, :games).find(params[:id])
  end

  def list_params
    params.require(:list).permit(:name)
  end
end
