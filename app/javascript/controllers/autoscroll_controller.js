import { Controller } from "@hotwired/stimulus"

// Keeps the chat pinned to the latest message as bubbles stream in.
// Connects to data-controller="autoscroll"
export default class extends Controller {
  connect() {
    this.scrollToBottom()

    this.observer = new MutationObserver(() => this.scrollToBottom())
    this.observer.observe(this.element, { childList: true, subtree: true })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  scrollToBottom() {
    this.element.scrollTop = this.element.scrollHeight
  }
}
