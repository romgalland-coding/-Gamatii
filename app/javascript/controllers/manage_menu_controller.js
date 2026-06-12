import { Controller } from "@hotwired/stimulus"

// Small "⋯" menu on the list header card holding the rare owner-admin actions
// (Edit, Delete). Opens/closes the menu and closes on outside click. The menu
// items themselves delegate to the page-level list-edit / confirm-dialog
// controllers, so this only manages its own open state.
export default class extends Controller {
  static targets = ["menu"]

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
    this.menuTarget.classList.toggle("is-open")
  }

  close() {
    this.menuTarget.classList.remove("is-open")
  }
}
