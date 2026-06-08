import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results"]

  connect() {
    this.page = 1
    this.query = ""
  }

  search() {
    clearTimeout(this.timeout)
    this.query = this.inputTarget.value.trim()

    if (this.query.length < 2) {
      this.resultsTarget.innerHTML = ""
      document.getElementById("list_search_more").innerHTML = ""
      return
    }

    this.page = 1
    this.timeout = setTimeout(() => this.#fetch(), 300)
  }

  loadMore() {
    this.page++
    this.#fetch()
  }

  #fetch() {
    fetch(`/lists/search?query=${encodeURIComponent(this.query)}&page=${this.page}`, {
      headers: { "Accept": "text/vnd.turbo-stream.html" }
    })
      .then(r => r.text())
      .then(html => Turbo.renderStreamMessage(html))
  }
}
