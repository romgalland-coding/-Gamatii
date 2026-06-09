import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["extra", "btn"]

  show() {
    this.extraTarget.classList.remove("d-none")
    this.btnTarget.classList.add("d-none")
  }
}
