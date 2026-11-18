import { Controller } from "@hotwired/stimulus"

// Плавающее приглашение в чат: появляется, когда читатель доходит
// до конца статьи, и больше не показывается после закрытия.
export default class extends Controller {
  static targets = ["sentinel", "panel"]

  connect() {
    this.dismissed = false
    this.checkEnd = this.checkEnd.bind(this)
    this.syncHeight = this.syncHeight.bind(this)

    window.addEventListener("scroll", this.checkEnd, { passive: true })
    window.addEventListener("resize", this.checkEnd)
    requestAnimationFrame(this.checkEnd)
  }

  disconnect() {
    window.removeEventListener("scroll", this.checkEnd)
    window.removeEventListener("resize", this.checkEnd)
    window.removeEventListener("resize", this.syncHeight)
    this.clearPageState()
  }

  checkEnd() {
    if (this.dismissed || !this.panelTarget.hidden) return
    if (this.sentinelTarget.getBoundingClientRect().top <= window.innerHeight) this.show()
  }

  show() {
    if (this.dismissed || !this.panelTarget.hidden) return

    this.panelTarget.hidden = false
    window.removeEventListener("scroll", this.checkEnd)
    window.removeEventListener("resize", this.checkEnd)
    this.syncHeight()
    window.addEventListener("resize", this.syncHeight)
    document.documentElement.classList.add("chat-invite-visible")
  }

  close(event) {
    event?.preventDefault()
    event?.stopPropagation()

    this.dismissed = true
    this.panelTarget.hidden = true
    window.removeEventListener("scroll", this.checkEnd)
    window.removeEventListener("resize", this.checkEnd)
    window.removeEventListener("resize", this.syncHeight)
    this.clearPageState()
  }

  // поднимаем кнопку «наверх» над плавающей панелью
  syncHeight() {
    if (this.panelTarget.hidden) return
    document.documentElement.style.setProperty("--chat-invite-h", `${this.panelTarget.offsetHeight}px`)
  }

  clearPageState() {
    document.documentElement.classList.remove("chat-invite-visible")
    document.documentElement.style.removeProperty("--chat-invite-h")
  }
}
