import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  hideForm(event) {
    event.preventDefault()
    const form = this.element.querySelector('.translation-form-container')
    if (form) {
      form.innerHTML = ''
    }
  }
}
