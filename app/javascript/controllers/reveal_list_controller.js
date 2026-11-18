import { Controller } from "@hotwired/stimulus"

// Сворачивает длинное содержание по клику на верхнюю полоску с заголовком.
export default class extends Controller {
  static targets = ["button"]

  toggle() {
    const is_collapsed = this.element.classList.toggle("collapsed")
    this.buttonTarget.setAttribute("aria-expanded", String(!is_collapsed))
  }
}
