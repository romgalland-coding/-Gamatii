require "application_system_test_case"

class HomeAuthorLinksTest < ApplicationSystemTestCase
  include Warden::Test::Helpers

  setup do
    Warden.test_mode!
    @me = User.create!(email: "me@test.dev", password: "password", gamer_tag: "MeViewer")
    @author = User.create!(email: "author@test.dev", password: "password", gamer_tag: "PostAuthor")
    @me.follow(@author)

    @post = Post.create!(user: @author, body: "Just beat Elden Ring!")
    Comment.create!(post: @post, user: @author, body: "Took me 90 hours.")

    login_as @me, scope: :user
  end

  teardown { Warden.test_reset! }

  test "clicking a post author's name on the home feed opens their profile" do
    visit root_path
    assert_text "Just beat Elden Ring!"

    find("#post-#{@post.id} .post-card__user").click

    assert_current_path user_path(@author)
    assert_text "PostAuthor's lists"
  end

  test "clicking a comment author's name opens their profile" do
    visit root_path
    # Open the comments section on the post.
    find("#post-#{@post.id} .post-card__stat").click
    assert_text "Took me 90 hours."

    find("#post-#{@post.id} .post-comment__user").click

    assert_current_path user_path(@author)
  end
end
