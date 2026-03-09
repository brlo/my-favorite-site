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
