import { Controller } from "@hotwired/stimulus"

// Живой блок «Читают сейчас»: раз в минуту перезапрашивает разметку блока.
export default class extends Controller {
  static values = { url: String, interval: { type: Number, default: 60000 } }

  connect() {
    this.refresh = this.refresh.bind(this)
    this.onVisibility = () => { if (!document.hidden) this.refresh() }

    document.addEventListener("visibilitychange", this.onVisibility)
    this.timer = setInterval(this.refresh, this.intervalValue)
  }

  disconnect() {
    clearInterval(this.timer)
    document.removeEventListener("visibilitychange", this.onVisibility)
  }

  async refresh() {
    if (document.hidden || !this.hasUrlValue) return

    try {
      const response = await fetch(this.urlValue, {
        headers: { Accept: "text/html" },
        credentials: "same-origin"
      })
      if (response.ok) this.element.innerHTML = await response.text()
    } catch (_error) {
      // сети нет — оставляем прежние данные до следующей попытки
    }
  }
}
