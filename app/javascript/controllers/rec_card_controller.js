import { Controller } from "@hotwired/stimulus"

// Drives a recommendation card's three actions. Adding to existing lists is
// handled by the reused add-to-list panel (each row is its own request); this
// controller handles "new list", "skip", and the Done button — and in every
// case chains the next recommendation once the choice is recorded.
export default class extends Controller {
  static targets = ["newListForm", "nextRecForm"]

  // Reveal the inline "create a new list" form.
  openNewList(event) {
    event.preventDefault()
    this.newListFormTarget.classList.remove("d-none")
  }

  // Create the new list (+ add this game) via fetch, then ask for the next game.
  async submitNewList(event) {
    event.preventDefault()
    const form = this.newListFormTarget
    if (!form.reportValidity()) return

    const formData = new FormData(form)
    const csrf = document.querySelector('meta[name="csrf-token"]')?.content
    if (csrf) formData.set("authenticity_token", csrf)

    const response = await fetch(form.action, { method: "POST", body: formData })
    if (!response.ok) return

    this.#markActed()
    this.#requestNext("ACTION:ADDED — recommend a different game now.")
  }

  // Done in the existing-lists panel: rows were already toggled, so just close
  // the card and move on.
  confirmAdd(event) {
    event.preventDefault()
    this.#markActed()
    this.#requestNext("ACTION:ADDED — recommend a different game now.")
  }

  skip(event) {
    event.preventDefault()
    this.#markActed()
    this.#requestNext("ACTION:SKIPPED — recommend a different game now.")
  }

  // Lock the card and hide its controls once a choice has been made.
  #markActed() {
    this.element.classList.add("rec-card--acted")
    this.element.style.pointerEvents = "none"
    const panel = this.element.querySelector(".add-list-panel")
    panel?.classList.remove("is-open")
  }

  #requestNext(message) {
    const input = this.nextRecFormTarget.querySelector("input[name='message[content]']")
    if (input) input.value = message
    this.nextRecFormTarget.requestSubmit()
  }
}
