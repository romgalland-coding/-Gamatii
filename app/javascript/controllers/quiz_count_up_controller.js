// app/javascript/controllers/quiz_count_up_controller.js
import { Controller } from "@hotwired/stimulus"

// Animates the score number from `from` to `to` on connect. The turbo_stream
// re-renders the score line on each correct guess, so connect() runs again and
// the count-up replays from the previous total. The rAF loop self-terminates
// when it reaches the target, and disconnect() cancels any in-flight frame.
export default class extends Controller {
  static targets = ["number"]
  static values = { from: Number, to: Number }

  connect() {
    const from = this.fromValue
    const to = this.toValue
    if (from === to) {
      this.numberTarget.textContent = to
      return
    }

    const duration = 500
    let start = null
    const step = (ts) => {
      if (start === null) start = ts
      const progress = Math.min((ts - start) / duration, 1)
      const value = Math.round(from + (to - from) * progress)
      this.numberTarget.textContent = value
      if (progress < 1) {
        this.frame = requestAnimationFrame(step)
      }
    }
    this.frame = requestAnimationFrame(step)
  }

  disconnect() {
    if (this.frame) cancelAnimationFrame(this.frame)
  }
}
