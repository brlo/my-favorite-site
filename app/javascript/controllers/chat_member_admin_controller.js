import { Controller } from "@hotwired/stimulus"
import axios from "lib/axios"

// Админские действия в карточке участника чата: титул, роль, мьют, бан
export default class extends Controller {
  static targets = ["title", "result"]
  static values = { url: String }

  saveTitle() {
    this.patch({ title: this.titleTarget.value })
  }

  setRole(event) {
    this.patch({ role: event.currentTarget.value })
  }

  send(event) {
    const { param, value } = event.currentTarget.dataset
    this.patch({ [param]: value })
  }

  async patch(params) {
    try {
      await axios.patch(this.urlValue, params)
      this.resultTarget.textContent = "✓"
      setTimeout(() => window.location.reload(), 400)
    } catch (error) {
      this.resultTarget.textContent = error.response?.data?.error || error.message
    }
  }
}
