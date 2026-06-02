import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, title: String }

  async share() {
    if (!navigator.share) {
      await navigator.clipboard.writeText(this.urlValue)
      alert("Link copied to clipboard!")
      return
    }

    try {
      await navigator.share({ title: this.titleValue, url: this.urlValue })
    } catch (err) {
      if (err.name !== "AbortError") console.error(err)
    }
  }
}
