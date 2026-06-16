import OrderedList from "@tiptap/extension-ordered-list"

export const CustomList = OrderedList.extend({
  addAttributes() {
    return {
      ...this.parent?.(),
      start: {
        default: 1,
        parseHTML: element => {
          return parseInt(element.getAttribute('start')) || 1
        },
        renderHTML: attributes => {
          if (attributes.start === 1) return {}
          return { start: attributes.start }
        },
      },
    }
  },
})
