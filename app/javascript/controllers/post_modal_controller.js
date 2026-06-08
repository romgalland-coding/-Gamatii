import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  open() {
    this.modalTarget.classList.add("is-open")
    document.body.style.overflow = "hidden"
  }

  close() {
    this.modalTarget.classList.remove("is-open")
    document.body.style.overflow = ""
  }

  handleSubmitEnd(event) {
    if (event.detail.success) this.close()
  }
}
