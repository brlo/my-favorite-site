// app/javascript/controllers/text_fragment_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["link", "snippet"]
  static values = {
    baseUrl: String,
    wordsCount: { type: Number, default: 4 } // длина фрагмента
  }

  connect() {
    this.generateFragmentLink()
  }

  generateFragmentLink() {
    const snippetText = this.snippetTarget?.textContent?.trim()
    if (!snippetText || !this.linkTarget) return

    const cleanedText = this.cleanText(snippetText)
    const fragment = this.createSimpleFragment(cleanedText)

    if (fragment) {
      // baseUrl уже содержит полный путь, просто добавляем фрагмент
      const base = this.baseUrlValue || this.linkTarget.href.split('#')[0]
      this.linkTarget.href = `${base}#:~:text=${fragment}`
      this.linkTarget.classList.add('text-fragment-link')
    }
  }

  cleanText(text) {
    return text
      .replace(/\s+/g, ' ')      // Нормализуем пробелы
      .replace(/[\n\r\t]/g, '')  // Удаляем переносы
      .trim()
  }

  createSimpleFragment(text) {
    const tokens = text.match(/\S+/g) || []

    if (tokens.length <= this.wordsCountValue * 2) {
      return this._encodeFragmentPart(tokens.join(' '))
    }

    const firstTokens = tokens.slice(0, this.wordsCountValue)
    const lastTokens = tokens.slice(-this.wordsCountValue)

    let firstPart = firstTokens.join(' ').trim().replace(/[.,;:!?…]+$/, '')
    let lastPart = lastTokens.join(' ').trim().replace(/^[.,;:!?…]+/, '')

    if (!firstPart || !lastPart) {
      return this._encodeFragmentPart(tokens.join(' '))
    }

    // Разделительную запятую нельзя кодировать
    return `${this._encodeFragmentPart(firstPart)},${this._encodeFragmentPart(lastPart)}`
  }

  // Кодирование для Text Fragment API
  _encodeFragmentPart(text) {
    return encodeURIComponent(text)
      .replace(/-/g, '%2D')   // Дефис → %2D (конфликтует с синтаксисом контекста)
      .replace(/_/g, '%5F')   // Подчёркивание → %5F (на всякий случай)
  }
}
