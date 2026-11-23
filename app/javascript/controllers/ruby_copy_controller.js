import { Controller } from "@hotwired/stimulus"
import { replaceRubyWithText } from "lib/tools"

// При обычном копировании (Ctrl+C / контекстное меню) отдаём фуригану в виде «漢字[かんじ]»,
// а не «漢字かんじ» или одним основанием без чтения.
export default class extends Controller {
  copy(event) {
    const selection = window.getSelection()
    if (!selection || selection.isCollapsed || !event.clipboardData) return
    if (!this.element.contains(selection.anchorNode) || !this.element.contains(selection.focusNode)) return

    const range = selection.getRangeAt(0)
    const fragment = range.cloneContents()
    if (!fragment.querySelector || !fragment.querySelector('ruby')) return

    const div = document.createElement('div')
    div.appendChild(fragment)
    replaceRubyWithText(div)

    // временно в DOM, чтобы innerText сохранил переносы строк таблицы/абзацев
    div.style.position = 'fixed'
    div.style.left = '-10000px'
    div.style.top = '0'
    document.body.appendChild(div)
    const text = div.innerText
    const html = div.innerHTML
    div.remove()

    event.clipboardData.setData('text/plain', text)
    event.clipboardData.setData('text/html', html)
    event.preventDefault()
  }
}
