require "test_helper"

class CommentTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "commenter@test.com",
      password: "password123",
      gamer_tag: "Commenter1"
    )
    @post_owner = User.create!(
      email: "poster@test.com",
      password: "password123",
      gamer_tag: "PostOwner1"
    )
    @post = @post_owner.posts.create!(body: "Test post")
  end

  test "valid with body, user, and post" do
    comment = @post.comments.build(user: @user, body: "Great post!")
    assert comment.valid?
  end

  test "invalid without body" do
    comment = @post.comments.build(user: @user, body: nil)
    assert_not comment.valid?
    assert comment.errors[:body].any?
  end

  test "body length capped at 500 chars" do
    comment = @post.comments.build(user: @user, body: "x" * 501)
    assert_not comment.valid?
    assert comment.errors[:body].any?
  end

  test "belongs to user and post" do
    comment = @post.comments.create!(user: @user, body: "Nice!")
    assert_equal @user, comment.user
    assert_equal @post, comment.post
  end
end
