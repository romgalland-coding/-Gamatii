class QuizSchedule < ApplicationRecord
  LAST_POSITION = Quiz::THEMES.size - 1 # 13 — the final day of the demo
  ZONE = "Europe/Paris".freeze # CET/CEST — the timezone the rotation runs on

  # The single row that tracks which day of the rotation we're on. Durable
  # source of truth (survives restarts) read on every /daily request and
  # advanced once a night by DailyRotationJob.
  def self.instance
    first_or_create!
  end

  def today_quiz
    Quiz.find_by(position: current_position)
  end

  # On day 0 there is no real "yesterday", so we wrap to the last position
  # (the final day's quiz) purely so the guessing UI has something to show
  # while testing. Past day 0 it's simply the previous position.
  def yesterday_quiz
    previous = current_position.zero? ? LAST_POSITION : current_position - 1
    Quiz.find_by(position: previous)
  end

  # Advance one day. Capped at the last position so the 14-day demo can't run
  # off the end, and idempotent within a CET day so a double-trigger is a no-op.
  #
  # `now` is a UTC timestamp; all "what day is it?" logic is done in CET so the
  # stored timestamp (UTC in the DB) and the comparison agree. Comparing bare
  # Dates against a datetime column round-trips through UTC and drifts a day —
  # this keeps both sides in the same zone instead.
  def rotate!(now: Time.current)
    today = now.in_time_zone(ZONE).to_date
    return self if last_rotated_at&.in_time_zone(ZONE)&.to_date == today
    return self if current_position >= LAST_POSITION

    update!(current_position: current_position + 1, last_rotated_at: now)
  end
end
