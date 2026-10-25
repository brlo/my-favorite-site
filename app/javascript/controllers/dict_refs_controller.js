import { Controller } from "@hotwired/stimulus"

// Сноски в статьях словаря: <abbr title="5th c.BC: Herodotus 1.24">Refs 5th c.BC+</abbr>.
// На телефонах title не всплывает, поэтому по клику раскрываем текст сноски прямо в строке (повторный клик - прячем).
// <div data-controller="dict-refs" data-action="click->dict-refs#toggle">
export default class extends Controller {
  toggle(event) {
    const abbr = event.target.closest("abbr[title]")
    if (!abbr) return

    const opened = abbr.nextElementSibling
    if (opened?.classList.contains("abbr-text")) {
      opened.remove()
      return
    }

    const text = document.createElement("span")
    text.className = "abbr-text"
    text.textContent = abbr.title
    abbr.after(text)
  }
}
