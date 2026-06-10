namespace :games do
  desc "Backfill screenshots and rawg_id for games that are missing them"
  task backfill_screenshots: :environment do
    api_key = ENV.fetch("RAWG_API_KEY") { ENV.fetch("RAW_API_KEY", "") }
    base_url = "https://api.rawg.io/api"

    games = Game.where("screenshots = '{}' OR screenshots IS NULL OR rawg_id IS NULL")
    puts "Backfilling #{games.count} games…"

    games.each do |game|
      begin
        response = HTTParty.get("#{base_url}/games", query: {
          key: api_key,
          search: game.title,
          page_size: 1
        })
        result = response["results"]&.first
        next puts "  [skip] #{game.title}: no RAWG result" unless result

        shots = (result["short_screenshots"] || []).filter_map { |s| s["image"] }[1..3].to_a
        attrs = { screenshots: shots }
        attrs[:rawg_id] = result["id"] unless Game.where.not(id: game.id).exists?(rawg_id: result["id"])
        game.update!(attrs)
        print "."
      rescue StandardError => e
        puts "\n  [error] #{game.title}: #{e.message}"
      end
      sleep 0.25
    end

    puts "\nDone."
  end

  desc "Backfill store_links (buy links) for games that don't have them yet"
  task backfill_store_links: :environment do
    service = RawgService.new
    games = Game.where.not(rawg_id: nil).select { |g| g.store_links.blank? }
    puts "Backfilling store links for #{games.size} games…"

    games.each do |game|
      links = service.stores(game.rawg_id)
      game.update_columns(store_links: links)
      print links.any? ? "." : "○" # ○ = game has no stores on RAWG
      sleep 0.25
    end

    puts "\nDone."
  end
end
