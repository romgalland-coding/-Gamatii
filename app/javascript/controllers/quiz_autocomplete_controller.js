// app/javascript/controllers/quiz_autocomplete_controller.js
import { Controller } from "@hotwired/stimulus"

// Autocompletes the daily-quiz game field from games matching the quiz's
// theme. Picking a suggestion fills the input and submits the quiz form.
export default class extends Controller {
  static targets = ["input", "form"]
  static values = { url: String }

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      const query = this.inputTarget.value
      if (query.length < 2) return

      fetch(`${this.urlValue}?query=${encodeURIComponent(query)}`, {
        headers: { "Accept": "text/vnd.turbo-stream.html" }
      })
        .then(r => r.text())
        .then(html => Turbo.renderStreamMessage(html))
    }, 200)
  }

  pick(event) {
    this.inputTarget.value = event.currentTarget.dataset.gameTitle
    this.formTarget.requestSubmit()
  }
}
