// app/javascript/controllers/quiz_timer_controller.js
import { Controller } from "@hotwired/stimulus"

// Counts down to the next quiz rotation and reloads the page when it hits zero,
// so the next quiz appears. Because this controller lives on an element inside
// the quiz page, Stimulus tears it down (disconnect) the moment you navigate
// away — the interval is cleared there, so the reload can never fire on another
// page (e.g. while you're building a list).
export default class extends Controller {
  static values = { seconds: Number, endedUrl: String }

  connect() {
    this.remaining = this.secondsValue
    this.render()
    // One interval per controller instance; cleared in disconnect() and again
    // at zero, so it never double-fires or outlives the element.
    this.interval = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    this.stop()
  }

  tick() {
    this.remaining -= 1
    if (this.remaining <= 0) {
      this.stop()
      // On the guess tab, reload to the just-ended quiz's results (?ended=<id>);
      // elsewhere just reload to the new window.
      if (this.hasEndedUrlValue) {
        window.location.href = this.endedUrlValue
      } else {
        window.location.reload()
      }
      return
    }
    this.render()
  }

  stop() {
    if (this.interval) {
      clearInterval(this.interval)
      this.interval = null
    }
  }

  render() {
    const total = Math.max(this.remaining, 0)
    const h = Math.floor(total / 3600)
    const m = Math.floor((total % 3600) / 60)
    const s = total % 60
    const pad = (n) => String(n).padStart(2, "0")
    // Show hours only when the window is long (real midnight mode); the 30s test
    // window stays as MM:SS.
    this.element.textContent = h > 0 ? `${pad(h)}:${pad(m)}:${pad(s)}` : `${pad(m)}:${pad(s)}`
  }
}
