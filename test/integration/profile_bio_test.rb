require "test_helper"

class ProfileBioTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  def setup
    Warden.test_mode!
    @me = User.create!(email: "me@test.dev", password: "password", gamer_tag: "MeOwner")
    @other = User.create!(email: "other@test.dev", password: "password", gamer_tag: "Stranger",
                          bio: "their bio")
  end

  def teardown = Warden.test_reset!

  test "own profile shows the empty state when bio is blank" do
    login_as @me, scope: :user
    get profile_path
    assert_response :success
    assert_match "user-profile__bio-empty", @response.body
    assert_match "Add a bio", @response.body
  end

  test "own profile shows the bio with an inline edit affordance when present" do
    @me.update!(bio: "I main support")
    login_as @me, scope: :user
    get profile_path
    assert_response :success
    assert_match "I main support", @response.body
    assert_match "user-profile__bio-edit", @response.body
  end

  test "inline bio save updates via turbo_stream" do
    login_as @me, scope: :user
    patch profile_path,
          params: { user: { bio: "Speedrunner, mostly Soulslikes" } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_match "profile-bio", @response.body
    assert_match "Speedrunner, mostly Soulslikes", @response.body
    assert_equal "Speedrunner, mostly Soulslikes", @me.reload.bio
  end

  test "another user's profile shows their bio but no edit affordance" do
    login_as @me, scope: :user
    get user_path(@other)
    assert_response :success
    assert_match "their bio", @response.body
    refute_match "user-profile__bio-empty", @response.body
    refute_match "user-profile__bio-edit", @response.body
  end

  test "over-long bio is rejected and re-renders the form with an error" do
    login_as @me, scope: :user
    patch profile_path,
          params: { user: { bio: "x" * 501 } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :unprocessable_entity
    assert_match "profile-bio", @response.body
    assert_nil @me.reload.bio
  end
end
