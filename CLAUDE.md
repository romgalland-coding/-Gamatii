# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Gamatii is a Rails 8.1 app (generated from the Le Wagon template) where users can manage game lists and play quizzes about games. It uses PostgreSQL, Devise for auth, Bootstrap 5 + SimpleForm for UI, and Hotwire (Turbo + Stimulus) for interactivity.

## Commands

```bash
bin/dev              # Start dev server (Puma + asset watchers)
bin/rails db:migrate # Run migrations
bin/rails db:seed    # Seed database
bin/rails test       # Run all tests
bin/rails test test/models/game_test.rb  # Run a single test file
bin/rubocop          # Lint (rubocop-rails-omakase)
bin/brakeman         # Security static analysis
bin/bundler-audit    # Gem vulnerability audit
bin/ci               # Run the full CI suite
```

## Architecture

### Data Model

- **User** — authenticated via Devise; has `gamer_tag`, `platform[]` (array of strings, allowed values in `User::PLATFORMS`); owns many `List`s and `QuizGame`s
- **Game** — central catalog entity populated from the RAWG API (no in-app creation); fields include `title`, `genre`, `platforms` (plain string, not array), `rating`, `cover_img`, `in_game_img`, `game_mode[]` (array), `developer`, `publisher`, `release_date`
- **List** — user-curated game list (`name`, `list_type` string array limited to `List::LIST_TYPES = ["wishlist", "played", "custom"]`, `votes_count`); join to games via `ListGame`
- **ListGame** — join table between `List` and `Game`
- **Quiz** — a named quiz (`name`); join to games via `QuizGame`
- **QuizGame** — join table between `Quiz`, `Game`, and `User` (tracks which user answered which game in a quiz)

### Key Relationships

```
User → has_many Lists → has_many Games (through ListGames)
User → has_many QuizGames → belongs_to Quiz & Game
Game → has_many Lists (through ListGames)
Game → has_many Quizzes (through QuizGames)
```

### Authentication

`ApplicationController` has a global `before_action :authenticate_user!` — every route requires login by default. Controllers that need public access must explicitly skip it (e.g. `ListsController` allows `index` and `show` without auth). Devise extra params (`gamer_tag`, `platform[]`) are permitted in `configure_permitted_parameters`.

### Routes

```
/              → pages#home
/games/:id     → games#show
/lists         → full CRUD
/lists/:list_id/list_games    → create only (add game to list)
/list_games/:id               → destroy only (remove game from list)
/quizzes/:id                  → show only
/quizzes/:quiz_id/quiz_games  → create only (answer/add game to quiz)
/quiz_games/:id               → destroy only
```

### External API: RAWG

`app/services/rawg_service.rb` wraps the RAWG.io game database API via HTTParty. Requires `RAWG_API_KEY` in `.env`. Key methods:

- `search(query)` — full-text search, returns up to 5 results
- `find(id)` — fetch a single game by RAWG ID
- `by_genre(genre_name, exclude_rawg_id:, devices: [])` — fetch top-rated games by genre, optionally filtered by platform, excluding a specific game

Game records in the DB are imported from RAWG; the app has no UI for creating games.

### Frontend Stack

- **Importmap** (no Node/Webpack) — JS managed via `config/importmap.rb`
- **Bootstrap 5** + **Font Awesome 6** via gems
- **SimpleForm** configured with Bootstrap integration (`config/initializers/simple_form_bootstrap.rb`)
- **Hotwire** (Turbo + Stimulus) for reactive UI without full-page reloads
- **SCSS** organized into `config/` (Bootstrap variable overrides, colors, fonts), `components/` (reusable UI pieces), and `pages/` (page-specific styles); all imported in `application.scss`
- Stimulus controllers are auto-loaded from `app/javascript/controllers/` via `eagerLoadControllersFrom`

### Infrastructure

- **Solid Cache / Solid Queue / Solid Cable** — all DB-backed (no Redis required)
- **Kamal** — deployment config in `config/deploy.yml`
- **Dotenv** — `.env` for local secrets (dev/test only)
