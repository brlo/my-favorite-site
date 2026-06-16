
import { OrderedList } from "tiptap/tiptap_bundle"

export const CustomList = OrderedList.extend({
  name: 'orderedList',
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
