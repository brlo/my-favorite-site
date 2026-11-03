import { Controller } from "@hotwired/stimulus"

// Меню «⋯» в шапке: дополнительные пункты (чат, переводы, помощь сайту)
export default class extends Controller {
  static targets = ["menu", "button"]

  toggle(event) {
    event.preventDefault()
    this.menuTarget.classList.toggle('hidden')
  }

  // клик вне меню
  clickOutside(event) {
    if (this.menuTarget.classList.contains('hidden')) return
    if (this.element.contains(event.target)) return
    this.menuTarget.classList.add('hidden')
  }
}
