class ListsController < ApplicationController
  before_action :authenticate_user!, only: %i[new create edit update destroy]
  before_action :set_list, only: %i[show edit update destroy]

  def index
    @lists = policy_scope(List)
    if current_user
      @lists = current_user.lists.includes(:games).order(created_at: :desc)
    else
      @lists = List.includes(:games).order(created_at: :desc)
    end
  end

  def show
    @games = @list.games
    authorize @list
  end

  def new
    @list = List.new
    authorize @list
  end

  def create
    @list = current_user.lists.build(list_params)
    authorize @list
    if @list.save
      redirect_to @list
    else
      render :new, status: :unprocessable_entity
    end
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
    @list = List.find(params[:id])
  end

  def list_params
    params.require(:list).permit(:name)
  end
end
