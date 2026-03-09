import { Controller } from "@hotwired/stimulus"

// Подключите этот контроллер к тегу <form>
export default class extends Controller {
  static values = {
    // Задержка в миллисекундах перед отправкой (по умолчанию 100ms)
    delay: { type: Number, default: 100 }
  }

  safeSubmitForm() {
    // const formData = new FormData(this.element)
    // const params = Object.fromEntries(formData.entries())
    // console.log(params)

    // Логика задержки (Debounce)
    if (this.delayValue > 0) {
      clearTimeout(this.timeoutId)
      this.timeoutId = setTimeout(() => {
        this.submitForm()
      }, this.delayValue)
    } else {
      this.submitForm()
    }
  }

  submitForm() {
    this.element.requestSubmit()
  }
}
