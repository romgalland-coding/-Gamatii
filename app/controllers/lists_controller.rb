class ListsController < ApplicationController
  before_action :authenticate_user!, only: %i[new create edit update destroy build]
  before_action :set_list, only: %i[show edit update destroy]

  def index
    @lists = policy_scope(List)
    if current_user
      @lists = current_user.lists.includes(:games, :user).order(created_at: :desc)
    else
      @lists = List.includes(:games, :user).order(created_at: :desc)
    end
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
      to:         params[:to]
    )
    @games_in_list = @list.games.pluck(:rawg_id)
  end

  def edit
    authorize @list
  end

  def search_games
    skip_authorization
    @query = params[:query]
    @list_id = params[:list_id]
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

  private

  def set_list
    @list = List.includes(:list_games, :games).find(params[:id])
  end

  def list_params
    params.require(:list).permit(:name)
  end
end
