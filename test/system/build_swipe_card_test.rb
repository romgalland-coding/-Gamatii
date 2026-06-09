require "application_system_test_case"

class BuildSwipeCardTest < ApplicationSystemTestCase
  include Warden::Test::Helpers

  setup do
    Warden.test_mode!
    @user = User.create!(email: "owner@test.dev", password: "password", gamer_tag: "Builder")
    @list = @user.lists.create!(name: "Played Backlog", list_type: "played")
    login_as @user, scope: :user

    # Stub the RAWG search so the build page renders one swipe card offline.
    RawgService.class_eval do
      alias_method :__orig_search_games, :search_games
      alias_method :__orig_genres_discovery, :genres_discovery
      alias_method :__orig_tags, :tags
      define_method(:search_games) do |*|
        [{
          "id" => 3498, "name" => "Grand Theft Auto V",
          "background_image" => "https://media.rawg.io/media/games/gta.jpg",
          "metacritic" => 92, "released" => "2013-09-17",
          "genres" => [{ "name" => "Action" }],
          "platforms" => [{ "platform" => { "name" => "PlayStation 5" } }]
        }]
      end
      define_method(:genres_discovery) { [] }
      define_method(:tags) { [] }
    end
  end

  teardown do
    if RawgService.private_method_defined?(:__orig_search_games) ||
       RawgService.method_defined?(:__orig_search_games)
      RawgService.class_eval do
        alias_method :search_games, :__orig_search_games
        alias_method :genres_discovery, :__orig_genres_discovery
        alias_method :tags, :__orig_tags
      end
    end
    Warden.test_reset!
  end

  test "swipe card is constrained to a card width on desktop, not full page" do
    visit build_list_path(@list, tab: "swipe")
    assert_text "Grand Theft Auto V"

    card = find(".swipe-card", match: :first)
    width = card.evaluate_script("this.getBoundingClientRect().width")
    # The deck is capped at 380px; the card must be far narrower than the 1400px page.
    assert_operator width, :<=, 400, "swipe card should be card-width, got #{width}px"
    assert_operator width, :>=, 300, "swipe card should not be tiny, got #{width}px"

    save_screenshot("tmp/screenshots/swipe_card_width.png")
  end
end
