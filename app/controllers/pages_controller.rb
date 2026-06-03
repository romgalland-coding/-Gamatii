class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  def home
  end

  def discover
    @list = List.new
    @recent_lists = List.includes(:games).order(created_at: :desc).limit(3)
    load_rawg_filter_options
  end
end
