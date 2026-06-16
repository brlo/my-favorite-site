// Для построения одного локального js-файла (бандла), который содержит всё необходимое для tiptap.
// Подготовка:
// npm install @tiptap/core @tiptap/starter-kit @tiptap/extension-typography @tiptap/extension-underline @tiptap/extension-link @tiptap/extension-highlight @tiptap/extension-image @tiptap/extension-table @tiptap/extension-ordered-list
// Сборка:
// npx esbuild app/javascript/tiptap_bundle.js --bundle --outfile=app/javascript/tiptap/tiptap_bundle.js --format=esm
// Итоговый бандл здесь:
// app/javascript/tiptap/tiptap_bundle.js

import { Editor } from '@tiptap/core'
import StarterKit from '@tiptap/starter-kit'
import Typography from '@tiptap/extension-typography'
import Underline from '@tiptap/extension-underline'
import Link from '@tiptap/extension-link'
import Highlight from '@tiptap/extension-highlight'
import Image from '@tiptap/extension-image'
import { TableKit } from '@tiptap/extension-table'
import OrderedList from '@tiptap/extension-ordered-list';

export {
  Editor,
  StarterKit,
  OrderedList,
  Typography,
  Underline,
  Link,
  Highlight,
  Image,
  TableKit
}
