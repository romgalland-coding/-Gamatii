import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "tags", "inputs", "checkbox"]
  static values  = { name: String }

  selected = {}

  connect() {
    this.checkboxTargets.forEach(cb => {
      if (cb.checked) this.selected[cb.value] = cb.dataset.name
    })
    this._render()
  }

  open(e) {
    e.preventDefault()
    this.panelTarget.classList.add("is-open")
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
    this.tagsTarget.innerHTML = Object.entries(this.selected).map(([id, name]) => `
      <span class="filter-chip">
        ${name}
        <button type="button"
                class="filter-chip__remove"
                data-action="click->multi-select#remove"
                data-multi-select-id-param="${id}">×</button>
      </span>
    `).join("")

    this.inputsTarget.innerHTML = Object.keys(this.selected)
      .map(id => `<input type="hidden" name="${this.nameValue}" value="${id}">`)
      .join("")
  }
}
