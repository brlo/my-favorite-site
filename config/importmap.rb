# Pin npm packages by running ./bin/importmap
# bin/importmap pin choices

pin "application"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
# так можно будет обращаться в любую папку в app/javascript, сразу начиная с имени внутренней папки: controllers, lib, services
pin_all_from "app/javascript"
# pin_all_from "app/javascript/controllers", under: "controllers"
# pin_all_from "app/javascript/lib", under: "lib"
# pin_all_from "app/javascript/services", under: "services"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
# curl -o vendor/javascript/axios.js https://cdn.jsdelivr.net/npm/axios@1.13.2/dist/esm/axios.min.js
pin "axios", to: "axios.js" # to: "https://cdn.jsdelivr.net/npm/axios@1.13.2/dist/esm/axios.min.js"
pin "colors" # @0.6.2
pin "process" # @2.1.0
pin "choices.js" # @11.1.0

# Основные пакеты
pin "@tiptap/core", to: "https://esm.sh/@tiptap/core"
pin "@tiptap/starter-kit", to: "https://esm.sh/@tiptap/starter-kit"

# Расширения
pin "@tiptap/extension-typography", to: "https://esm.sh/@tiptap/extension-typography"
pin "@tiptap/extension-underline", to: "https://esm.sh/@tiptap/extension-underline"
pin "@tiptap/extension-highlight", to: "https://esm.sh/@tiptap/extension-highlight"
pin "@tiptap/extension-image", to: "https://esm.sh/@tiptap/extension-image"
pin "@tiptap/extension-link", to: "https://esm.sh/@tiptap/extension-link"
pin "@tiptap/extension-table", to: "https://esm.sh/@tiptap/extension-table"
pin "@tiptap/extension-ordered-list", to: "https://esm.sh/@tiptap/extension-ordered-list"

# pin "@tiptap/core", to: "tiptap/core/dist/index.js"
# pin "@tiptap/starter-kit", to: "tiptap/starter-kit/dist/index.js"
# pin "@tiptap/extension-typography", to: "tiptap/extension-typography/dist/index.js"
# pin "@tiptap/extension-underline", to: "tiptap/extension-underline/dist/index.js"
# pin "@tiptap/extension-link", to: "tiptap/extension-link/dist/index.js"
# pin "@tiptap/extension-highlight", to: "tiptap/extension-highlight/dist/index.js"
# pin "@tiptap/extension-image", to: "tiptap/extension-image/dist/index.js"
# pin "@tiptap/extension-table", to: "tiptap/extension-table/dist/index.js"

# Локальный кастомный список
pin "tiptap/custom_list", to: "tiptap/custom_list.js"
