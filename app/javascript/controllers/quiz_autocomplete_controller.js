// app/javascript/controllers/quiz_autocomplete_controller.js
import { Controller } from "@hotwired/stimulus"

// Searches RAWG as you type and renders the matching games into the results
// area. Each result carries its own submit form, so clicking one adds it to
// the quiz — same pattern as the list search modal.
export default class extends Controller {
  static values = { url: String }

  search(event) {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      const query = event.target.value
      if (query.length < 2) return

      fetch(`${this.urlValue}?query=${encodeURIComponent(query)}`, {
        headers: { "Accept": "text/vnd.turbo-stream.html" }
      })
        .then(r => r.text())
        .then(html => Turbo.renderStreamMessage(html))
    }, 200)
  }
}
