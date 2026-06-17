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

# ОБЯЗАТЕЛЬНО ДЕЛАЙ ПОСЛЕ ИЗМЕНЕНИЯ СПИСКА, чтобы у пользователей работало без VPN
# подключить в importmap, предварительно скачав к себе:
# bin/importmap pin @tiptap/core @tiptap/starter-kit @tiptap/extension-typography @tiptap/extension-underline @tiptap/extension-link @tiptap/extension-highlight @tiptap/extension-image @tiptap/extension-table  --preload --from jsdelivr
# скачать заново всё:
# bin/importmap pristine
#
# Так как с предыдущими пунктами была куча багов, упаковал всё в один локальный файл.
# см. команды для сборки в app/javascript/tiptap_bundle.js
pin "tiptap_bundle", to: "tiptap_bundle.js"

pin "@rails/actioncable", to: "actioncable.esm.js"
pin_all_from "app/javascript/channels", under: "channels"
