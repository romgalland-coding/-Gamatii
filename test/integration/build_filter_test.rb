require "test_helper"

class BuildFilterTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  def setup
    Warden.test_mode!
    @user = User.create!(email: "owner@test.dev", password: "password", gamer_tag: "Builder")
    @list = @user.lists.create!(name: "My Faves", list_type: "custom")
    login_as @user, scope: :user
  end

  def teardown = Warden.test_reset!

  # Run the block with RawgService's network methods stubbed out so the build
  # page renders without hitting the live API. Returns canned filter options.
  def with_stubbed_rawg
    RawgService.class_eval do
      alias_method :__orig_search_games, :search_games
      alias_method :__orig_genres_discovery, :genres_discovery
      alias_method :__orig_tags, :tags
      define_method(:search_games) { |*| [] }
      define_method(:genres_discovery) { [{ id: 4, name: "Action" }, { id: 5, name: "RPG" }] }
      define_method(:tags) { [{ id: 31, name: "Singleplayer" }] }
    end
    yield
  ensure
    RawgService.class_eval do
      alias_method :search_games, :__orig_search_games
      alias_method :genres_discovery, :__orig_genres_discovery
      alias_method :tags, :__orig_tags
    end
  end

  test "build page shows the restyled filter panel, not the old offcanvas" do
    with_stubbed_rawg do
      get build_list_path(@list)
    end
    assert_response :success
    assert_select ".list-filter-panel"
    assert_select "[data-controller='build-filter']"
    assert_select ".list-filter-panel__save"
    assert_select ".offcanvas-bottom", false # old offcanvas is gone
  end

  test "an active genre filter round-trips into the panel as checked" do
    with_stubbed_rawg do
      get build_list_path(@list, genres: ["4"])
    end
    assert_response :success
    # The Action genre (id 4) checkbox is pre-checked.
    assert_select "input.filter-checkbox[name='genres[]'][value='4'][checked]"
    # A non-selected genre is not checked.
    assert_select "input.filter-checkbox[name='genres[]'][value='5'][checked]", false
  end
end
