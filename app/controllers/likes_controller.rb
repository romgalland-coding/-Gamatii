class LikesController < ApplicationController
  before_action :set_post

  def create
    @like = @post.likes.build(user: current_user)
    authorize @like
    @like.save
    respond_to { |f| f.turbo_stream }
  end

  def destroy
    @like = @post.likes.find_by!(user: current_user)
    authorize @like
    @like.destroy
    respond_to { |f| f.turbo_stream }
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end
end
