import { Controller } from "@hotwired/stimulus"

// Lazy-loads a CSS background-image. The element keeps its placeholder tint
// (set in CSS) until it scrolls near the viewport, at which point the real
// image URL is applied. Native loading="lazy" only covers <img> tags, so this
// fills the gap for our background-image covers.
//
//   <div data-controller="lazy-bg" data-lazy-bg-url-value="https://…"></div>
//
// `rootMargin` starts the fetch 200px before the element enters view so the
// image is usually ready by the time it's visible.
export default class extends Controller {
  static values = { url: String }

  connect() {
    if (!this.urlValue) return

    // No IntersectionObserver (very old browsers) → just load immediately.
    if (!("IntersectionObserver" in window)) {
      this.load()
      return
    }

    this.observer = new IntersectionObserver((entries) => {
      if (entries.some((e) => e.isIntersecting)) this.load()
    }, { rootMargin: "200px" })
    this.observer.observe(this.element)
  }

  disconnect() {
    this.observer?.disconnect()
  }

  load() {
    this.element.style.backgroundImage = `url('${this.urlValue}')`
    this.observer?.disconnect()
  }
}
