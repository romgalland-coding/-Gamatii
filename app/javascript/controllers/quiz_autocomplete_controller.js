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
  }

  search(event) {
    clearTimeout(this.timeout)
    const query = event.target.value

    // Erasing the box (or fewer than 2 chars) clears the dropdown instead of
    // leaving stale results open.
    if (query.length < 2) {
      this.clearResults()
      return
    }

    this.timeout = setTimeout(() => {
      fetch(`${this.urlValue}?query=${encodeURIComponent(query)}`, {
        headers: { "Accept": "text/vnd.turbo-stream.html" }
      })
        .then(r => r.text())
        .then(html => Turbo.renderStreamMessage(html))
    }, 200)
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
