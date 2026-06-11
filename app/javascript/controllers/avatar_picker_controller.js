import { Controller } from "@hotwired/stimulus"

// Owner-only avatar emoji picker. Clicking the avatar opens a popover grid of
// emojis; choosing one sets the hidden field and submits the form (Turbo), so
// the avatar region re-renders with the new emoji. Closes on outside click.
export default class extends Controller {
  static targets = ["popover", "field", "form"]

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
    this.fieldTarget.value = event.currentTarget.dataset.emoji
    this.close()
    this.formTarget.requestSubmit()
  }
}
