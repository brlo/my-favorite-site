import { Controller } from "@hotwired/stimulus"

// Выбор языка интерфейса в шапке: кнопка с глобусом раскрывает список языков.
// Пункты списка — обычные ссылки, поэтому переход работает и без JS;
// скрипт только раскрывает/закрывает список, ведёт себя как меню
// (клик вне, Escape) и сохраняет якорь (#L10) при смене языка.
export default class extends Controller {
  static targets = ["button", "menu"]

  connect() {
    this.handleDocumentClick = this.handleDocumentClick.bind(this)
    this.handleKeydown = this.handleKeydown.bind(this)
    this.handleBeforeCache = () => this.close()
    document.addEventListener('turbo:before-cache', this.handleBeforeCache)
  }

  disconnect() {
    this.removeListeners()
    document.removeEventListener('turbo:before-cache', this.handleBeforeCache)
  }

  toggle(event) {
    event.preventDefault()
    this.isOpen() ? this.close() : this.open()
  }

  open() {
    this.menuTarget.classList.remove('hidden')
    this.buttonTarget.setAttribute('aria-expanded', 'true')
    document.addEventListener('click', this.handleDocumentClick)
    document.addEventListener('keydown', this.handleKeydown)
    // открываем на текущем языке: он подсвечен и сразу виден в прокрутке
    const current = this.menuTarget.querySelector('.selected') || this.menuTarget.querySelector('a')
    current?.focus()
    current?.scrollIntoView({ block: 'nearest' })
  }

  close() {
    this.menuTarget.classList.add('hidden')
    this.buttonTarget.setAttribute('aria-expanded', 'false')
    this.removeListeners()
  }

  isOpen() {
    return !this.menuTarget.classList.contains('hidden')
  }

  removeListeners() {
    document.removeEventListener('click', this.handleDocumentClick)
    document.removeEventListener('keydown', this.handleKeydown)
  }

  handleDocumentClick(event) {
    if (this.element.contains(event.target)) return
    this.close()
  }

  handleKeydown(event) {
    if (event.key !== 'Escape') return
    this.close()
    this.buttonTarget.focus()
  }

  // Ссылка ведёт на тот же путь с другим языком — не теряем якорь стиха/раздела
  keepAnchor(event) {
    const link = event.target.closest('a')
    if (!link || !window.location.hash) return
    link.hash = window.location.hash
  }
}
