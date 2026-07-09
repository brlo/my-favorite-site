import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    id: Number
  }

  connect() {
    this.originalText = this.element.dataset
  }

  edit(event) {
    event.stopPropagation()
    if (this.isEditing) return

    this.isEditing = true
    const rt = this.element.querySelector('rt')
    const currentText = this.element.dataset.word
    const verseId = this.element.dataset.verseId
    const wordIndex = this.element.dataset.wordIndex

    // Создаем input с классами
    const input = document.createElement('input')
    input.type = 'text'
    input.value = currentText
    input.className = 'interlinear-edit-input'

    // Добавляем класс editing на ruby
    this.element.classList.add('editing')

    rt.textContent = ''
    rt.appendChild(input)
    input.focus()
    input.select()

    const save = () => {
      const newValue = input.value.trim()
      // save if changed
      if (currentText !== newValue) this.saveWord(verseId, wordIndex, newValue)
      this.finishEditing(rt, newValue)
    }

    const cancel = () => {
      this.finishEditing(rt, this.originalText)
    }

    input.addEventListener('blur', save)
    input.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        e.preventDefault()
        input.blur()
      } else if (e.key === 'Escape' && (e.ctrlKey || e.metaKey)) {
        e.preventDefault()
        cancel()
      }
    })

    this._input = input
    this._save = save
    this._cancel = cancel
  }

  finishEditing(rt, text) {
    if (!this.isEditing) return
    this.isEditing = false

    rt.textContent = text
    this.originalText = text
    this.element.classList.remove('editing')

    if (this._input) {
      this._input.removeEventListener('blur', this._save)
      this._input.removeEventListener('keydown', this._cancel)
      this._input = null
    }
  }

  async saveWord(verseId, wordIndex, newText) {
    try {
      const locale_and_lang = window.location.pathname.split('/').filter(Boolean).slice(0, 2).join('/');
      const response = await fetch(`/${locale_and_lang}/verses/${verseId}/update_interlinear_word`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          word_index: wordIndex,
          word: newText
        })
      })

      if (!response.ok) throw new Error('Failed to save')

      this.element.dataset.word = newText
      this.showFeedback('✓', 'success')
    } catch (error) {
      console.error('Error saving word:', error)
      this.showFeedback('✗', 'error')
      this.finishEditing(this.element.querySelector('rt'), this.originalText)
    }
  }

  showFeedback(symbol, type) {
    const rt = this.element.querySelector('rt')
    const originalText = this.element.dataset.word

    const indicator = document.createElement('span')
    indicator.textContent = symbol
    indicator.className = `interlinear-feedback interlinear-feedback-${type}`

    rt.appendChild(indicator)

    setTimeout(() => {
      if (indicator.parentNode) {
        indicator.remove()
        rt.textContent = originalText
      }
    }, 1500)
  }
}
