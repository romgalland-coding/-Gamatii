module ApplicationHelper
  STORE_ICONS = {
    "steam"             => "fa-brands fa-steam",
    "playstation-store" => "fa-brands fa-playstation",
    "xbox-store"        => "fa-brands fa-xbox",
    "apple-appstore"    => "fa-brands fa-apple",
    "google-play"       => "fa-brands fa-google-play",
    "gog"               => "fa-solid fa-dragon",
    "nintendo"          => "fa-solid fa-gamepad",
    "epic-games"        => "fa-solid fa-bolt",
    "itch"              => "fa-solid fa-heart",
  }.freeze

  def store_icon(slug)
    STORE_ICONS[slug.to_s] || "fa-solid fa-store"
  end

  # DOM id for an add-to-list panel row. `scope` namespaces the id so the same
  # list can appear in several panels on one page (e.g. one per recommendation
  # card in a chat) without colliding. No scope keeps the original id used on
  # the game show page.
  def list_panel_item_id(list, scope = nil)
    ["list-panel-item", scope.presence, list.id].compact.join("-")
  end

  # RAWG serves on-the-fly resized variants by injecting a "resize/<width>/-/"
  # segment into the media path: a 600 KB cover becomes ~25 KB at 420px, which
  # is plenty for card-sized thumbnails. Only rewrites media.rawg.io URLs that
  # aren't already resized; anything else (uploaded photos, blanks) passes
  # through untouched. Use the full URL on the game-detail hero only.
  def rawg_thumb(url, width = 420)
    return url if url.blank?
    return url unless url.include?("media.rawg.io/media/")
    return url if url.include?("/media/resize/") || url.include?("/media/crop/")

    url.sub("/media/", "/media/resize/#{width}/-/")
  end

  # Attributes for a lazily-loaded background image. Drops in where an inline
  # `style="background-image: url(...)"` used to go: the element keeps its CSS
  # placeholder tint until the lazy_bg Stimulus controller swaps the image in as
  # it nears the viewport. Returns "" when there's no url so empty covers render
  # their plain placeholder.
  #
  #   <div class="card__cover" <%= lazy_bg(game.cover_img) %>></div>
  def lazy_bg(url)
    return "".html_safe if url.blank?

    tag.attributes('data-controller': "lazy-bg", 'data-lazy-bg-url-value': url)
  end

  # Render assistant chat replies (markdown) as safe HTML.
  def markdown(text)
    return "" if text.blank?

    renderer = Redcarpet::Render::HTML.new(
      hard_wrap: true,
      no_images: true,
      safe_links_only: true
    )
    md = Redcarpet::Markdown.new(renderer,
      no_intra_emphasis: true,
      strikethrough: true
    )
    md.render(text).html_safe
  end
end
