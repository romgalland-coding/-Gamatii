class DiscoverController < ApplicationController
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def index
    @lists = current_user.lists
    @list = List.new
  end

  def create
    @list = current_user.lists.build(name: params[:list][:name], list_type: "custom")
    if @list.save
      redirect_to discover_list_path(@list)
    else
      @lists = current_user.lists
      render :index
    end
  end

  def show
    @list = current_user.lists.find(params[:id])
    @games = params[:query].present? ?
      Game.where("title ILIKE ?", "%#{params[:query]}%") :
      Game.all
  end
end
