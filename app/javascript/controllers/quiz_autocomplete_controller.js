// app/javascript/controllers/quiz_autocomplete_controller.js
import { Controller } from "@hotwired/stimulus"

// Searches RAWG as you type and renders the matching games into the results
// area. Each result carries its own submit form, so clicking one adds it to
// the quiz — same pattern as the list search modal.
export default class extends Controller {
  static targets = ["input", "results"]
  static values = { url: String }

  disconnect() {
    clearTimeout(this.timeout)
    this.abortInFlight()
  }

  search(event) {
    clearTimeout(this.timeout)
    const query = event.target.value

    // Erasing the box (or fewer than 2 chars) clears the dropdown. We also abort
    // any in-flight request so a late response can't re-populate the cleared box.
    if (query.length < 2) {
      this.abortInFlight()
      this.clearResults()
      return
    }

    this.timeout = setTimeout(() => {
      this.abortInFlight()
      this.controller = new AbortController()
      fetch(`${this.urlValue}?query=${encodeURIComponent(query)}`, {
        headers: { "Accept": "text/vnd.turbo-stream.html" },
        signal: this.controller.signal
      })
        .then(r => r.text())
        .then(html => Turbo.renderStreamMessage(html))
        .catch(e => { if (e.name !== "AbortError") throw e })
    }, 200)
  }

  abortInFlight() {
    if (this.controller) {
      this.controller.abort()
      this.controller = null
    }
  }

  // After a guess submits, empty the search box and close the dropdown.
  reset() {
    this.inputTarget.value = ""
    this.clearResults()
  }

  clearResults() {
    if (this.hasResultsTarget) this.resultsTarget.innerHTML = ""
  }
}
