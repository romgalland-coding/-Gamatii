require "test_helper"

class ListDiscoverAddTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  def setup
    Warden.test_mode!
    @user = User.create!(email: "owner@test.dev", password: "password", gamer_tag: "ListOwner")
    @list = @user.lists.create!(name: "My Faves", list_type: "custom")
    # The list already has one game — we're "editing" a non-empty list.
    @existing = Game.create!(rawg_id: 1, title: "Existing Game")
    @list.list_games.create!(game: @existing)
    login_as @user, scope: :user
  end

  def teardown = Warden.test_reset!

  test "list show page links to the discovery (build) view" do
    get list_path(@list)
    assert_response :success
    assert_select "a.list-show__discover-btn[href=?]", build_list_path(@list)
  end

  test "adding a game from the discovery view appends to the existing list" do
    # The game is already in the catalogue, so ListGame#create's find_or_create_by
    # short-circuits and never calls the live RAWG API.
    Game.create!(rawg_id: 42, title: "Hollow Knight")

    assert_difference -> { @list.reload.games.count }, 1 do
      post list_list_games_path(@list), params: { rawg_id: 42, origin: "build" }
    end

    assert @list.games.exists?(rawg_id: 42), "new game should be in the list"
    assert @list.games.exists?(rawg_id: 1), "existing game should remain"
    assert_redirected_to build_list_path(@list) # stays in the discovery view to keep adding
  end
end
