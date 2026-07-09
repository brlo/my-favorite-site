import { Controller } from '@hotwired/stimulus'
import { convertToRuby } from 'lib/tools'

export default class extends Controller {
  edit(event) {
    event.stopPropagation()
    if (this.isEditing) return

    this.isEditing = true
    const currentText = this.element.dataset.text.trim()
    const verseId = this.element.dataset.verseId

    const textarea = document.createElement('textarea')
    textarea.value = currentText
    textarea.className = 'verse-edit-textarea'
    textarea.rows = 3

    this.element.textContent = ''
    this.element.appendChild(textarea)
    this.element.classList.add('editing')

    textarea.focus()
    // textarea.select()

    const save = () => {
      const newValue = textarea.value.trim()
      if (currentText !== newValue) this.saveVerse(verseId, newValue)
      this.finishEditing(newValue)
    }

    const cancel = () => {
      this.finishEditing(currentText)
    }

    textarea.addEventListener('blur', save)
    textarea.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && (e.ctrlKey || e.metaKey)) {
        e.preventDefault()
        cancel()
      }
      // Ctrl+Enter для сохранения
      if (e.key === 'Enter' && (e.ctrlKey || e.metaKey)) {
        e.preventDefault()
        textarea.blur()
      }
    })

    this._textarea = textarea
    this._save = save
    this._cancel = cancel
  }

  finishEditing(text) {
    if (!this.isEditing) return
    this.isEditing = false

    this.element.innerHTML = convertToRuby(text)
    this.element.classList.remove('editing')

    if (this._textarea) {
      this._textarea.removeEventListener('blur', this._save)
      this._textarea.removeEventListener('keydown', this._cancel)
      this._textarea = null
    }
  }

  async saveVerse(verseId, newText) {
    try {
      const locale_and_lang = window.location.pathname.split('/').filter(Boolean).slice(0, 2).join('/')
      const response = await fetch(`/${locale_and_lang}/verses/${verseId}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          verse: {
            text: newText
          }
        })
      })

      if (!response.ok) throw new Error('Failed to save')

      this.element.dataset.text = newText
      this.showFeedback('✓', 'success')
    } catch (error) {
      console.error('Error saving verse:', error)
      this.showFeedback('✗', 'error')
      this.finishEditing(this.element.dataset.text)
    }
  }

  showFeedback(symbol, type) {
    const indicator = document.createElement('span')
    indicator.textContent = symbol
    indicator.className = `verse-feedback verse-feedback-${type}`

    this.element.appendChild(indicator)

    setTimeout(() => {
      if (indicator.parentNode) {
        indicator.remove()
      }
    }, 1500)
  }
}
