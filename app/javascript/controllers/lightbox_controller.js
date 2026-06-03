import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "image", "counter"]
  static values = { images: Array, index: Number }

  open({ params: { index } }) {
    this.indexValue = index
    this.overlayTarget.classList.add("is-open")
    document.body.style.overflow = "hidden"
    this._render()
  }

  close() {
    this.overlayTarget.classList.remove("is-open")
    document.body.style.overflow = ""
  }

  prev() {
    this.indexValue = (this.indexValue - 1 + this.imagesValue.length) % this.imagesValue.length
    this._render()
  }

  next() {
    this.indexValue = (this.indexValue + 1) % this.imagesValue.length
    this._render()
  }

  handleKey({ key }) {
    if (!this.overlayTarget.classList.contains("is-open")) return
    if (key === "Escape") this.close()
    if (key === "ArrowLeft") this.prev()
    if (key === "ArrowRight") this.next()
  }

  _render() {
    this.imageTarget.style.backgroundImage = `url('${this.imagesValue[this.indexValue]}')`
    if (this.imagesValue.length > 1) {
      this.counterTarget.textContent = `${this.indexValue + 1} / ${this.imagesValue.length}`
    }
  }
}
