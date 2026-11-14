import { Controller } from "@hotwired/stimulus"

// Живое превью заголовка поверх обложки: цвета из полей применяются к превью до сохранения формы
export default class extends Controller {
  static targets = ["bgText", "textText", "bgPicker", "textPicker", "overlay", "caption"]

  connect() {
    this.refresh()
  }

  // ввод hex в текстовое поле
  type() {
    this.refresh()
  }

  // выбор цвета в нативном picker'е
  pick(event) {
    this[`${event.params.field}TextTarget`].value = event.target.value
    this.refresh()
  }

  // отказ от цвета: пустое поле = цвет не задан
  clear(event) {
    this[`${event.params.field}TextTarget`].value = ""
    this.refresh()
  }

  refresh() {
    const bg = this.colorValue(this.bgTextTarget.value)
    const text = this.colorValue(this.textTextTarget.value)

    if (bg) {
      const [r, g, b] = this.rgb(bg)
      this.overlayTarget.style.background =
        `linear-gradient(to top, rgba(${r}, ${g}, ${b}, 0.85) 0%, rgba(${r}, ${g}, ${b}, 0) 55%)`
      this.overlayTarget.classList.remove("is-off")
      this.bgPickerTarget.value = this.toSixDigits(bg)
    } else {
      this.overlayTarget.classList.add("is-off")
    }

    this.captionTarget.style.color = text || "#ffffff"
    if (text) this.textPickerTarget.value = this.toSixDigits(text)
  }

  colorValue(value) {
    value = value.trim().toLowerCase()
    if (value === "") return null
    if (!value.startsWith("#")) value = `#${value}`
    return /^#([0-9a-f]{3}|[0-9a-f]{6})$/.test(value) ? value : null
  }

  rgb(hex) {
    const six = this.toSixDigits(hex)
    return [0, 2, 4].map((i) => parseInt(six.slice(i + 1, i + 3), 16))
  }

  // picker принимает только #rrggbb
  toSixDigits(hex) {
    if (hex.length === 4) return `#${hex[1]}${hex[1]}${hex[2]}${hex[2]}${hex[3]}${hex[3]}`
    return hex
  }
}
