class UsersController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[show followers following]
  before_action :set_user, except: %i[find_friends search]

  def find_friends
    authorize User, :find_friends?
    @users = User.where.not(id: current_user.id).order(:gamer_tag)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to root_path }
    end
  end

  def search
    authorize User, :search?
    q = params[:q].to_s.strip
    @users = if q.length >= 2
      User.where.not(id: current_user.id)
          .where("gamer_tag ILIKE ?", "%#{q}%")
          .order(:gamer_tag)
          .limit(20)
    else
      User.where.not(id: current_user.id).order(:gamer_tag).limit(20)
    end
  end

  def show
    authorize @user
    @lists = @user.lists.includes(:games).order(votes_count: :desc, created_at: :desc)
  end

  def followers
    authorize @user
    @title = "Followers"
    @users = @user.followers.order(:gamer_tag)
    render_user_list_modal
  end

  def following
    authorize @user
    @title = "Following"
    @users = @user.following.order(:gamer_tag)
    render_user_list_modal
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def render_user_list_modal
    respond_to do |format|
      format.html { render partial: "users/user_list_modal", locals: { title: @title, users: @users, user: @user } }
      format.turbo_stream
    end
  end
end
