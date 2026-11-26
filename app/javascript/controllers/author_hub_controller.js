import { Controller } from "@hotwired/stimulus"

// Панель автора на публичной странице: открывает кабинет в модальном окне
// и один раз показывает подсказку о новых возможностях.
export default class extends Controller {
  static targets = ["dialog", "frame", "tour"]
  static values = { workspaceUrl: String, tourKey: String }

  connect() {
    this.changed = false
    this.handleDialogClose = this.handleDialogClose.bind(this)
    this.markChanged = this.markChanged.bind(this)
    this.dialogTarget.addEventListener("close", this.handleDialogClose)
    // Любое успешное действие в кабинете меняет меню на странице —
    // после закрытия окна перечитываем страницу, чтобы это стало видно.
    this.element.addEventListener("turbo:submit-end", this.markChanged)

    if (this.hasTourTarget && !this.tourSeen()) {
      this.tourTarget.hidden = false
    }
  }

  disconnect() {
    this.dialogTarget.removeEventListener("close", this.handleDialogClose)
    this.element.removeEventListener("turbo:submit-end", this.markChanged)
  }

  markChanged(event) {
    if (event.detail?.success) this.changed = true
  }

  open(event) {
    event.preventDefault()
    this.openWorkspace(event.params.mode)
  }

  openWorkspace(mode) {
    if (!this.frameTarget.hasAttribute("src")) {
      this.frameTarget.src = this.workspaceUrlValue
    }

    if (!this.dialogTarget.open) {
      this.dialogTarget.showModal()
    }

    document.documentElement.classList.add("author-hub-open")
    this.hideTour()

    if (mode === "article") this.focusTitle()
  }

  close(event) {
    event?.preventDefault()
    if (this.dialogTarget.open) this.dialogTarget.close()
  }

  // Клик по затемнённой области вокруг окна закрывает его
  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  startTour(event) {
    event.preventDefault()
    this.openWorkspace("article")
  }

  dismissTour(event) {
    event?.preventDefault()
    this.hideTour()
  }

  handleDialogClose() {
    document.documentElement.classList.remove("author-hub-open")

    if (this.changed) {
      this.changed = false
      window.location.reload()
    }
  }

  focusTitle() {
    const focus = () => {
      const input = this.frameTarget.querySelector("input[name='title']")
      if (!input) return
      input.focus()
      input.scrollIntoView({ block: "center" })
    }

    if (this.frameTarget.querySelector("input[name='title']")) {
      focus()
    } else {
      this.frameTarget.addEventListener("turbo:frame-load", focus, { once: true })
    }
  }

  hideTour() {
    if (this.hasTourTarget) this.tourTarget.hidden = true
    try {
      localStorage.setItem(this.tourKeyValue, "1")
    } catch (_) {
      // приватный режим — просто не запоминаем
    }
  }

  tourSeen() {
    try {
      return localStorage.getItem(this.tourKeyValue) === "1"
    } catch (_) {
      return true
    }
  }
}
