import { Controller } from "@hotwired/stimulus"
import { Editor, StarterKit, Typography, Underline, Link, Highlight, Image, TableKit } from "tiptap/tiptap_bundle"
import { CustomList } from "tiptap/custom_list"
import { ArticleCut } from "tiptap/article_cut"

export default class extends Controller {
  static targets = ["field", "editor"]
  static values = {
    initialContent: String
  }

  connect() {
    this.editor = new Editor({
      element: this.editorTarget,
      extensions: [
        StarterKit.configure({
          orderedList: false, // Отключаем стандартный, используем CustomList
          heading: {
            levels: [2, 3, 4],
          },
        }),
        CustomList,
        Typography,
        Underline,
        Highlight,
        Image,
        Link.configure({
          openOnClick: false,
          HTMLAttributes: {
            rel: null,
            target: null
          },
        }),
        TableKit,
        ArticleCut
      ],
      content: this.initialContentValue || '<p></p>',

      // При каждом изменении обновляем скрытое поле формы
      onUpdate: ({ editor }) => {
        this.fieldTarget.value = editor.getHTML()
        this.refreshArticleCutState()
      },

      // Аналог вашего onBlur с emit('change')
      onBlur: ({ editor }) => {
        this.fieldTarget.value = editor.getHTML()
        // Если нужно триггерить событие для других контроллеров:
        this.dispatch('change', { detail: { html: editor.getHTML() } })
      },

      onSelectionUpdate: () => this.refreshArticleCutState()
    })

    // Делаем editor доступным для кнопок тулбара
    this.element.editor = this.editor
    this.refreshArticleCutState()
  }

  disconnect() {
    if (this.editor) {
      this.editor.destroy()
    }
  }

  // === Методы для кнопок тулбара ===

  // Универсальный метод для простых команд
  execute(event) {
    const command = event.currentTarget.dataset.command
    const params = event.currentTarget.dataset.params

    if (!this.editor || !command) return

    let chain = this.editor.chain().focus()

    // Разбираем параметры, если они есть (например, toggleHeading с level)
    if (params) {
      try {
        const parsedParams = JSON.parse(params)
        chain = chain[command](parsedParams)
      } catch (e) {
        chain = chain[command](params)
      }
    } else {
      chain = chain[command]()
    }

    chain.run()
  }

  // Специальные методы для сложных команд
  setLink() {
    const previousUrl = this.editor.getAttributes('link').href
    const url = window.prompt('URL', previousUrl)

    if (url === null) return
    if (url === '') {
      this.editor.chain().focus().extendMarkRange('link').unsetLink().run()
      return
    }
    this.editor.chain().focus().extendMarkRange('link').setLink({ href: url }).run()
  }

  addImage() {
    const url = window.prompt('URL')
    if (url) {
      this.editor.chain().focus().setImage({ src: url }).run()
    }
  }

  setListStartNumber() {
    const startNum = window.prompt('Введите номер, с которого должен начинаться список')
    if (startNum) {
      this.editor.chain().focus().updateAttributes('orderedList', { start: parseInt(startNum) }).run()
    }
  }

  // === Место деления статьи (аналог habracut) ===

  // Ставит метку деления в позицию курсора, а если она уже стоит — убирает её
  toggleArticleCut() {
    if (!this.editor) return
    const cutType = this.editor.schema.nodes.articleCut
    if (!cutType) return

    const existing = this.findArticleCutPos()
    if (existing !== null) {
      this.editor.chain().focus().deleteRange({ from: existing, to: existing + 1 }).run()
      return
    }

    const pos = this.articleCutInsertPos()
    this.editor.view.dispatch(this.editor.state.tr.replaceWith(pos, pos, cutType.create()).scrollIntoView())
    this.editor.view.focus()
  }

  // Позиция уже стоящей метки деления или null
  findArticleCutPos() {
    if (!this.editor) return null
    const cutType = this.editor.schema.nodes.articleCut
    let found = null

    this.editor.state.doc.descendants((node, pos) => {
      if (found !== null) return false
      if (node.type === cutType) {
        found = pos
        return false
      }
      return true
    })

    return found
  }

  // Куда поставить метку: в позицию курсора; внутри цитаты, списка или таблицы —
  // после этого блока на верхнем уровне, чтобы метка не оказалась вложенной в разметку
  articleCutInsertPos() {
    const { $from } = this.editor.state.selection

    if ($from.depth > 1) return $from.after(1)
    if ($from.depth === 1 && $from.parent.isTextblock) {
      if ($from.parentOffset === 0) return $from.before(1)
      if ($from.parentOffset === $from.parent.content.size) return $from.after(1)
    }
    return $from.pos
  }

  // Кнопка в тулбаре подсвечивается, когда метка деления стоит в тексте
  refreshArticleCutState() {
    const button = this.element.querySelector('[data-tiptap-role="article-cut"]')
    if (!button) return

    const hasCut = this.findArticleCutPos() !== null
    button.classList.toggle('active', hasCut)
    button.setAttribute('aria-pressed', hasCut ? 'true' : 'false')
  }

  // Вспомогательный метод для проверки активности (используется в view)
  isActive(name, attrs = {}) {
    return this.editor?.isActive(name, attrs) || false
  }
}
