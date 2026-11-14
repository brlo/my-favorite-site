import { Controller } from "@hotwired/stimulus"

// Последний отправленный URL — на уровне модуля, чтобы переживать
// пересоздание контроллера при turbo-навигации (body заменяется целиком)
let lastSentUrl = null

// Маячок посещаемости: шлёт POST /visit на каждый показ страницы,
// чем подтверждает, что в браузере исполнился JS. Статистика считается
// только по этим сигналам — скрейперы, тянущие голый HTML, не учитываются.
export default class extends Controller {
  connect() {
    this.turboLoadHandler = () => this.send()
    document.addEventListener("turbo:load", this.turboLoadHandler)
    this.send()
  }

  disconnect() {
    document.removeEventListener("turbo:load", this.turboLoadHandler)
  }

  send() {
    // connect при первичной загрузке и turbo:load стреляют по одному URL дважды
    if (lastSentUrl === window.location.href) return

    const body = document.body
    const token = body.dataset.visitToken
    if (!token) return

    lastSentUrl = window.location.href

    const params = new URLSearchParams({
      page_id: body.dataset.visitPageId || "0",
      lang: body.dataset.visitLang || "",
      t: token
    })

    if (navigator.sendBeacon) {
      navigator.sendBeacon("/visit", params)
    } else {
      fetch("/visit", { method: "POST", body: params, keepalive: true })
    }
  }
}
