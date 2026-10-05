import { Controller } from "@hotwired/stimulus"

// Копирует HTML в буфер обмена (как text/html, чтобы вставлялся в редактор с разметкой, и как text/plain)
export default class extends Controller {
  static values = { content: String }

  connect() {
    this.label = this.element.textContent
  }

  async copy() {
    const html = this.contentValue
    const ok = (await this.copyWithClipboardApi(html)) || this.copyWithCopyEvent(html)

    this.element.textContent = ok ? "Скопировано ✓" : "Не удалось скопировать"
    setTimeout(() => { this.element.textContent = this.label }, 1500)
  }

  // Clipboard API есть только в безопасном контексте (https или localhost)
  async copyWithClipboardApi(html) {
    if (!window.isSecureContext || !navigator.clipboard?.write || typeof ClipboardItem === "undefined") return false

    try {
      await navigator.clipboard.write([
        new ClipboardItem({
          "text/html": new Blob([html], { type: "text/html" }),
          "text/plain": new Blob([html], { type: "text/plain" }),
        }),
      ])
      return true
    } catch (e) {
      console.warn("Clipboard API:", e)
      return false
    }
  }

  // Запасной способ (работает и по http): подменяем данные в событии copy
  copyWithCopyEvent(html) {
    const onCopy = (event) => {
      event.clipboardData.setData("text/html", html)
      event.clipboardData.setData("text/plain", html)
      event.preventDefault()
    }

    document.addEventListener("copy", onCopy, { once: true })
    try {
      return document.execCommand("copy")
    } catch (e) {
      console.warn("execCommand copy:", e)
      return false
    } finally {
      document.removeEventListener("copy", onCopy)
    }
  }
}
