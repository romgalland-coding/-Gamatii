import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "tags", "inputs", "checkbox", "label"]
  static values  = { name: String, placeholder: String }

  selected = {}

  connect() {
    this.checkboxTargets.forEach(cb => {
      if (cb.checked) this.selected[cb.value] = cb.dataset.name
    })
    this._render()
    // Close the inline dropdown when clicking anywhere outside it.
    this._onOutside = (e) => { if (!this.element.contains(e.target)) this.close() }
    document.addEventListener("click", this._onOutside)
  }

  disconnect() {
    document.removeEventListener("click", this._onOutside)
  }

  // Toggle the inline dropdown menu open/closed (used by the filter-dropdown
  // trigger). The fullscreen-panel callers still call open/close directly.
  open(e) {
    e.preventDefault()
    e.stopPropagation()
    this.panelTarget.classList.toggle("is-open")
  }

  close() {
    this.panelTarget.classList.remove("is-open")
  }

  toggle(e) {
    const { value, dataset, checked } = e.target
    if (checked) {
      this.selected[value] = dataset.name
    } else {
      delete this.selected[value]
    }
    this._render()
  }

  remove(e) {
    const id = e.params.id
    delete this.selected[id]
    const cb = this.checkboxTargets.find(c => c.value === String(id))
    if (cb) cb.checked = false
    this._render()
  }

  _render() {
    // Chips (legacy callers that render selection as removable tags).
    if (this.hasTagsTarget) {
      this.tagsTarget.innerHTML = Object.entries(this.selected).map(([id, name]) => `
        <span class="filter-chip">
          ${name}
          <button type="button"
                  class="filter-chip__remove"
                  data-action="click->multi-select#remove"
                  data-multi-select-id-param="${id}">×</button>
        </span>
      `).join("")
    }

    // Dropdown trigger label (filter-dropdown style): placeholder when empty,
    // the single name when one is picked, otherwise an "N selected" summary.
    if (this.hasLabelTarget) {
      const names = Object.values(this.selected)
      this.labelTarget.textContent =
        names.length === 0 ? this.placeholderValue
        : names.length === 1 ? names[0]
        : `${names.length} selected`
    }

    this.inputsTarget.innerHTML = Object.keys(this.selected)
      .map(id => `<input type="hidden" name="${this.nameValue}" value="${id}">`)
      .join("")
  }
}
