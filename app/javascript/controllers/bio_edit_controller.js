import { Controller } from "@hotwired/stimulus"

// Toggles the profile bio between its display/empty state and an inline edit
// form. The form submits via Turbo and the server replaces #profile-bio, so on
// a successful save this controller's element is swapped out entirely.
export default class extends Controller {
  static targets = ["display", "form", "input"]

  edit() {
    this.displayTarget.hidden = true
    this.formTarget.hidden = false
    if (this.hasInputTarget) {
      this.inputTarget.focus()
      // Put the cursor at the end of any existing text.
      const len = this.inputTarget.value.length
      this.inputTarget.setSelectionRange(len, len)
    }
  }

  cancel() {
    this.formTarget.hidden = true
    this.displayTarget.hidden = false
  }
}
