require "test_helper"

class LikeTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "liker@test.com",
      password: "password123",
      gamer_tag: "LikerUser1"
    )
    @owner = User.create!(
      email: "owner@test.com",
      password: "password123",
      gamer_tag: "OwnerUser1"
    )
    @post = @owner.posts.create!(body: "Post to like")
  end

  test "valid like on a post" do
    like = @post.likes.build(user: @user)
    assert like.valid?
  end

  test "prevents duplicate like by same user on same post" do
    @post.likes.create!(user: @user)
    duplicate = @post.likes.build(user: @user)
    assert_not duplicate.valid?
    assert duplicate.errors[:user_id].any?
  end

  test "two different users can like the same post" do
    other = User.create!(email: "other@test.com", password: "pass1234", gamer_tag: "OtherUser2")
    @post.likes.create!(user: @user)
    like2 = @post.likes.build(user: other)
    assert like2.valid?
  end

  test "polymorphic — can like a comment too" do
    commenter = User.create!(email: "cx@test.com", password: "pass1234", gamer_tag: "CmtrUser")
    comment = @post.comments.create!(user: commenter, body: "Nice!")
    like = comment.likes.build(user: @user)
    assert like.valid?
  end

  test "belongs to user and likeable" do
    like = @post.likes.create!(user: @user)
    assert_equal @user, like.user
    assert_equal @post, like.likeable
  end
end
