import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["short", "full", "btn"]

  toggle() {
    const collapsed = this.fullTarget.classList.toggle("d-none")
    this.shortTarget.classList.toggle("d-none")
    this.btnTarget.textContent = collapsed ? "Read more" : "Read less"
  }
}
