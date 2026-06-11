import { Controller } from "@hotwired/stimulus"

// Owner-only avatar picker. Clicking the avatar opens a popover with an emoji
// grid and a color row; choosing either sets the matching hidden field and
// submits the form (Turbo), so the avatar region re-renders. The form always
// carries both emoji + color so a color-only change still round-trips. Closes
// on outside click.
export default class extends Controller {
  static targets = ["popover", "emojiField", "colorField", "form"]

  connect() {
    this._onOutside = (e) => { if (!this.element.contains(e.target)) this.close() }
    document.addEventListener("click", this._onOutside)
  }

  disconnect() {
    document.removeEventListener("click", this._onOutside)
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    this.popoverTarget.classList.toggle("is-open")
  }

  close() {
    this.popoverTarget.classList.remove("is-open")
  }

  // An emoji button was clicked: stash it and submit the form.
  select(event) {
    this.emojiFieldTarget.value = event.currentTarget.dataset.emoji
    this.close()
    this.formTarget.requestSubmit()
  }

  // A color swatch was clicked: stash it and submit the form.
  selectColor(event) {
    this.colorFieldTarget.value = event.currentTarget.dataset.color
    this.close()
    this.formTarget.requestSubmit()
  }
}
