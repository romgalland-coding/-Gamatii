import { Controller } from "@hotwire/stimulus"

export default class extends Controller {
  static targets = ["card", "likeLabel", "nopeLabel"]
  static values  = { listId: Number }

  connect() {
    this.startX    = 0
    this.startY    = 0
    this.currentX  = 0
    this.isDragging = false
    this.swiped    = false

    this._onMove = this._move.bind(this)
    this._onEnd  = this._end.bind(this)
  }

  dragStart(event) {
    if (this.swiped) return
    const pt = event.touches ? event.touches[0] : event
    this.startX = pt.clientX
    this.startY = pt.clientY
    this.currentX = 0
    this.isDragging = true
    this.cardTarget.style.transition = "none"

    document.addEventListener("mousemove",  this._onMove)
    document.addEventListener("mouseup",    this._onEnd)
    document.addEventListener("touchmove",  this._onMove, { passive: false })
    document.addEventListener("touchend",   this._onEnd)
  }

  _move(event) {
    if (!this.isDragging || this.swiped) return
    if (event.cancelable) event.preventDefault()

    const pt = event.touches ? event.touches[0] : event
    const dx = pt.clientX - this.startX
    const dy = pt.clientY - this.startY
    this.currentX = dx

    const rotation = dx * 0.07
    this.cardTarget.style.transform = `translateX(${dx}px) translateY(${dy * 0.25}px) rotate(${rotation}deg)`

    const progress = Math.min(Math.abs(dx) / 80, 1)
    if (dx > 20) {
      this.likeLabelTarget.style.opacity  = progress
      this.nopeLabelTarget.style.opacity  = 0
    } else if (dx < -20) {
      this.nopeLabelTarget.style.opacity  = progress
      this.likeLabelTarget.style.opacity  = 0
    } else {
      this.likeLabelTarget.style.opacity  = 0
      this.nopeLabelTarget.style.opacity  = 0
    }
  }

  _end() {
    if (!this.isDragging) return
    this.isDragging = false
    this._removeGlobalListeners()

    const THRESHOLD = 80
    if (this.currentX > THRESHOLD) {
      this._triggerSwipe("right")
    } else if (this.currentX < -THRESHOLD) {
      this._triggerSwipe("left")
    } else {
      this.cardTarget.style.transition = "transform 0.35s cubic-bezier(0.175, 0.885, 0.32, 1.275)"
      this.cardTarget.style.transform  = ""
      this.likeLabelTarget.style.opacity = 0
      this.nopeLabelTarget.style.opacity = 0
    }
  }

  swipeLeft() {
    if (!this.swiped) this._triggerSwipe("left")
  }

  swipeRight() {
    if (!this.swiped) this._triggerSwipe("right")
  }

  _triggerSwipe(direction) {
    this.swiped = true
    this._removeGlobalListeners()

    const card   = this.cardTarget
    const gameId = card.dataset.gameId

    card.style.transition = "transform 0.42s ease-in, opacity 0.42s ease-in"
    if (direction === "right") {
      card.style.transform = "translateX(130vw) rotate(30deg)"
      this.likeLabelTarget.style.opacity = 1
    } else {
      card.style.transform = "translateX(-130vw) rotate(-30deg)"
      this.nopeLabelTarget.style.opacity = 1
    }

    const token = document.querySelector('meta[name="csrf-token"]')?.content
    const body  = new URLSearchParams({
      game_id:            gameId,
      direction:          direction,
      list_id:            this.listIdValue,
      authenticity_token: token
    })

    fetch("/discover/swipe", {
      method:  "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "Accept":        "text/vnd.turbo-stream.html, text/html"
      },
      body: body.toString()
    })
      .then(r => r.text())
      .then(html => Turbo.renderStreamMessage(html))
  }

  _removeGlobalListeners() {
    document.removeEventListener("mousemove", this._onMove)
    document.removeEventListener("mouseup",   this._onEnd)
    document.removeEventListener("touchmove", this._onMove)
    document.removeEventListener("touchend",  this._onEnd)
  }

  disconnect() {
    this._removeGlobalListeners()
  }
}
