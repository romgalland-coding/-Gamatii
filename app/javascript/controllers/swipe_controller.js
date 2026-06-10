import { Controller } from "@hotwired/stimulus"

const THRESHOLD = 80 // px drag needed to commit add/skip

export default class extends Controller {
  static targets = ["card", "stack", "empty", "actions", "progress"]

  connect() {
    this.pointer = this.cardTargets.length - 1 // last in DOM = top of visual stack
    this.dragging = false
    this.startX = 0
    this.deltaX = 0
    this.skipAlreadyAdded()
    this.updateProgress()
    this.initialized = true
  }

  // Called by Stimulus whenever a card element is added to the DOM after connect()
  cardTargetConnected(card) {
    if (!this.initialized) return // ignore targets present on initial connect
    // New cards arrived (turbo stream append) — reset pointer to the new top card
    this.pointer = this.cardTargets.length - 1
    this.emptyTarget.style.display   = "none"
    this.stackTarget.style.display   = ""
    this.actionsTarget.style.display = ""
    this.skipAlreadyAdded()
    this.updateProgress()
  }

  get currentCard() {
    return this.cardTargets[this.pointer] ?? null
  }

  // ── Auto-skip already-added cards ─────────────────────────────────────

  skipAlreadyAdded() {
    while (this.currentCard?.dataset.added === "true") {
      this.currentCard.style.display = "none"
      this.pointer--
    }
    if (this.pointer < 0) this.showEmpty()
  }

  // ── Drag ──────────────────────────────────────────────────────────────

  dragstart(event) {
    if (!this.currentCard || event.currentTarget !== this.currentCard) return
    this.dragging = true
    this.startX = event.clientX
    this.currentCard.setPointerCapture(event.pointerId)
  }

  dragmove(event) {
    if (!this.dragging || !this.currentCard) return
    this.deltaX = event.clientX - this.startX

    const rotate = this.deltaX * 0.08
    this.currentCard.style.transition = "none"
    this.currentCard.style.transform = `translateX(${this.deltaX}px) rotate(${rotate}deg)`

    const ratio = Math.min(Math.abs(this.deltaX) / THRESHOLD, 1)
    this.currentCard.querySelector(".swipe-card__overlay--add").style.opacity  = this.deltaX > 0 ? ratio : 0
    this.currentCard.querySelector(".swipe-card__overlay--skip").style.opacity = this.deltaX < 0 ? ratio : 0
  }

  dragend(event) {
    if (!this.dragging) return
    this.dragging = false

    if (Math.abs(this.deltaX) < 5) {
      const modalEl = document.querySelector(`#swipeModal${this.currentCard.dataset.rawgId}`)
      if (modalEl) bootstrap.Modal.getOrCreateInstance(modalEl).show()
      this.snapBack()
      return
    }

    if (Math.abs(this.deltaX) >= THRESHOLD) {
      this.deltaX > 0 ? this.add() : this.skip()
    } else {
      this.snapBack()
    }
  }

  snapBack() {
    if (!this.currentCard) return
    this.currentCard.style.transition = "transform 0.3s ease"
    this.currentCard.style.transform = ""
    this.currentCard.querySelectorAll(".swipe-card__overlay").forEach(o => o.style.opacity = 0)
  }

  // ── Actions ───────────────────────────────────────────────────────────

  skip() {
    this.flyOff("left")
    this.advance()
  }

  add() {
    const card = this.currentCard
    if (!card) return
    this.postAdd(card)
    this.flyOff("right")
    this.advance()
  }

  flyOff(direction) {
    const card = this.currentCard
    if (!card) return
    const x = direction === "right" ? "150%" : "-150%"
    const deg = direction === "right" ? 20 : -20
    card.style.transition = "transform 0.35s ease, opacity 0.35s ease"
    card.style.transform = `translateX(${x}) rotate(${deg}deg)`
    card.style.opacity = "0"
  }

  advance() {
    this.pointer--
    this.deltaX = 0
    this.updateProgress()
    if (this.pointer < 0) {
      setTimeout(() => this.showEmpty(), 400) // wait for fly-off animation
    }
  }

  // ── Server ────────────────────────────────────────────────────────────

  async postAdd(card) {
    const url = card.dataset.addUrl
    const params = JSON.parse(card.dataset.addParams)
    const body = new URLSearchParams({
      ...params,
      authenticity_token: document.querySelector('meta[name="csrf-token"]').content
    })

    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Accept": "text/vnd.turbo-stream.html",
        "Content-Type": "application/x-www-form-urlencoded"
      },
      body
    })

    if (response.ok) {
      const html = await response.text()
      Turbo.renderStreamMessage(html)
    }
  }

  // ── UI state ──────────────────────────────────────────────────────────

  updateProgress() {
    const total = this.cardTargets.length
    const seen  = total - 1 - this.pointer
    this.progressTarget.textContent = `${seen} / ${total}`
  }

  showEmpty() {
    this.stackTarget.style.display   = "none"
    this.actionsTarget.style.display = "none"
    this.emptyTarget.style.display   = "flex"
  }
}
