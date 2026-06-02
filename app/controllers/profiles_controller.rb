class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    authorize @user
  end

  def edit
    @user = current_user
    authorize @user
  end

  def update
    @user = current_user
    authorize @user

    # Supprime le password des params s'il est vide pour ne pas l'écraser
    if params[:user][:password].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end

    if @user.update(user_params)
      redirect_to profile_path, notice: "Profil mis à jour"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(
      :gamer_tag,
      :email,
      :password,
      :password_confirmation,
      platform: [],
    )
  end
end
