import { Controller } from "@hotwired/stimulus"

// Карта цитирования: по клику на участок линии рядом со стихом
// подгружает и показывает список авторов с фрагментами их трудов.
export default class extends Controller {
  static values = { url: String }

  connect() {
    this.onKeydown = (e) => { if (e.key === 'Escape') this.close() }
    document.addEventListener('keydown', this.onKeydown)
  }

  disconnect() {
    document.removeEventListener('keydown', this.onKeydown)
    this.panel?.remove()
  }

  async open(event) {
    event.preventDefault()
    event.stopPropagation()
    const bar = event.currentTarget
    const line = bar.dataset.line

    this.markActive(bar)
    const panel = this.ensurePanel()
    panel.innerHTML = '<div class="cite-loading">…</div>'
    panel.classList.add('open')
    this.backdrop.classList.add('open')

    try {
      const res = await fetch(`${this.urlValue}/${line}`, { headers: { Accept: 'text/html' } })
      if (!res.ok) throw new Error(res.status)
      panel.innerHTML = await res.text()
      panel.scrollTop = 0
    } catch (e) {
      panel.innerHTML = '<div class="cite-empty">Error</div>'
    }
  }

  close() {
    this.panel?.classList.remove('open')
    this.backdrop?.classList.remove('open')
    this.markActive(null)
  }

  markActive(bar) {
    this.element.querySelectorAll('.cite-bar.active').forEach((el) => el.classList.remove('active'))
    bar?.classList.add('active')
  }

  ensurePanel() {
    if (this.panel) return this.panel
    this.backdrop = document.createElement('div')
    this.backdrop.className = 'cite-backdrop'
    this.backdrop.addEventListener('click', () => this.close())
    this.panel = document.createElement('aside')
    this.panel.className = 'cite-panel'
    // кнопка «×» внутри загруженного HTML обрабатывается делегированием
    this.panel.addEventListener('click', (e) => { if (e.target.closest('.cite-close')) this.close() })
    document.body.append(this.backdrop, this.panel)
    return this.panel
  }
}
