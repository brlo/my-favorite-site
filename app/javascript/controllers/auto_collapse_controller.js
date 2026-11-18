import { Controller } from "@hotwired/stimulus"

// Сворачивает блок, если он выше заданной высоты (maxHeight)
// или занимает больше заданного числа строк (maxRows).
export default class extends Controller {
  static targets = ["button", "static", "content"]
  static values = { maxHeight: Number, maxRows: Number, alwaysToggle: Boolean }

  connect() {
    this.isCollapsible = false
    this.userToggled = false
    this.userCollapsed = false
    this.check = this.check.bind(this)
    window.addEventListener("resize", this.check)

    // Высота может измениться после загрузки шрифтов или смены размера текста.
    document.fonts?.ready.then(this.check)
    this.mutationObserver = new MutationObserver(this.check)
    this.mutationObserver.observe(document.body, { attributes: true, attributeFilter: ["class"] })

    this.check()
  }

  disconnect() {
    window.removeEventListener("resize", this.check)
    this.mutationObserver?.disconnect()
  }

  check() {
    if (!this.hasButtonTarget || !this.hasContentTarget) return

    const overLimit = this.isOverLimit()
    this.isCollapsible = this.alwaysToggleValue || overLimit

    if (this.isCollapsible) {
      this.buttonTarget.hidden = false
      if (this.hasStaticTarget) this.staticTarget.hidden = true

      const isCollapsed = this.userToggled ? this.userCollapsed : overLimit
      this.element.classList.toggle("collapsed", isCollapsed)
      this.buttonTarget.setAttribute("aria-expanded", String(!isCollapsed))
    } else {
      this.userToggled = false
      this.element.classList.remove("collapsed")
      this.buttonTarget.hidden = true
      if (this.hasStaticTarget) this.staticTarget.hidden = false
    }
  }

  toggle() {
    if (!this.isCollapsible) return

    const isCollapsed = this.element.classList.toggle("collapsed")
    this.userToggled = true
    this.userCollapsed = isCollapsed
    this.buttonTarget.setAttribute("aria-expanded", String(!isCollapsed))
  }

  isOverLimit() {
    if (this.hasMaxRowsValue) return this.rowCount() > this.maxRowsValue
    if (this.hasMaxHeightValue) return this.expandedHeight() > this.maxHeightValue
    return false
  }

  // Временно раскрываем блок, чтобы измерить его в полном виде.
  expandedHeight() {
    const wasCollapsed = this.element.classList.contains("collapsed")
    this.element.classList.remove("collapsed")
    const height = this.element.getBoundingClientRect().height
    if (wasCollapsed) this.element.classList.add("collapsed")
    return height
  }

  rowCount() {
    const wasCollapsed = this.element.classList.contains("collapsed")
    this.element.classList.remove("collapsed")

    const rows = []
    for (const item of this.contentTarget.children) {
      if (item.getClientRects().length === 0) continue
      const top = item.getBoundingClientRect().top
      if (!rows.some((rowTop) => Math.abs(rowTop - top) <= 4)) rows.push(top)
    }

    if (wasCollapsed) this.element.classList.add("collapsed")
    return rows.length
  }
}
