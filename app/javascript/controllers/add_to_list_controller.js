import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  open(e) {
    e.preventDefault()
    this.panelTarget.classList.add("is-open")
  }

  close() {
    this.panelTarget.classList.remove("is-open")
  }
}
