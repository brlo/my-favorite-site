import { Controller } from "@hotwired/stimulus"
import axios from "lib/axios"

// Счётчик непрочитанных сообщений чата в шапке.
// Отдельный лёгкий опрос вместо постоянного ActionCable-соединения на всех страницах:
// один запрос в минуту и только для тех, у кого уже есть профиль в чате.
export default class extends Controller {
  static targets = ["link"]
  static values = {
    url: String,
    interval: Number,
    title: String,
    replyTitle: String
  }

  connect() {
    this.timer = setInterval(() => this.refresh(), this.intervalValue || 60_000)
    this.onVisibility = () => { if (!document.hidden) this.refresh() }
    document.addEventListener("visibilitychange", this.onVisibility)
  }

  disconnect() {
    clearInterval(this.timer)
    document.removeEventListener("visibilitychange", this.onVisibility)
  }

  async refresh() {
    try {
      const { data } = await axios.get(this.urlValue)
      this.render(data)
    } catch (_) { /* счётчик не критичен для страницы */ }
  }

  render({ count, replies }) {
    const total = Number(count) || 0
    const hasReplies = Number(replies) > 0

    this.linkTargets.forEach((link) => {
      link.hidden = total === 0
      link.dataset.count = total > 99 ? "99+" : String(total)
      link.classList.toggle("chat-notify-link--reply", hasReplies)
      link.title = hasReplies ? this.replyTitleValue : this.titleValue
    })
  }
}
