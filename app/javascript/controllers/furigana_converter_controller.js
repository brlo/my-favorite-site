import { Controller } from "@hotwired/stimulus"
import { convertToRuby } from 'lib/tools'

export default class extends Controller {
  connect() {
    this.convert()
  }

  convert() {
    const elements = this.element.querySelectorAll('.verse-text')

    elements.forEach(el => {
      if (el.dataset.rubyConverted) return

      const text = el.textContent
      if (!text.includes('[')) return

      const converted = convertToRuby(text)
      if (converted !== text) {
        el.innerHTML = converted
        el.dataset.rubyConverted = 'true'
      }
    })
  }
}
