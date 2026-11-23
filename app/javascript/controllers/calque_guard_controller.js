import { Controller } from "@hotwired/stimulus"

// Калька jp-box рендерится сервером по куке. Turbo/bfcache могут показать
// снимок страницы, сделанный до переключения, — тогда сверяем куку с тем,
// что реально отрисовано, и один раз перезагружаем страницу.
export default class extends Controller {
  connect() {
    this.check = this.check.bind(this)
    document.addEventListener("turbo:load", this.check)
    window.addEventListener("pageshow", this.check)
    this.check()
  }

  disconnect() {
    document.removeEventListener("turbo:load", this.check)
    window.removeEventListener("pageshow", this.check)
  }

  check() {
    const rendered = document.body.dataset.calque
    if (!rendered) return
    const match = document.cookie.match(/(?:^|;\s*)calque=([^;]+)/)
    const current = match && match[1] === "orthodox" ? "orthodox" : "common"
    if (current !== rendered) window.location.reload()
  }
}
