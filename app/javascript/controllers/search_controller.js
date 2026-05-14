import { Controller } from "@hotwired/stimulus"
import { getCurrentLocale } from 'lib/localization'

export default class extends Controller {
  static targets = ["input"]
  static values = { locale: String }

  // Отправка формы поиска
  submit(event) {
    event.preventDefault()
    this.goToSearch(event.currentTarget)
  }

  // Обработка клика на иконку поиска
  searchIconClick(event) {
    event.preventDefault()
    const form = event.currentTarget.closest('form')
    if (form) this.goToSearch(form)
  }

  goToSearch(form) {
    let text, lang

    if (form) {
      text = form.querySelector('.search-tree-input')?.value
    } else if (this.hasInputTarget) {
      text = this.inputTarget.value
    }
    lang = document.getElementById('lang-select')?.value

    const params = new URLSearchParams()
    if (lang && lang.length > 0) params.append('l', lang)
    if (text && text.length > 0) params.append('t', text)

    const locale = this.localeValue || getCurrentLocale() || 'ru'
    document.location.href = `/${locale}/search?${params.toString()}`
  }
}
