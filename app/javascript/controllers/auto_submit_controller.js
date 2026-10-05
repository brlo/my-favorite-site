import { Controller } from "@hotwired/stimulus"

// Отправляет форму при изменении полей (поиск по мере ввода, загрузка файла сразу после выбора)
export default class extends Controller {
  static values = { delay: { type: Number, default: 300 } }

  disconnect() {
    clearTimeout(this.timeout)
  }

  // поле может быть привязано к форме вне контроллера атрибутом form (input.form это учитывает)
  submit(event) {
    const form = event?.target?.form || this.element
    form.requestSubmit()
  }

  debounced(event) {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.submit(event), this.delayValue)
  }
}
