// app/javascript/controllers/quiz_score_controller.js
import { Controller } from "@hotwired/stimulus"

// The daily-quiz score screen: auto-opens once all guesses are used, can be
// dismissed (X) and re-opened ("View results"), and shares the score via the
// Web Share API (clipboard fallback). No timers/listeners are held, but we
// release the body scroll-lock on disconnect so a Turbo navigation while the
// overlay is open never leaves the page un-scrollable.
//
// Auto-open fires only the FIRST time per quiz: once the user has seen and
// dismissed it, a `keyValue`-scoped localStorage flag suppresses re-popping on
// later page loads. "View results" still opens it explicitly any time. A new
// day's quiz uses a different key, so it pops once again.
export default class extends Controller {
  static targets = ["overlay"]
  static values = { auto: Boolean, key: String, shareText: String }

  connect() {
    if (this.autoValue && !this.seen) this.open()
  }

  get seen() {
    if (!this.keyValue) return false
    try {
      return localStorage.getItem(this.keyValue) === "1"
    } catch (e) {
      return false
    }
  }

  markSeen() {
    if (!this.keyValue) return
    try {
      localStorage.setItem(this.keyValue, "1")
    } catch (e) {
      // localStorage unavailable (private mode / disabled) — auto-open just
      // falls back to per-load behaviour, which is acceptable.
    }
  }

  disconnect() {
    document.body.style.overflow = ""
    clearTimeout(this.copiedTimeout)
  }

  open() {
    this.overlayTarget.classList.add("is-open")
    document.body.style.overflow = "hidden"
    this.markSeen()
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
