module GamesHelper
  # Map RAWG's verbose platform names to the short labels used in the UI
  # ("PlayStation 5" → "PS5"). Anything unmatched falls back to the original
  # name so we never hide a platform we don't have a rule for.
  PLATFORM_SHORT_LABELS = {
    /playstation\s*5/i => "PS5",
    /playstation\s*4/i => "PS4",
    /playstation\s*3/i => "PS3",
    /playstation/i => "PS",
    /xbox\s*series/i => "Xbox",
    /xbox\s*one/i => "Xbox",
    /xbox/i => "Xbox",
    /nintendo\s*switch/i => "Switch",
    /\bpc\b/i => "PC",
    /macos|\bmac\b|os x/i => "Mac",
    /linux/i => "Linux",
    /\bios\b|iphone|ipad/i => "iOS",
    /android/i => "Android"
  }.freeze

  # Turn a Game's platform list into a compact, de-duplicated label such as
  # "Switch / PC / Xbox". Accepts the array column directly.
  def short_platforms(platforms, limit: 3)
    labels = Array(platforms).map { |name| short_platform_label(name) }.uniq
    labels.first(limit).join(" / ")
  end

  # Convert a 0–100 Metascore into the 0–10 decimal shown on the rating badge.
  # Returns nil when the game has no rating so the badge can be hidden.
  def display_rating(rating)
    return if rating.blank?

    format("%.1f", rating.to_f / 10)
  end

  private

  def short_platform_label(name)
    match = PLATFORM_SHORT_LABELS.find { |pattern, _| name =~ pattern }
    match ? match.last : name
  end
end
