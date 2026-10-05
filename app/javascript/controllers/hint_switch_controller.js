import { Controller } from "@hotwired/stimulus"

// Меняет текст подсказки под select при выборе значения.
// <select data-controller="hint-switch" data-action="hint-switch#update" data-hint-switch-hints-value='{"1":"..."}'>
// Подсказка — следующий за select элемент .hint
export default class extends Controller {
  static values = { hints: Object }

  update() {
    const hint = this.element.parentElement.querySelector(".hint")
    if (hint) hint.textContent = this.hintsValue[this.element.value] || ""
  }
}
