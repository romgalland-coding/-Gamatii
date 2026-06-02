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

- **User** — authenticated via Devise; has `gamer_tag`, `platform[]` (array); owns many `List`s and `QuizGame`s
- **Game** — central catalog entity with metadata (title, genre, platforms, rating, cover/in-game images, game_mode[] array); read-only from the app (no create/update routes)
- **List** — user-curated game list (`name`, `list_type[]` array, `votes_count`); join to games via `ListGame`
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

### Frontend Stack

- **Importmap** (no Node/Webpack) — JS managed via `config/importmap.rb`
- **Bootstrap 5** + **Font Awesome 6** via gems
- **SimpleForm** configured with Bootstrap integration (`config/initializers/simple_form_bootstrap.rb`)
- **Hotwire** (Turbo + Stimulus) for reactive UI without full-page reloads

### Infrastructure

- **Solid Cache / Solid Queue / Solid Cable** — all DB-backed (no Redis required)
- **Kamal** — deployment config in `config/deploy.yml`
- **Dotenv** — `.env` for local secrets (dev/test only)
