require "test_helper"
class FollowFlowTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  def setup
    Warden.test_mode!
    @viewer = User.create!(email: "viewer@test.dev", password: "password", gamer_tag: "ViewerOne")
    @target = User.create!(email: "target@test.dev", password: "password", gamer_tag: "TargetTwo",
                           bio: "hello", avatar_emoji: "🐉", avatar_color: "#9FC5F8")
  end

  def teardown = Warden.test_reset!

  test "profile is public" do
    get user_path(@target)
    assert_response :success
    assert_match @target.gamer_tag, @response.body
    assert_match "hello", @response.body
  end

  test "follow button toggles blue->green via turbo_stream" do
    login_as @viewer, scope: :user

    get user_path(@target)
    assert_response :success
    assert_match "profile-follow__btn--follow", @response.body

    post user_follow_path(@target), headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_match "profile-follow__btn--following", @response.body
    assert @viewer.reload.following?(@target)

    delete user_follow_path(@target), headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_match "profile-follow__btn--follow", @response.body
    refute @viewer.reload.following?(@target)
  end

  test "followers modal lists followers" do
    @viewer.follow(@target)
    login_as @viewer, scope: :user
    get followers_user_path(@target), headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_match "user-modal", @response.body
    assert_match @viewer.gamer_tag, @response.body
  end

  test "cannot follow yourself" do
    login_as @viewer, scope: :user
    # Policy denies self-follows; the rescue_from turns that into a redirect,
    # not a 500. The UI also never renders a self-follow button.
    post user_follow_path(@viewer)
    assert_response :redirect
    refute @viewer.reload.following?(@viewer)
  end
end
