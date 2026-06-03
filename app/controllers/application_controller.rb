class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  include Pundit::Authorization

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  after_action :verify_authorized, except: :index, unless: :skip_pundit?
  after_action :verify_policy_scoped, only: :index, unless: :skip_pundit?

  private

  def load_rawg_filter_options
    rawg = RawgService.new
    @genres     = rawg.genres_discovery
    @platforms  = rawg.platforms
    @publishers = rawg.publishers
    @game_modes = rawg.tags
  end

  def skip_pundit?
    devise_controller? || params[:controller] =~ /(^(rails_)?admin)|(^pages$)/
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:gamer_tag, platform: []])
    devise_parameter_sanitizer.permit(:account_update, keys: [:gamer_tag, platform: []])
  end
end
