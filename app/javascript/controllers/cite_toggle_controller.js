import { Controller } from "@hotwired/stimulus"
import Cookies from "lib/cookies"

// Кнопка в text-bar: показать/скрыть карту цитирования (запоминается в куке citeMap)
export default class extends Controller {
  toggle() {
    const off = !this.element.classList.contains('off')
    this.element.classList.toggle('off', off)
    this.element.setAttribute('aria-pressed', String(!off))
    document.getElementById('chapter-text')?.classList.toggle('cite-off', off)
    Cookies.set('citeMap', off ? '0' : '1', 365)
  }
}
