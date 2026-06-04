class DailyRotationJob < ApplicationJob
  queue_as :default

  # Advances the quiz rotation by one day. Scheduled just after midnight CET via
  # config/recurring.yml. QuizSchedule#rotate! does all date logic in CET, is
  # idempotent per CET day, and is capped at the last position — so the exact
  # firing time and any re-runs are harmless.
  def perform
    QuizSchedule.instance.rotate!(now: Time.current)
  end
end
