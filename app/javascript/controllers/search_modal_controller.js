// app/javascript/controllers/search_modal_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "input", "results"]

  open() {
    this.modalTarget.classList.add("is-open")
    document.body.style.overflow = "hidden"
    this.inputTarget.focus()
  }

  close() {
    this.modalTarget.classList.remove("is-open")
    document.body.style.overflow = ""
    this.resultsTarget.innerHTML = ""
    this.inputTarget.value = ""
  }

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      const query = this.inputTarget.value
      if (query.length < 2) return

      const listId = this.element.dataset.listId

      fetch(`/lists/search_games?query=${encodeURIComponent(query)}&list_id=${listId}`, {
        headers: { "Accept": "text/vnd.turbo-stream.html" }
      })
      .then(r => r.text())
      .then(html => Turbo.renderStreamMessage(html))
    }, 0)
  }
}
