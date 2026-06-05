// app/javascript/controllers/quiz_howto_controller.js
import { Controller } from "@hotwired/stimulus"

// The "How to play" rules modal. Opens from the header button; closes on X,
// "Got it", or a backdrop click. Releases the body scroll-lock on disconnect so
// a Turbo navigation while it's open never leaves the page un-scrollable.
export default class extends Controller {
  static targets = ["overlay"]

  disconnect() {
    document.body.style.overflow = ""
  }

  open() {
    this.overlayTarget.classList.add("is-open")
    document.body.style.overflow = "hidden"
  }

  close() {
    this.overlayTarget.classList.remove("is-open")
    document.body.style.overflow = ""
  }

  // Close only when the click is on the backdrop itself, not the card inside it.
  backdrop(event) {
    if (event.target === this.overlayTarget) this.close()
  }
}
