// app/javascript/controllers/quiz_shake_controller.js
import { Controller } from "@hotwired/stimulus"

// Shakes a target element (the quiz search input) once when this controller
// connects — used for wrong-guess feedback. The turbo_stream re-renders the
// feedback region on each miss, so connect() runs again and the shake repeats.
// The animationend listener is { once: true } so it cleans itself up.
export default class extends Controller {
  static values = { targetSelector: String }

  connect() {
    const input = document.querySelector(this.targetSelectorValue)
    if (!input) return

    input.classList.remove("shake")
    // Force reflow so re-adding the class restarts the animation on repeats.
    void input.offsetWidth
    input.classList.add("shake")
    input.addEventListener(
      "animationend",
      () => input.classList.remove("shake"),
      { once: true }
    )
  }
}
