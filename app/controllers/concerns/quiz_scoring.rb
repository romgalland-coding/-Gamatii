# Shared scoring + leaderboard logic for the daily quiz, used by both
# QuizzesController (rendering the tab) and QuizGamesController (the turbo_stream
# response after a guess). Keeping it in one place stops the two from drifting.
module QuizScoring
  extend ActiveSupport::Concern

  POINTS_BY_RANK = [50, 40, 30, 20, 10].freeze

  # Points for a set of guessed titles against the ordered answer pool.
  def score_for(answers, guessed_titles)
    answers.each_with_index.sum do |game, rank|
      guessed_titles.include?(normalize_title(game.title)) ? POINTS_BY_RANK[rank] : 0
    end
  end

  def normalize_title(title)
    title.to_s.downcase.strip
  end

  # How many of the answers the given titles cover.
  def found_count(answers, guessed_titles)
    answers.count { |g| guessed_titles.include?(normalize_title(g.title)) }
  end

  # Ranks everyone who guessed on `quiz` by score (found-count as tiebreaker).
  # `current_user` is always included so they see their own rank. Returns the
  # ranked rows plus the current user's rank and the total player count.
  def leaderboard_for(quiz, answers)
    rows = QuizGame.guesses.where(quiz: quiz).includes(:game, :user)
                   .group_by(&:user)
                   .map { |user, qgs| leaderboard_row(user, qgs, answers) }

    rows << leaderboard_row(current_user, [], answers) if rows.none? { |r| r[:user] == current_user }

    ranked = rows.sort_by { |r| [-r[:score], -r[:found]] }
                 .each_with_index.map { |r, i| r.merge(rank: i + 1) }
    me = ranked.find { |r| r[:user] == current_user }
    { rows: window_around(ranked, me), my_rank: me[:rank], total_players: ranked.size }
  end

  # Keep the leaderboard a fixed size: show `me` plus up to 2 above and 2 below.
  # Near an edge we extend the other way so the window is always ~5 rows (or
  # fewer when there aren't enough players total).
  WINDOW_RADIUS = 2

  def window_around(ranked, me)
    size = WINDOW_RADIUS * 2 + 1
    idx  = ranked.index(me)
    first = [idx - WINDOW_RADIUS, 0].max
    first = [ranked.size - size, 0].max if first + size > ranked.size
    ranked[first, size]
  end

  def leaderboard_row(user, quiz_games, answers)
    titles = quiz_games.to_set { |qg| normalize_title(qg.game.title) }
    { user: user, score: score_for(answers, titles), found: found_count(answers, titles) }
  end
end
