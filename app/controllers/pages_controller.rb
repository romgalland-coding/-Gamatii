class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  def home
    # NOTE: "popular" is seed-driven for now. Eventually these will rank by
    # activity over a rolling 3-day window — the "this week" / "last 3 days"
    # copy in the view is placeholder text for that future logic.
    @popular_games = Game.left_joins(:list_games)
                         .group(:id)
                         .order(Arel.sql("COUNT(list_games.id) DESC"))
                         .limit(4)

    @popular_lists = List.order(votes_count: :desc).limit(4)
  end

  def discover
    @list = List.new
    @recent_lists = List.includes(:games).order(created_at: :desc).limit(3)
    load_rawg_filter_options
  end
end
