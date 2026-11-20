import { Node, mergeAttributes } from "tiptap/tiptap_bundle"

// Метка места деления статьи (аналог habracut): текст выше неё показывается до оглавления.
// В сохраняемом HTML — <hr class="article-cut">: hr и class разрешены санитайзером Page
// (Page::ALLOW_TAGS/ALLOW_ATTRS), по этому классу Page::HtmlRenderer делит текст на две части.
export const ArticleCut = Node.create({
  name: 'articleCut',
  group: 'block',
  atom: true,
  selectable: true,

  parseHTML() {
    // приоритет выше, чем у стандартного horizontalRule с его tag: 'hr'
    return [{ tag: 'hr.article-cut', priority: 60 }]
  },

  renderHTML({ HTMLAttributes }) {
    return ['hr', mergeAttributes(HTMLAttributes, { class: 'article-cut' })]
  },

  // В редакторе показываем не пустую линию, а заметную подпись
  addNodeView() {
    return () => {
      const dom = document.createElement('div')
      dom.className = 'article-cut-marker'
      dom.setAttribute('contenteditable', 'false')
      dom.textContent = '✂ Место деления — выше текст показывается до оглавления'
      return { dom }
    }
  },
})
