require "test_helper"

class OwnProfileTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  def setup
    Warden.test_mode!
    @user = User.create!(email: "me@test.dev", password: "password", gamer_tag: "MeMyself",
                         bio: "my bio here", avatar_emoji: "🦊", avatar_color: "#FFE599")
    login_as @user, scope: :user
  end

  def teardown = Warden.test_reset!

  test "own profile shows the social layout with a settings gear, not a follow button" do
    get profile_path
    assert_response :success
    assert_match "user-profile__name", @response.body
    assert_match "my bio here", @response.body
    assert_match "user-profile__settings", @response.body          # gear present
    assert_match settings_profile_path, @response.body             # gear links to settings
    refute_match "profile-follow__btn", @response.body             # no follow button on own profile
    assert_match "Your lists", @response.body
  end

  test "settings page shows account management" do
    get settings_profile_path
    assert_response :success
    assert_match @user.email, @response.body
    assert_match "Gamertag", @response.body
    assert_match "Log out", @response.body
    assert_match "Delete account", @response.body
  end

  test "settings requires login" do
    logout
    get settings_profile_path
    assert_redirected_to new_user_session_path
  end
end
