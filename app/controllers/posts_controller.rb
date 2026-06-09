class PostsController < ApplicationController
  before_action :set_post, only: [:show, :destroy]

  def index
    @posts = policy_scope(Post).includes(:user, :comments, :likes)
                               .order(created_at: :desc)
  end

  def show
    authorize @post
  end

  def create
    @post = current_user.posts.build(post_params)
    authorize @post
    if @post.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to root_path }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.update("post-form-errors", partial: "posts/form_errors", locals: { post: @post }) }
        format.html { redirect_to root_path, alert: @post.errors.full_messages.to_sentence }
      end
    end
  end

  def destroy
    authorize @post
    @post.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("post-#{@post.id}") }
      format.html { redirect_to root_path }
    end
  end

  private

  def set_post
    @post = Post.includes({ list: :games }, { comments: :user }, :likes, :user).find(params[:id])
  end

  def post_params
    params.require(:post).permit(:body, :url, :photo_url, :list_id)
  end
end
