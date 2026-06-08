require "test_helper"

class PostTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "poster@test.com",
      password: "password123",
      gamer_tag: "TestPoster"
    )
    @post = @user.posts.build(body: "Hello world!")
  end

  test "valid with body" do
    assert @post.valid?
  end

  test "valid with url only" do
    @post.body = nil
    @post.url = "https://example.com"
    assert @post.valid?
  end

  test "invalid when body, photo, and url all blank" do
    @post.body = nil
    assert_not @post.valid?
    assert_includes @post.errors[:base], "A post must have text, a photo, or a URL"
  end

  test "invalid with malformed url" do
    @post.url = "not-a-url"
    assert_not @post.valid?
    assert @post.errors[:url].any?
  end

  test "valid with well-formed https url" do
    @post.url = "https://twitch.tv/stream"
    assert @post.valid?
  end

  test "body length capped at 2000 chars" do
    @post.body = "a" * 2001
    assert_not @post.valid?
    assert @post.errors[:body].any?
  end

  test "belongs to user" do
    @post.save!
    assert_equal @user, @post.user
  end

  test "destroys dependent comments" do
    @post.save!
    other = User.create!(email: "c@test.com", password: "pass1234", gamer_tag: "Commenter")
    @post.comments.create!(user: other, body: "Nice post")
    assert_difference("Comment.count", -1) { @post.destroy }
  end

  test "destroys dependent likes" do
    @post.save!
    other = User.create!(email: "l@test.com", password: "pass1234", gamer_tag: "LikrUser")
    @post.likes.create!(user: other)
    assert_difference("Like.count", -1) { @post.destroy }
  end
end
