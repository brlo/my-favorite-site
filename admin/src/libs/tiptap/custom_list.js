import OrderedList from '@tiptap/extension-ordered-list';

// Позволяет изменять номер, с которого начинается нумерованый списк (ol start=3)
const CustomList = OrderedList.extend({
  addAttributes() {
    return {
      ...this.parent?.(),
      start: {
        default: 1,
        parseHTML: (element) => element.hasAttribute('start') ? parseInt(element.getAttribute('start'), 10) : 1,
        renderHTML: (attributes) => {
          if (attributes.start === 1) {
            return {};
          }

          return { start: attributes.start };
        },
      },
    };
  },
});

export { CustomList }
