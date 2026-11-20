import { Controller } from '@hotwired/stimulus'
import { shareLink } from 'lib/tools'

export default class extends Controller {
  static values = { url: String }

  share(event) {
    event.preventDefault()
    // По умолчанию делимся текущей страницей; в ленте передаём канонический адрес статьи
    shareLink(this.hasUrlValue && this.urlValue ? this.urlValue : window.location.href)
  }
}
