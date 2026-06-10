import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]
  static values = {
    url:     String,
    page:    { type: Number, default: 2 },
    maxPage: { type: Number, default: 5 }
  }

  load(event) {
    event.preventDefault()
    if (this.pageValue > this.maxPageValue) return

    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set("page", this.pageValue)

    fetch(url.toString(), { headers: { "Accept": "text/vnd.turbo-stream.html" } })
      .then(r => r.text())
      .then(html => Turbo.renderStreamMessage(html))

    this.pageValue++
    if (this.pageValue > this.maxPageValue) {
      this.buttonTargets.forEach(btn => { btn.style.display = "none" })
    }
  }
}
