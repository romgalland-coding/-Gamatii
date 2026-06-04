// app/javascript/controllers/quiz_score_controller.js
import { Controller } from "@hotwired/stimulus"

// The daily-quiz score screen: auto-opens once all guesses are used, can be
// dismissed (X) and re-opened ("View results"), and shares the score via the
// Web Share API (clipboard fallback). No timers/listeners are held, but we
// release the body scroll-lock on disconnect so a Turbo navigation while the
// overlay is open never leaves the page un-scrollable.
export default class extends Controller {
  static targets = ["overlay"]
  static values = { auto: Boolean, shareText: String }

  connect() {
    if (this.autoValue) this.open()
  }

  disconnect() {
    document.body.style.overflow = ""
    clearTimeout(this.copiedTimeout)
  }

  open() {
    this.overlayTarget.classList.add("is-open")
    document.body.style.overflow = "hidden"
  }

  close() {
    this.overlayTarget.classList.remove("is-open")
    document.body.style.overflow = ""
  }

  async share() {
    const text = this.shareTextValue
    if (navigator.share) {
      try {
        await navigator.share({ text })
      } catch (e) {
        // User cancelled the share sheet — nothing to do.
      }
    } else if (navigator.clipboard) {
      await navigator.clipboard.writeText(text)
      this.flashCopied()
    }
  }

  flashCopied() {
    const btn = this.element.querySelector(".quiz-score-share")
    if (!btn) return
    const original = btn.innerHTML
    btn.innerHTML = '<i class="fa-solid fa-check"></i> Copied!'
    this.copiedTimeout = setTimeout(() => { btn.innerHTML = original }, 1500)
  }
}
