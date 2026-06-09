import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "toggleBtn", "card", "count", "emptyState"]

  // --- Panel ---

  toggle() {
    this.panelTarget.classList.toggle("is-open")
  }

  close() {
    this.panelTarget.classList.remove("is-open")
    this.#closeAllDropdowns()
  }

  // --- Dropdowns ---

  toggleDropdown(event) {
    event.stopPropagation()
    const dropdown = event.currentTarget.closest(".filter-dropdown")
    const menu = dropdown.querySelector(".filter-dropdown__menu")
    const opening = !menu.classList.contains("is-open")

    this.#closeAllDropdowns()

    if (opening) {
      menu.classList.add("is-open")
      const closeHandler = (e) => {
        if (!dropdown.contains(e.target)) {
          menu.classList.remove("is-open")
          document.removeEventListener("click", closeHandler)
        }
      }
      document.addEventListener("click", closeHandler)
    }
  }

  updateDropdownLabel(event) {
    const dropdown = event.currentTarget.closest(".filter-dropdown")
    const trigger = dropdown.querySelector(".filter-dropdown__trigger")
    const labelEl = trigger.querySelector(".filter-dropdown__label")
    const checked = Array.from(dropdown.querySelectorAll(".filter-checkbox:checked"))
    const placeholder = trigger.dataset.placeholder

    if (checked.length === 0) {
      labelEl.textContent = placeholder
    } else {
      const labels = checked.map(cb => cb.dataset.displayLabel || cb.value)
      labelEl.textContent = labels.join(", ")
    }
  }

  // --- Sliders ---

  updateSliderLabel(event) {
    const slider = event.currentTarget
    const value = parseFloat(slider.value)
    const isAtMin = value <= parseFloat(slider.min)
    const valueEl = slider.closest(".filter-slider-row").querySelector(".filter-slider-value")
    const type = slider.dataset.filterType

    valueEl.textContent = isAtMin ? "—" : (type === "rating" ? `${value.toFixed(1)}+` : `${value}+`)
    valueEl.classList.toggle("is-active", !isAtMin)
    this.#updateSliderTrack(slider)
  }

  // --- Filter apply / reset ---

  apply() {
    const selected = this.#selectedFilters()
    const hasFilters = Object.keys(selected).length > 0
    let visibleCount = 0

    this.cardTargets.forEach(card => {
      const visible = !hasFilters || this.#cardMatches(card, selected)
      card.style.display = visible ? "" : "none"
      if (visible) visibleCount++
    })

    this.#updateCount(this.#activeFilterCount())
    this.#updateEmptyState(visibleCount === 0 && hasFilters)
    this.toggleBtnTarget.classList.toggle("is-active", hasFilters)
    this.panelTarget.classList.remove("is-open")
    this.#closeAllDropdowns()
  }

  reset() {
    this.element.querySelectorAll(".filter-dropdown").forEach(dropdown => {
      dropdown.querySelectorAll(".filter-checkbox").forEach(cb => cb.checked = false)
      const labelEl = dropdown.querySelector(".filter-dropdown__label")
      const trigger = dropdown.querySelector(".filter-dropdown__trigger")
      if (labelEl && trigger) labelEl.textContent = trigger.dataset.placeholder
    })

    this.element.querySelectorAll(".filter-slider-input").forEach(slider => {
      slider.value = slider.min
      const valueEl = slider.closest(".filter-slider-row")?.querySelector(".filter-slider-value")
      if (valueEl) { valueEl.textContent = "—"; valueEl.classList.remove("is-active") }
      this.#updateSliderTrack(slider)
    })

    this.cardTargets.forEach(card => card.style.display = "")
    this.#updateCount(0)
    this.#updateEmptyState(false)
    this.toggleBtnTarget.classList.remove("is-active")
    this.panelTarget.classList.remove("is-open")
    this.#closeAllDropdowns()
  }

  // --- Private ---

  #closeAllDropdowns() {
    this.element.querySelectorAll(".filter-dropdown__menu.is-open").forEach(m => {
      m.classList.remove("is-open")
    })
  }

  #selectedFilters() {
    const selected = {}

    this.element.querySelectorAll(".filter-checkbox:checked").forEach(cb => {
      const type = cb.dataset.filterType
      if (!selected[type]) selected[type] = []
      selected[type].push(cb.value)
    })

    this.element.querySelectorAll(".filter-slider-input").forEach(slider => {
      if (parseFloat(slider.value) > parseFloat(slider.min)) {
        selected[slider.dataset.filterType] = [slider.value]
      }
    })

    return selected
  }

  #cardMatches(card, selected) {
    return Object.entries(selected).every(([type, values]) => {
      switch (type) {
        case "platform": {
          const platforms = JSON.parse(card.dataset.platforms || "[]")
          return values.some(v => platforms.includes(v))
        }
        case "genre":
          return values.includes(card.dataset.genre)
        case "studio":
          return values.includes(card.dataset.studio)
        case "rating": {
          const rating = parseInt(card.dataset.rating || "0")
          return parseFloat(values[0]) * 10 <= rating
        }
        case "year": {
          const year = parseInt(card.dataset.year || "0")
          return parseInt(values[0]) <= year
        }
        default:
          return true
      }
    })
  }

  #activeFilterCount() {
    const checked = this.element.querySelectorAll(".filter-checkbox:checked").length
    const sliders = Array.from(this.element.querySelectorAll(".filter-slider-input"))
      .filter(s => parseFloat(s.value) > parseFloat(s.min)).length
    return checked + sliders
  }

  #updateCount(n) {
    if (!this.hasCountTarget) return
    this.countTarget.textContent = n > 0 ? n : ""
    this.countTarget.classList.toggle("is-visible", n > 0)
  }

  #updateEmptyState(show) {
    if (!this.hasEmptyStateTarget) return
    this.emptyStateTarget.style.display = show ? "flex" : "none"
  }

  #updateSliderTrack(slider) {
    const pct = (parseFloat(slider.value) - parseFloat(slider.min)) /
                (parseFloat(slider.max) - parseFloat(slider.min)) * 100
    slider.style.background = `linear-gradient(to right, #000 ${pct}%, #ddd ${pct}%)`
  }
}
