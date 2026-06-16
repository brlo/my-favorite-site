import { Controller } from "@hotwired/stimulus"
import { Editor } from "@tiptap/core"
import StarterKit from "@tiptap/starter-kit"
import Typography from "@tiptap/extension-typography"
import Underline from "@tiptap/extension-underline"
import Link from "@tiptap/extension-link"
import Highlight from "@tiptap/extension-highlight"
import Image from "@tiptap/extension-image"
import { TableKit } from '@tiptap/extension-table'
import { CustomList } from "tiptap/custom_list"

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
        TableKit
      ],
      content: this.initialContentValue || '<p></p>',

      // При каждом изменении обновляем скрытое поле формы
      onUpdate: ({ editor }) => {
        this.fieldTarget.value = editor.getHTML()
      },

      // Аналог вашего onBlur с emit('change')
      onBlur: ({ editor }) => {
        this.fieldTarget.value = editor.getHTML()
        // Если нужно триггерить событие для других контроллеров:
        this.dispatch('change', { detail: { html: editor.getHTML() } })
      }
    })

    // Делаем editor доступным для кнопок тулбара
    this.element.editor = this.editor
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

  // Вспомогательный метод для проверки активности (используется в view)
  isActive(name, attrs = {}) {
    return this.editor?.isActive(name, attrs) || false
  }
}
