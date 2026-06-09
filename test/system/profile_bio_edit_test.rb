require "application_system_test_case"

class ProfileBioEditTest < ApplicationSystemTestCase
  include Warden::Test::Helpers

  setup do
    Warden.test_mode!
    @me = User.create!(email: "me@test.dev", password: "password", gamer_tag: "MeOwner")
    login_as @me, scope: :user
  end

  teardown { Warden.test_reset! }

  test "owner can add a bio inline from the empty state" do
    visit profile_path
    assert_text "Add a bio"

    click_button "Add a bio"
    fill_in "user_bio", with: "Soulslike speedrunner."
    click_button "Save"

    # The bio region swaps in with the saved text; empty state is gone.
    assert_text "Soulslike speedrunner."
    assert_no_text "Add a bio"
    assert_equal "Soulslike speedrunner.", @me.reload.bio
  end
end
