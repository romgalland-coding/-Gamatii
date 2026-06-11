import { Controller } from "@hotwired/stimulus"

// Filter panel for the list /build (discovery) page. Visually mirrors the
// list-show filter panel, but its inputs are a real GET form: "Apply" submits
// it so the server re-runs the RAWG search with the chosen filters.
export default class extends Controller {
  static targets = ["panel", "toggleBtn", "form"]

  connect() {
    const btn = this.toggleBtnTarget
    const rect = btn.getBoundingClientRect()
    const initialTop = rect.top
    const initialRight = window.innerWidth - rect.right

    this._onScroll = () => {
      const scrolled = window.scrollY > 60
      btn.classList.toggle("is-scrolled", scrolled)
      if (scrolled) {
        btn.style.top = `${initialTop}px`
        btn.style.right = `${initialRight}px`
      } else {
        btn.style.top = ""
        btn.style.right = ""
      }
    }
    window.addEventListener("scroll", this._onScroll, { passive: true })
  }

  disconnect() {
    window.removeEventListener("scroll", this._onScroll)
  }

  // --- Panel ---

  toggle() {
    this.panelTarget.classList.toggle("is-open")
    if (this.panelTarget.classList.contains("is-open") && window.scrollY > 60) {
      window.scrollTo({ top: 0, behavior: "smooth" })
    }
  }

  close() {
    this.panelTarget.classList.remove("is-open")
    this.#closeAllDropdowns()
  }

  // --- Dropdowns (multi-select checkboxes) ---

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

    labelEl.textContent = checked.length === 0
      ? placeholder
      : checked.map(cb => cb.dataset.displayLabel || cb.value).join(", ")
  }

  // --- Slider (rating) ---

  updateSliderLabel(event) {
    const slider = event.currentTarget
    const value = parseFloat(slider.value)
    const isAtMin = value <= parseFloat(slider.min)
    const valueEl = slider.closest(".filter-slider-row").querySelector(".filter-slider-value")

    valueEl.textContent = isAtMin ? "—" : `${value}+`
    valueEl.classList.toggle("is-active", !isAtMin)
    this.#updateSliderTrack(slider)
  }

  // --- Apply / reset ---

  // Submit the form so the server re-runs the search with the chosen filters.
  apply() {
    this.formTarget.requestSubmit()
  }

  // Clear every input, then submit so results return to unfiltered.
  reset() {
    this.element.querySelectorAll(".filter-checkbox").forEach(cb => { cb.checked = false })
    this.element.querySelectorAll(".filter-dropdown").forEach(dropdown => {
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
    this.element.querySelectorAll("input[type=date]").forEach(input => { input.value = "" })
    this.formTarget.requestSubmit()
  }

  // --- Private ---

  #closeAllDropdowns() {
    this.element.querySelectorAll(".filter-dropdown__menu.is-open").forEach(m => {
      m.classList.remove("is-open")
    })
  }

  #updateSliderTrack(slider) {
    const pct = (parseFloat(slider.value) - parseFloat(slider.min)) /
                (parseFloat(slider.max) - parseFloat(slider.min)) * 100
    slider.style.background = `linear-gradient(to right, #000 ${pct}%, #ddd ${pct}%)`
  }
}
