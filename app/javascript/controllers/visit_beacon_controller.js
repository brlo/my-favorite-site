import { Controller } from "@hotwired/stimulus"

// Последний отправленный URL — на уровне модуля, чтобы переживать
// пересоздание контроллера при turbo-навигации (body заменяется целиком)
let lastSentUrl = null

// Как часто подтверждать, что вкладка ещё читает статью
const READING_INTERVAL = 45_000

// Маячок посещаемости: шлёт POST /visit на каждый показ страницы,
// чем подтверждает, что в браузере исполнился JS. Статистика считается
// только по этим сигналам — скрейперы, тянущие голый HTML, не учитываются.
//
// Для страниц статей контроллер дополнительно шлёт heartbeat /reading,
// пока вкладка открыта: по нему строится блок «Читают сейчас».
export default class extends Controller {
  connect() {
    this.turboLoadHandler = () => {
      this.send()
      this.startHeartbeat()
    }
    this.visibilityHandler = () => {
      if (!document.hidden) this.sendReading()
    }
    this.leaveHandler = () => this.sendReadingLeave()

    document.addEventListener("turbo:load", this.turboLoadHandler)
    document.addEventListener("visibilitychange", this.visibilityHandler)
    // при переходе по сайту и закрытии вкладки снимаем отметку «читает сейчас»
    document.addEventListener("turbo:before-visit", this.leaveHandler)
    window.addEventListener("pagehide", this.leaveHandler)

    this.send()
    this.startHeartbeat()
  }

  disconnect() {
    document.removeEventListener("turbo:load", this.turboLoadHandler)
    document.removeEventListener("visibilitychange", this.visibilityHandler)
    document.removeEventListener("turbo:before-visit", this.leaveHandler)
    window.removeEventListener("pagehide", this.leaveHandler)
    clearInterval(this.heartbeatTimer)
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

  startHeartbeat() {
    clearInterval(this.heartbeatTimer)

    const pageId = document.body.dataset.visitPageId
    if (!pageId || pageId === "0") return

    this.heartbeatTimer = setInterval(() => this.sendReading(), READING_INTERVAL)
  }

  sendReading() {
    if (document.hidden) return

    const body = document.body
    const pageId = body.dataset.visitPageId
    const token = body.dataset.visitToken
    if (!pageId || pageId === "0" || !token) return

    const params = new URLSearchParams({ page_id: pageId, t: token })

    if (navigator.sendBeacon) {
      navigator.sendBeacon("/reading", params)
    } else {
      fetch("/reading", { method: "POST", body: params, keepalive: true })
    }
  }

  sendReadingLeave() {
    const body = document.body
    const pageId = body.dataset.visitPageId
    const token = body.dataset.visitToken
    if (!pageId || pageId === "0" || !token) return

    const params = new URLSearchParams({ page_id: pageId, t: token, leave: "1" })

    if (navigator.sendBeacon) {
      navigator.sendBeacon("/reading", params)
    } else {
      fetch("/reading", { method: "POST", body: params, keepalive: true })
    }
  }
}
