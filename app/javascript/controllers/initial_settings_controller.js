import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.applySettings()
  }

  applySettings() {
    this.applyNightMode()
    this.applyTextSize()
  }

  applyNightMode() {
    if (this.cookieIncludes('isNightMode=1')) {
      document.body.classList.add('night-mode')
    } else {
      document.body.classList.remove('night-mode')
    }
  }

  applyTextSize() {
    const articleEl = document.querySelector('article')
    if (!articleEl) return

    // Удаляем все классы размера текста перед применением нового
    articleEl.classList.remove('text-small', 'text-medium', 'text-large')

    if (this.cookieIncludes('textSize=1')) {
      articleEl.classList.add('text-small')
    } else if (this.cookieIncludes('textSize=2')) {
      articleEl.classList.add('text-medium')
    } else if (this.cookieIncludes('textSize=3')) {
      articleEl.classList.add('text-large')
    }
  }

  cookieIncludes(value) {
    return document.cookie.includes(value)
  }

  // Методы для переключения режимов
  setNightMode(enabled) {
    document.cookie = `isNightMode=${enabled ? 1 : 0}; path=/`
    this.applyNightMode()
  }

  setTextSize(size) {
    // size: 1, 2, или 3
    document.cookie = `textSize=${size}; path=/`
    this.applyTextSize()
  }
}
