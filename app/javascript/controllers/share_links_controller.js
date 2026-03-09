import { Controller } from "@hotwired/stimulus"
import { shareLink } from "../lib/tools"

export default class extends Controller {
  static targets = ["header"]

  connect() {
    this.addShareLinks()
  }

  addShareLinks() {
    // Ищем заголовки внутри элемента контроллера
    const headers = this.element.querySelectorAll('h2[id], h3[id], h4[id]')

    headers.forEach(header => {
      // Пропускаем, если ссылка уже добавлена (защита от двойного connect)
      if (header.querySelector('.copy-anchor')) return

      const link = document.createElement('a')
      link.href = this.buildHref(header.id)
      link.className = 'copy-anchor'
      link.setAttribute('aria-label', 'Скопировать ссылку на раздел')

      // Обработчик через метод контроллера для удобства тестирования
      link.addEventListener('click', (e) => this.copyLink(e))

      header.insertAdjacentElement('afterbegin', link)
    })
  }

  buildHref(headerId) {
    const base = window.location.href.split('#')[0]
    return `${base}#${headerId}`
  }

  copyLink(event) {
    event.preventDefault()
    const href = event.currentTarget.href
    shareLink(href)
  }

  // Метод для пересоздания ссылок, если контент подгружается динамически
  refresh() {
    this.addShareLinks()
  }
}
