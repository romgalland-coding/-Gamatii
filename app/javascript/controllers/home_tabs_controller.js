import { Controller } from "@hotwired/stimulus"

// Three-tab switcher on the home page (Feed / Popular Games / Popular Lists).
// All three panels are rendered server-side in one request; this just flips
// which panel is visible and which tab reads as active. Defaults to "feed".
export default class extends Controller {
  static targets = ["tab", "panel"]

  switch(event) {
    this.show(event.currentTarget.dataset.tab)
  }

  show(name) {
    this.tabTargets.forEach(t =>
      t.classList.toggle("home-tab--active", t.dataset.tab === name)
    )
    this.panelTargets.forEach(p => { p.hidden = p.dataset.tab !== name })
  }
}
