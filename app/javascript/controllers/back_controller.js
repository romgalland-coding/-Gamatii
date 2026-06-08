import { Controller } from "@hotwired/stimulus"

// Makes a link behave like the browser's Back button: return to the previous
// page in history instead of a fixed destination. Falls back to the element's
// href when there's no history to go back to (e.g. the page was opened directly).
//
// Note: we intentionally don't gate on document.referrer — under Turbo Drive,
// in-app navigations are pushState visits that never update referrer, so it's
// stale/empty even when there's a perfectly good history entry to return to.
export default class extends Controller {
  back(event) {
    if (window.history.length > 1) {
      event.preventDefault()
      window.history.back()
    }
    // else: let the href fallback navigate normally.
  }
}
