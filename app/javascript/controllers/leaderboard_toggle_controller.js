import { Controller } from "@hotwired/stimulus"

// Toggles the score-screen leaderboard between the "global" and "follows"
// views. Both views (and both rank-meta strings) are rendered server-side; this
// just flips which one is visible and which tab reads as active. Defaults to
// "global" — the markup ships with the global view shown.
export default class extends Controller {
  static targets = ["tab", "view", "meta"]

  switch(event) {
    this.show(event.currentTarget.dataset.view)
  }

  show(view) {
    this.tabTargets.forEach(t =>
      t.classList.toggle("quiz-leaderboard-toggle__btn--active", t.dataset.view === view)
    )
    this.viewTargets.forEach(v => { v.hidden = v.dataset.view !== view })
    this.metaTargets.forEach(m => { m.hidden = m.dataset.view !== view })
  }
}
