class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[home discover]
  before_action :require_login_or_redirect, only: :discover

  def home
    # NOTE: "popular" is seed-driven for now. Eventually these will rank by
    # activity over a rolling 3-day window — the "this week" / "last 3 days"
    # copy in the view is placeholder text for that future logic.
    @popular_games = Game.left_joins(:list_games)
                         .group(:id)
                         .order(Arel.sql("COUNT(list_games.id) DESC"))
                         .limit(4)

    @popular_lists = List.includes(:user).order(votes_count: :desc).limit(4)

    if current_user
      followed_ids = current_user.following.pluck(:id) + [current_user.id]
      @feed_posts = Post.where(user_id: followed_ids)
                        .includes(:user, { list: :games }, { comments: :user }, :likes)
                        .order(created_at: :desc)
                        .limit(30)
    end
  end

  def discover
    @chats = current_user.chats.order(updated_at: :desc)
    @top_lists_this_week = List.includes(:user, :games)
                               .where(created_at: 7.days.ago..)
                               .order(Arel.sql("COALESCE(votes_count, 0) DESC"))
                               .limit(3)
  end

end
