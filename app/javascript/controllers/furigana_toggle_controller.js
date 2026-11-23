import { Controller } from "@hotwired/stimulus"
import Cookies from "lib/cookies"

// Кнопка в text-bar: показать/скрыть фуригану (запоминается в куке furigana)
export default class extends Controller {
  connect() {
    this.apply(Cookies.get('furigana') === '0')
  }

  toggle() {
    const off = !this.element.classList.contains('off')
    this.apply(off)
    Cookies.set('furigana', off ? '0' : '1', 365)
  }

  apply(off) {
    this.element.classList.toggle('off', off)
    this.element.setAttribute('aria-pressed', String(!off))
    document.querySelectorAll('[data-furigana-container]').forEach((el) => {
      el.classList.toggle('no-furigana', off)
    })
  }
}
