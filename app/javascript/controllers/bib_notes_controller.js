import { Controller } from "@hotwired/stimulus"

// Сноски-звёздочки jp-box: подсказка не должна вылезать за экран.
// У слова в правой половине окна раскрываем подсказку влево, у нижней трети — вверх.
export default class extends Controller {
  connect() {
    this.onShow = this.onShow.bind(this)
    document.addEventListener("mouseover", this.onShow)
    document.addEventListener("focusin", this.onShow)
  }

  disconnect() {
    document.removeEventListener("mouseover", this.onShow)
    document.removeEventListener("focusin", this.onShow)
  }

  onShow(event) {
    const note = event.target.closest && event.target.closest(".bib-note")
    if (!note) return
    const rect = note.getBoundingClientRect()
    note.classList.toggle("tip-left", rect.left + rect.width / 2 > window.innerWidth / 2)
    note.classList.toggle("tip-up", rect.bottom > window.innerHeight * 0.6)
  }
}
