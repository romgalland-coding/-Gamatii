import { Controller } from "@hotwired/stimulus"

// Range slider for the new-list form. Mirrors the filter panel's slider look
// (— when at the minimum, "value+" otherwise, plus the filled track) but writes
// the picked value into hidden form fields so it submits with the form.
//
//   kind="rating"  → writes one field `rating` on RAWG's 0–100 scale (value×10)
//   kind="year"    → writes `from` = "<year>-01-01" and `to` = "<thisYear>-12-31"
//
// At the minimum the fields are cleared so an untouched slider sends nothing.
export default class extends Controller {
  static targets = ["input", "value", "field"]
  static values  = { kind: String }

  connect() {
    this.update()
  }

  update() {
    const slider = this.inputTarget
    const value  = parseFloat(slider.value)
    const atMin   = value <= parseFloat(slider.min)

    // Label: "—" at minimum, otherwise "9.0+" (rating) or "2015+" (year).
    this.valueTarget.textContent = atMin
      ? "—"
      : this.kindValue === "rating" ? `${value.toFixed(1)}+` : `${value}+`
    this.valueTarget.classList.toggle("is-active", !atMin)

    // Filled track up to the thumb.
    const pct = (value - slider.min) / (slider.max - slider.min) * 100
    slider.style.background = `linear-gradient(to right, #000 ${pct}%, #ddd ${pct}%)`

    this.#writeFields(atMin ? null : value)
  }

  #writeFields(value) {
    if (this.kindValue === "rating") {
      this.#field("rating").value = value == null ? "" : Math.round(value * 10)
    } else {
      // Year slider drives the date range RAWG expects (from,to both required).
      const thisYear = parseFloat(this.inputTarget.max)
      this.#field("from").value = value == null ? "" : `${value}-01-01`
      this.#field("to").value   = value == null ? "" : `${thisYear}-12-31`
    }
  }

  #field(name) {
    return this.fieldTargets.find(f => f.dataset.field === name)
  }
}
