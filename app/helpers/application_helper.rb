module ApplicationHelper
  # DOM id for an add-to-list panel row. `scope` namespaces the id so the same
  # list can appear in several panels on one page (e.g. one per recommendation
  # card in a chat) without colliding. No scope keeps the original id used on
  # the game show page.
  def list_panel_item_id(list, scope = nil)
    ["list-panel-item", scope.presence, list.id].compact.join("-")
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
