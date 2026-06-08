class FollowsController < ApplicationController
  before_action :set_target

  def create
    authorize @target, policy_class: FollowPolicy
    current_user.follow(@target)
    respond_with_button
  end

  def destroy
    authorize @target, policy_class: FollowPolicy
    current_user.unfollow(@target)
    respond_with_button
  end

  private

  def set_target
    @target = User.find(params[:user_id])
  end

  def respond_with_button
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to user_path(@target) }
    end
  end
end
