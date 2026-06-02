import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["swipeView", "gridView", "btnSwipe", "btnGrid", "card"]
  static values = { listId: Number, initialMode: String }

  connect() {
    if (this.initialModeValue === "grid") this.showGrid()
  }

  showSwipe() {
    this.swipeViewTarget.classList.remove("d-none")
    this.gridViewTarget.classList.add("d-none")
    this.btnSwipeTarget.classList.replace("btn-outline-primary", "btn-warning")
    this.btnGridTarget.classList.replace("btn-warning", "btn-outline-primary")
  }

  showGrid() {
    this.swipeViewTarget.classList.add("d-none")
    this.gridViewTarget.classList.remove("d-none")
    this.btnGridTarget.classList.replace("btn-outline-primary", "btn-warning")
    this.btnSwipeTarget.classList.replace("btn-warning", "btn-outline-primary")
  }

  like(event) {
    const card = event.target.closest('[data-discover-target="card"]')
    const gameId = card.dataset.gameId
    const listId = this.listIdValue

    if (!listId) return alert("Please select a list first!")

    card.style.transform = "translateX(200px) rotate(15deg)"
    card.style.opacity = "0"

    fetch(`/lists/${listId}/list_games`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.getAttribute("content")
      },
      body: JSON.stringify({ game_id: gameId })
    }).then(response => {
      if (response.ok) {
        setTimeout(() => card.remove(), 300)
      } else {
        card.style.transform = ""
        card.style.opacity = ""
      }
    })
  }

  dislike(event) {
    const card = event.target.closest('[data-discover-target="card"]')
    card.style.transform = "translateX(-200px) rotate(-15deg)"
    card.style.opacity = "0"
    setTimeout(() => card.remove(), 300)
  }
}
