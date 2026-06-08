class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  after_action :verify_authorized, except: :index, unless: :skip_pundit?
  after_action :verify_policy_scoped, only: :index, unless: :skip_pundit?

  private

  def user_not_authorized
    flash[:alert] = "You're not allowed to do that."
    redirect_back fallback_location: root_path
  end

  # Always send users to the homepage after login, ignoring Devise's stored
  # location (friendly forwarding). Without this, hitting an auth-protected page
  # while logged out — e.g. the quiz — would bounce there after sign-in.
  def after_sign_in_path_for(_resource)
    root_path
  end

  def load_rawg_filter_options
    rawg = RawgService.new
    # These four lists are cached in RawgService, but on a cold cache each one is
    # a blocking RAWG HTTP call. Fetch them concurrently so a cache-miss load
    # costs ~one round-trip instead of four sequential ones. Each thread checks
    # out its own DB/cache connection, which we release before joining.
    genres     = Thread.new { with_connection { rawg.genres_discovery } }
    game_modes = Thread.new { with_connection { rawg.tags } }

    @genres     = genres.value.sort_by { |g| g[:name].to_s }
    @platforms  = RawgService::CURATED_PLATFORMS
    @publishers = RawgService::CURATED_PUBLISHERS
    @game_modes = game_modes.value.sort_by { |t| t[:name].to_s }
  end

  def with_connection(&)
    ActiveRecord::Base.connection_pool.with_connection(&)
  end

  def skip_pundit?
    devise_controller? || params[:controller] =~ /(^(rails_)?admin)|(^pages$)/
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:gamer_tag, { platform: [] }])
    devise_parameter_sanitizer.permit(:account_update, keys: [:gamer_tag, { platform: [] }])
  end
end
