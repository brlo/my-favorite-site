import { Controller } from "@hotwired/stimulus"

// Один раз запоминает страницу, с которой человек начал посещение сайта (и откуда пришёл).
// Нужна админам чата, чтобы понимать, с каким вопросом пришёл гость.
// Пишется на клиенте, т.к. страницы сайта могут отдаваться из кэша.
export default class extends Controller {
  connect() {
    if (document.cookie.split("; ").some(c => c.startsWith("bx_landing="))) return

    const data = {
      u: (location.pathname + location.search).slice(0, 400),
      r: document.referrer.slice(0, 300),
      t: Date.now()
    }
    const value = encodeURIComponent(JSON.stringify(data))
    document.cookie = `bx_landing=${value}; max-age=${60 * 60 * 24 * 365}; path=/; SameSite=Lax`
  }
}
