require "application_system_test_case"

class ProfileBackTest < ApplicationSystemTestCase
  include Warden::Test::Helpers

  setup do
    Warden.test_mode!
    @me = User.create!(email: "me@test.dev", password: "password", gamer_tag: "MeViewer")
    @me.lists.create!(name: "My Own List", list_type: "custom")

    @other = User.create!(email: "other@test.dev", password: "password", gamer_tag: "FrostByte")
    @other_list = @other.lists.create!(name: "FrostByte Faves", list_type: "custom")

    login_as @me, scope: :user
  end

  teardown { Warden.test_reset! }

  test "Back on a public profile returns to the page you came from, not your own lists" do
    # Arrive at another user's list (as if from Home/Lists).
    visit list_path(@other_list)
    assert_text "FrostByte Faves"

    # Click their gamertag → their profile.
    click_link "FrostByte"
    assert_current_path user_path(@other)
    assert_text "FrostByte's lists"

    # Click Back — should return to FrostByte's list, NOT /lists.
    click_link "Back"
    assert_current_path list_path(@other_list)
    assert_text "FrostByte Faves"
  end
end
