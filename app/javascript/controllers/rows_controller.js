import { Controller } from "@hotwired/stimulus"

// Динамический список строк формы: добавление из <template> и удаление
export default class extends Controller {
  static targets = ["list", "template"]

  add() {
    this.listTarget.append(this.templateTarget.content.cloneNode(true))
    this.listTarget.lastElementChild?.querySelector("input")?.focus()
  }

  remove(event) {
    event.currentTarget.closest(".link-row")?.remove()
  }
}
