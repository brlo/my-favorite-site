import { Controller } from "@hotwired/stimulus"

// Отметка строк чекбоксами: «отметить все», счётчик и кнопка действия
export default class extends Controller {
  static targets = ["checkbox", "toggle", "count", "button"]

  connect() {
    this.update()
  }

  toggleAll() {
    this.enabledCheckboxes.forEach(cb => { cb.checked = this.toggleTarget.checked })
    this.update()
  }

  update() {
    const checked = this.enabledCheckboxes.filter(cb => cb.checked).length
    if (this.hasCountTarget) this.countTarget.textContent = checked
    if (this.hasButtonTarget) this.buttonTarget.disabled = checked === 0
    if (this.hasToggleTarget) {
      this.toggleTarget.checked = checked > 0 && checked === this.enabledCheckboxes.length
    }
  }

  get enabledCheckboxes() {
    return this.checkboxTargets.filter(cb => !cb.disabled)
  }
}
