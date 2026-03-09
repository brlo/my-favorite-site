// app/javascript/controllers/text_fragment_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["link", "snippet"]
  static values = {
    baseUrl: String,
    wordsCount: { type: Number, default: 40 } // длина фрагмента
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
    // Разбиваем на слова, фильтруем пустые
    const words = text.split(' ').filter(w => w.length > 0)

    // Берём первые N слов — этого обычно достаточно для уникальности
    const fragmentWords = words.slice(0, this.wordsCountValue)

    if (fragmentWords.length < 3) {
      // Слишком короткий текст — используем как есть
      return encodeURIComponent(text)
    }

    const fragment = fragmentWords.join(' ')

    // экранируем запятые, чтобы они не ломали синтаксис
    return encodeURIComponent(fragment)
  }
}
