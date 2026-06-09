class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    authorize @user
    @lists = @user.lists.includes(:games).order(votes_count: :desc, created_at: :desc)
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

    if @user.update(user_params)
      respond_to do |format|
        # Inline bio save from the profile page swaps just the bio region.
        format.turbo_stream { render_bio_stream }
        format.html { redirect_to settings_profile_path, notice: "Profil mis à jour" }
      end
    else
      respond_to do |format|
        format.turbo_stream { render_bio_stream(status: :unprocessable_entity) }
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

  # Replace just the profile bio region (used by the inline bio editor).
  def render_bio_stream(status: :ok)
    render(
      turbo_stream: turbo_stream.replace(
        "profile-bio",
        partial: "users/bio",
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
      :password,
      :password_confirmation,
      platform: []
    )
  end
end
