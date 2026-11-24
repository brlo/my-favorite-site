import { Controller } from "@hotwired/stimulus"

// Сноски-звёздочки jp-box: подсказка не должна вылезать за экран.
// Позиционируем её фиксированно по координатам звёздочки и прижимаем к краям
// окна с отступом; если сверху нет места — показываем снизу.
export default class extends Controller {
  connect() {
    this.tip = null
    this.current = null

    this.onOver = this.onOver.bind(this)
    this.onOut = this.onOut.bind(this)
    this.onFocusIn = this.onFocusIn.bind(this)
    this.onFocusOut = this.onFocusOut.bind(this)
    this.onDown = this.onDown.bind(this)
    this.onKey = this.onKey.bind(this)
    this.hide = this.hide.bind(this)

    document.addEventListener("pointerover", this.onOver, true)
    document.addEventListener("pointerout", this.onOut, true)
    document.addEventListener("focusin", this.onFocusIn, true)
    document.addEventListener("focusout", this.onFocusOut, true)
    document.addEventListener("pointerdown", this.onDown, true)
    document.addEventListener("keydown", this.onKey)
    window.addEventListener("scroll", this.hide, true)
    window.addEventListener("resize", this.hide)
  }

  disconnect() {
    document.removeEventListener("pointerover", this.onOver, true)
    document.removeEventListener("pointerout", this.onOut, true)
    document.removeEventListener("focusin", this.onFocusIn, true)
    document.removeEventListener("focusout", this.onFocusOut, true)
    document.removeEventListener("pointerdown", this.onDown, true)
    document.removeEventListener("keydown", this.onKey)
    window.removeEventListener("scroll", this.hide, true)
    window.removeEventListener("resize", this.hide)
    this.hide()
  }

  noteFrom(event) {
    const target = event.target
    return target && target.closest ? target.closest(".bib-note") : null
  }

  onOver(event) {
    const note = this.noteFrom(event)
    if (note && note !== this.current) this.show(note)
  }

  onOut(event) {
    if (event.pointerType === "touch") return
    const note = this.noteFrom(event)
    if (!note) return
    if (note.contains(event.relatedTarget)) return
    this.hide()
  }

  onFocusIn(event) {
    const note = this.noteFrom(event)
    if (note) this.show(note)
  }

  onFocusOut(event) {
    const note = this.noteFrom(event)
    if (!note) return
    if (note.contains(event.relatedTarget)) return
    this.hide()
  }

  // на тач-устройствах наведения нет: тап показывает/скрывает подсказку
  onDown(event) {
    if (event.pointerType !== "touch") return
    const note = this.noteFrom(event)
    if (!note) {
      this.hide()
      return
    }
    if (this.current === note) this.hide()
    else this.show(note)
  }

  onKey(event) {
    if (event.key === "Escape") this.hide()
  }

  show(note) {
    const text = note.dataset.tip
    if (!text) return

    this.hide()

    const tip = document.createElement("div")
    tip.className = "bib-note-tip"
    tip.setAttribute("role", "tooltip")
    tip.textContent = text
    document.body.appendChild(tip)

    this.tip = tip
    this.current = note
    this.place(note, tip)
  }

  place(note, tip) {
    const margin = 8
    const rect = note.getBoundingClientRect()
    const width = tip.offsetWidth
    const height = tip.offsetHeight

    let left = rect.left + rect.width / 2 - width / 2
    left = Math.min(Math.max(margin, left), window.innerWidth - width - margin)

    let top = rect.top - height - 10
    // сверху не помещается — показываем под звёздочкой
    if (top < margin) top = rect.bottom + 10
    top = Math.min(Math.max(margin, top), window.innerHeight - height - margin)

    tip.style.left = `${Math.round(left)}px`
    tip.style.top = `${Math.round(top)}px`
  }

  hide() {
    if (this.tip) {
      this.tip.remove()
      this.tip = null
    }
    this.current = null
  }
}
