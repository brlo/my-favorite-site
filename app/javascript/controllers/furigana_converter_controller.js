import { Controller } from "@hotwired/stimulus"
import { convertToRuby } from 'lib/tools'

// Фуригана: 漢字[かんじ] -> <ruby>. Раньше конвертер брал el.textContent и
// перезаписывал innerHTML, из-за чего пропадали <j> (слова Христа), <mo>
// (слова Богородицы) и сноски-звёздочки. Теперь обходим текстовые узлы:
// разметка остаётся, меняется только текст внутри неё.
export default class extends Controller {
  connect() {
    this.convert()
  }

  convert() {
    const elements = this.element.querySelectorAll('.verse-text, .zero-verse, .furigana-text')

    elements.forEach(el => {
      if (el.dataset.rubyConverted) return
      if (!el.textContent.includes('[')) return

      let isChanged = false
      const walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT)
      const textNodes = []
      while (walker.nextNode()) textNodes.push(walker.currentNode)

      textNodes.forEach(node => {
        const text = node.nodeValue
        if (!text.includes('[')) return

        const converted = convertToRuby(text)
        if (converted === text) return

        const holder = document.createElement('span')
        holder.innerHTML = converted
        node.replaceWith(...holder.childNodes)
        isChanged = true
      })

      if (isChanged) el.dataset.rubyConverted = 'true'
    })
  }
}
