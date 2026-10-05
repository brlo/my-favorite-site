import { Controller } from "@hotwired/stimulus"

// Редактирование профиля в чате: превью "как вас видят в чате", выбор фото по клику на аватар,
// счётчики символов. Всё проверяется и на сервере.
export default class extends Controller {
  static targets = ["avatar", "previewAvatar", "file", "remove", "removeBtn", "error",
                    "nickname", "nicknameCounter", "bio", "bioCounter", "previewNick"]
  static values = { maxSize: Number, color: String, tooBig: String }

  connect() {
    this.update()
  }

  disconnect() {
    if (this.objectUrl) URL.revokeObjectURL(this.objectUrl)
  }

  openPicker() {
    this.fileTarget.click()
  }

  pickFile() {
    const file = this.fileTarget.files[0]
    this.showError(null)
    if (!file) return

    if (file.size > this.maxSizeValue) {
      this.fileTarget.value = ""
      this.showError(this.tooBigValue)
      return
    }

    if (this.objectUrl) URL.revokeObjectURL(this.objectUrl)
    this.objectUrl = URL.createObjectURL(file)
    this.removeTarget.value = "0"
    this.removeBtnTarget.hidden = false
    this.renderAvatar(this.objectUrl)
  }

  removeAvatar() {
    this.fileTarget.value = ""
    this.removeTarget.value = "1"
    this.removeBtnTarget.hidden = true
    this.renderAvatar(null)
  }

  update() {
    const nick = this.nicknameTarget.value.trim()
    this.previewNickTarget.textContent = nick || "…"
    this.nicknameCounterTarget.textContent = `${this.nicknameTarget.value.length}/32`
    this.bioCounterTarget.textContent = `${this.bioTarget.value.length}/500`

    // буква в аватаре без фото следует за ником
    this.element.querySelectorAll(".chat-avatar--letter").forEach(el => {
      el.textContent = (nick[0] || "?").toUpperCase()
    })
  }

  renderAvatar(url) {
    const build = (large) => {
      let el
      if (url) {
        el = document.createElement("img")
        el.src = url
        el.alt = ""
      } else {
        el = document.createElement("span")
        el.classList.add("chat-avatar--letter")
        el.style.background = this.colorValue
        el.textContent = (this.nicknameTarget.value.trim()[0] || "?").toUpperCase()
      }
      el.classList.add("chat-avatar")
      if (large) el.classList.add("chat-avatar--large")
      return el
    }
    this.avatarTarget.replaceChildren(build(true))
    this.previewAvatarTarget.replaceChildren(build(false))
  }

  showError(text) {
    this.errorTarget.hidden = !text
    this.errorTarget.textContent = text || ""
  }
}
