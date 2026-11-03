import { Controller } from "@hotwired/stimulus"

// Сворачивает длинный список: скрытые пункты (.extra) показываются по нажатию на стрелку.
export default class extends Controller {
  static targets = ["button", "label"]
  static values = { expandText: String, collapseText: String }

  toggle() {
    const is_collapsed = this.element.classList.toggle("collapsed")
    this.buttonTarget.setAttribute("aria-expanded", String(!is_collapsed))
    this.labelTarget.textContent = is_collapsed ? this.expandTextValue : this.collapseTextValue
  }
}
