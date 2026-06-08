class CommentsController < ApplicationController
  before_action :set_post

  def create
    @comment = @post.comments.build(comment_params.merge(user: current_user))
    authorize @comment
    if @comment.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @post }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.update("comment-form-errors-#{@post.id}", partial: "comments/form_errors", locals: { comment: @comment }) }
        format.html { redirect_to @post, alert: @comment.errors.full_messages.to_sentence }
      end
    end
  end

  def destroy
    @comment = @post.comments.find(params[:id])
    authorize @comment
    @comment.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("comment-#{@comment.id}") }
      format.html { redirect_to @post }
    end
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
