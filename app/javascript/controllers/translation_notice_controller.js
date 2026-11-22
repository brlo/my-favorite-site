import { Controller } from "@hotwired/stimulus"

// Подсказка к бейджу «ИИ + человек».
// Держим её в position: fixed и прижимаем к краям экрана, чтобы длинный
// текст не растягивал страницу на узких экранах.
export default class extends Controller {
  static targets = ["trigger", "tooltip"]

  connect() {
    this.isOpen = false
    this.pointerType = "mouse"
    this.reposition = this.reposition.bind(this)
    this.closeOutside = this.closeOutside.bind(this)
    this.closeOnEscape = this.closeOnEscape.bind(this)
  }

  disconnect() {
    this.close()
  }

  show(event) {
    // фокус с клавиатуры показываем, фокус от тапа/клика мышью — нет
    if (event?.type === "focusin" && !this.triggerTarget.matches(":focus-visible")) return
    this.open()
  }

  hide() {
    this.close()
  }

  // наведение мышью/пером; тач обрабатываем через click, чтобы не мешали
  // синтетические mouseenter/mouseleave
  pointerEnter(event) {
    if (event.pointerType !== "mouse" && event.pointerType !== "pen") return
    this.pointerType = "mouse"
    this.element.classList.remove("is-touch")
    this.open()
  }

  pointerLeave(event) {
    if (event.pointerType !== "mouse" && event.pointerType !== "pen") return
    this.close()
  }

  pointerDown(event) {
    this.pointerType = event.pointerType || "mouse"
    this.element.classList.toggle("is-touch", this.pointerType !== "mouse")
  }

  toggle(event) {
    // на устройствах с мышью работает наведение, клик не должен её закрывать
    if (this.pointerType === "mouse" && event.detail > 0) return
    // клавиатурный клик (Enter/Space) уже показал подсказку через focus
    if (event.detail === 0 && this.isOpen) return

    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    if (this.isOpen) {
      this.reposition()
      return
    }

    this.isOpen = true
    this.element.classList.add("is-open")
    this.tooltipTarget.classList.add("is-open")
    this.triggerTarget.setAttribute("aria-expanded", "true")
    this.reposition()

    document.addEventListener("click", this.closeOutside)
    document.addEventListener("keydown", this.closeOnEscape)
    window.addEventListener("scroll", this.reposition, true)
    window.addEventListener("resize", this.reposition)
  }

  close() {
    if (!this.isOpen) return

    this.isOpen = false
    this.element.classList.remove("is-open")
    this.tooltipTarget.classList.remove("is-open", "is-above")
    this.triggerTarget.setAttribute("aria-expanded", "false")

    document.removeEventListener("click", this.closeOutside)
    document.removeEventListener("keydown", this.closeOnEscape)
    window.removeEventListener("scroll", this.reposition, true)
    window.removeEventListener("resize", this.reposition)
  }

  closeOutside(event) {
    if (this.element.contains(event.target)) return
    this.close()
  }

  closeOnEscape(event) {
    if (event.key === "Escape") this.close()
  }

  reposition() {
    if (!this.isOpen) return

    const triggerRect = this.triggerTarget.getBoundingClientRect()
    if (triggerRect.bottom < 0 || triggerRect.top > window.innerHeight) {
      this.close()
      return
    }

    const tooltipRect = this.tooltipTarget.getBoundingClientRect()
    const viewportWidth = document.documentElement.clientWidth
    const viewportHeight = window.innerHeight
    const padding = 8
    const gap = 6

    let left = triggerRect.left + triggerRect.width / 2 - tooltipRect.width / 2
    left = Math.min(Math.max(padding, left), Math.max(padding, viewportWidth - tooltipRect.width - padding))

    let top = triggerRect.bottom + gap
    let isAbove = false

    if (top + tooltipRect.height > viewportHeight - padding && triggerRect.top - gap - tooltipRect.height >= padding) {
      top = triggerRect.top - gap - tooltipRect.height
      isAbove = true
    }

    // если подсказка не помещается ни снизу, ни сверху — прижимаем к нижнему краю
    top = Math.min(top, viewportHeight - tooltipRect.height - padding)

    this.tooltipTarget.classList.toggle("is-above", isAbove)
    this.tooltipTarget.style.left = `${Math.round(left)}px`
    this.tooltipTarget.style.top = `${Math.round(top)}px`

    const arrowLeft = Math.min(
      Math.max(16, triggerRect.left + triggerRect.width / 2 - left),
      tooltipRect.width - 16
    )
    this.tooltipTarget.style.setProperty("--arrow-left", `${Math.round(arrowLeft)}px`)
  }
}
