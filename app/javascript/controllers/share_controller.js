import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="share"
export default class extends Controller {
  static values = { url: String, title: String }

  async share() {
    if (navigator.share) {
      try {
        await navigator.share({
          title: this.titleValue,
          url: this.urlValue
        })
      } catch (error) {
        if (error.name !== "AbortError") {
          console.error("Share failed:", error)
        }
      }
    } else {
      // Fallback : copier le lien dans le presse-papier
      await navigator.clipboard.writeText(this.urlValue)
      alert("Link copied to clipboard!")
    }
  }
}
