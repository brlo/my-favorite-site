import { Controller } from "@hotwired/stimulus"
import { shareLink } from "lib/tools"

export default class extends Controller {
  connect() {
    this.addShareLinks()
  }

  addShareLinks() {
    const shareElements = this.element.querySelectorAll('[data-share-id]')

    shareElements.forEach(element => {
      // Пропускаем, если ссылка уже добавлена
      if (element.querySelector('.copy-anchor')) return

      const shareId = element.dataset.shareId
      if (!shareId) return

      const link = document.createElement('a')
      link.href = this.buildHref(shareId)
      link.className = 'copy-link'
      link.setAttribute('aria-label', 'Скопировать ссылку на элемент')

      // исходное содержимое
      const originalContent = element.innerHTML

      // Очищаем элемент и добавляем ссылку с содержимым
      element.innerHTML = ''
      link.innerHTML = originalContent

      link.addEventListener('click', (e) => this.copyLink(e))

      element.appendChild(link)
    })
  }

  buildHref(shareId) {
    const base = window.location.href.split('#')[0]
    return `${base}#${shareId}`
  }

  copyLink(event) {
    event.preventDefault()
    event.stopPropagation()
    const href = event.currentTarget.href
    shareLink(href)
  }

  // Метод для пересоздания ссылок, если контент подгружается динамически
  refresh() {
    this.addShareLinks()
  }
}
