class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    authorize @user
    @lists = @user.lists.includes(:games).order(votes_count: :desc, created_at: :desc)
    @posts = @user.posts.includes(:list, :comments, :likes).order(created_at: :desc)
  end

  def settings
    @user = current_user
    authorize @user, :show?
  end

  def edit
    @user = current_user
    authorize @user
  end

  def update
    @user = current_user
    authorize @user
    strip_blank_password

    # Which inline region to swap back depends on what was edited: the emoji
    # picker updates the avatar, everything else (bio editor) the bio.
    region = params[:user].key?(:avatar_emoji) ? :avatar : :bio

    if @user.update(user_params)
      respond_to do |format|
        format.turbo_stream { render_inline_stream(region) }
        format.html { redirect_to settings_profile_path, notice: "Profil mis à jour" }
      end
    else
      respond_to do |format|
        format.turbo_stream { render_inline_stream(region, status: :unprocessable_entity) }
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  private

  # Drop blank password fields so updating other attributes (e.g. bio) doesn't
  # overwrite the existing password.
  def strip_blank_password
    return if params[:user][:password].present?

    params[:user].delete(:password)
    params[:user].delete(:password_confirmation)
  end

  # Replace just the inline region the edit touched (bio editor or emoji picker).
  def render_inline_stream(region, status: :ok)
    target, partial = region == :avatar ? ["profile-avatar", "users/avatar_editor"] : ["profile-bio", "users/bio"]
    render(
      turbo_stream: turbo_stream.replace(
        target,
        partial: partial,
        locals: { user: @user, owner: true }
      ),
      status: status
    )
  end

  def user_params
    params.require(:user).permit(
      :gamer_tag,
      :email,
      :bio,
      :avatar_emoji,
      :avatar_color,
      :password,
      :password_confirmation,
      platform: []
    )
  end
end
