class QuizSchedule < ApplicationRecord
  POSITION_COUNT = Quiz::THEMES.size  # 14 themes
  LAST_POSITION  = POSITION_COUNT - 1 # 13 — the final position
  ZONE = "Europe/Paris".freeze # CET/CEST — the timezone the rotation runs on

  # ── TEST MODE ────────────────────────────────────────────────────────────
  # While testing we rotate every 30 seconds instead of at midnight CET, and we
  # DERIVE the position from elapsed time rather than from a nightly job. This
  # means rotation "just happens" as time passes — no DB writes, no DailyRotationJob
  # — and the position wraps endlessly so the demo never runs out. The page
  # refreshes itself when the timer hits zero (see quiz_timer_controller.js).
  #
  # To go back to the real midnight rotation: set TEST_MODE = false and re-enable
  # the recurring DailyRotationJob in config/recurring.yml.
  TEST_MODE = true
  TEST_ROTATION_SECONDS = 120
  # Fixed anchor so window boundaries are stable across requests/processes.
  TEST_EPOCH = Time.utc(2026, 1, 1).freeze

  # The single row that tracks which day of the rotation we're on. Durable
  # source of truth (survives restarts) read on every /daily request and
  # advanced once a night by DailyRotationJob.
  def self.instance
    first_or_create!
  end

  # In test mode, position is a pure function of elapsed 30s windows (wrapping
  # mod 14). Otherwise it's the stored column advanced by the nightly job.
  def position(now: Time.current)
    return current_position unless TEST_MODE

    (elapsed_windows(now) % POSITION_COUNT)
  end

  def today_quiz(now: Time.current)
    Quiz.find_by(position: position(now: now))
  end

  # On position 0 there is no real "yesterday", so we wrap to the last position
  # (the final theme) purely so the guessing UI has something to show.
  def yesterday_quiz(now: Time.current)
    current  = position(now: now)
    previous = current.zero? ? LAST_POSITION : current - 1
    Quiz.find_by(position: previous)
  end

  # Seconds left in the current window — drives the countdown timer. In real
  # (midnight) mode this is the seconds until the next CET midnight.
  def seconds_until_next_rotation(now: Time.current)
    if TEST_MODE
      TEST_ROTATION_SECONDS - (seconds_since_epoch(now) % TEST_ROTATION_SECONDS)
    else
      midnight = now.in_time_zone(ZONE).end_of_day
      (midnight - now).ceil
    end
  end

  # Advance one day. Capped at the last position so the 14-day demo can't run
  # off the end, and idempotent within a CET day so a double-trigger is a no-op.
  #
  # `now` is a UTC timestamp; all "what day is it?" logic is done in CET so the
  # stored timestamp (UTC in the DB) and the comparison agree. Comparing bare
  # Dates against a datetime column round-trips through UTC and drifts a day —
  # this keeps both sides in the same zone instead.
  #
  # NOTE: unused while TEST_MODE is on (position is time-derived). Kept for when
  # we switch back to real midnight rotation.
  def rotate!(now: Time.current)
    today = now.in_time_zone(ZONE).to_date
    return self if last_rotated_at&.in_time_zone(ZONE)&.to_date == today
    return self if current_position >= LAST_POSITION

    update!(current_position: current_position + 1, last_rotated_at: now)
  end

  private

  def seconds_since_epoch(now)
    (now - TEST_EPOCH).to_i
  end

  def elapsed_windows(now)
    seconds_since_epoch(now) / TEST_ROTATION_SECONDS
  end
end
