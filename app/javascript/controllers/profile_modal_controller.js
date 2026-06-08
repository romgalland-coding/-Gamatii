import { Controller } from "@hotwired/stimulus"

// Opens the followers / following popup on a user's profile.
// The count buttons pass the followers/following turbo_stream URL via
// `data-profile-modal-url-param`; we fetch it and let Turbo render the modal
// into the #user-modal container target.
export default class extends Controller {
  static targets = ["container"]

  open(event) {
    const url = event.params.url
    if (!url) return

    fetch(url, { headers: { "Accept": "text/vnd.turbo-stream.html" } })
      .then((r) => r.text())
      .then((html) => {
        Turbo.renderStreamMessage(html)
        document.body.style.overflow = "hidden"
      })
  }

  close() {
    this.containerTarget.innerHTML = ""
    document.body.style.overflow = ""
  }

  // Stop clicks inside the modal card from bubbling to the backdrop (which closes).
  stop(event) {
    event.stopPropagation()
  }
}
