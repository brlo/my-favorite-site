import { Controller } from "@hotwired/stimulus"

// Поле с выпадающими подсказками с сервера.
// Сервер отдаёт [{title: "...", hint: "...", <key>: "..."}].
//
// Два режима:
// - есть target "value" (скрытое поле): в видимом поле — название, в форму уходит item[key] (например, id статьи);
// - нет target "value": в видимое поле подставляется item[key] (например, path статьи или слово).
// Разметку см. AdminHelper#admin_combobox.
export default class extends Controller {
  static targets = ["input", "value", "list", "note"]
  static values = {
    url: String,
    key: String,
    minLength: { type: Number, default: 2 },
  }

  connect() {
    this.items = []
    this.active = -1
    this.selectedLabel = this.inputTarget.value
  }

  disconnect() {
    clearTimeout(this.timeout)
    clearTimeout(this.blurTimeout)
    this.abortController?.abort()
  }

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.fetchItems(), 250)
  }

  keydown(event) {
    if (this.listTarget.hidden) {
      if (event.key === "ArrowDown") this.fetchItems()
      return
    }

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.highlight(Math.min(this.active + 1, this.items.length - 1))
        break
      case "ArrowUp":
        event.preventDefault()
        this.highlight(Math.max(this.active - 1, 0))
        break
      case "Enter":
        // не отправляем форму, пока открыт список
        event.preventDefault()
        if (this.active >= 0) this.select(this.active)
        break
      case "Escape":
        event.preventDefault()
        this.close()
        break
    }
  }

  blur() {
    this.blurTimeout = setTimeout(() => {
      this.close()
      if (!this.hasValueTarget) return

      // в режиме id вручную набранный текст без выбора из списка не сохраняем
      if (this.inputTarget.value.trim() === "") {
        this.setValue("", "")
      } else {
        this.inputTarget.value = this.selectedLabel
      }
    }, 150)
  }

  clear() {
    this.setValue("", "")
    this.inputTarget.value = ""
    this.inputTarget.focus()
  }

  async fetchItems() {
    const term = this.inputTarget.value.trim()
    if (term.length < this.minLengthValue) return this.close()

    this.abortController?.abort()
    this.abortController = new AbortController()

    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set("term", term)

    try {
      const response = await fetch(url, {
        headers: { Accept: "application/json" },
        signal: this.abortController.signal,
      })
      if (!response.ok) return
      this.items = await response.json()
      this.render()
    } catch (e) {
      if (e.name !== "AbortError") console.error(e)
    }
  }

  render() {
    this.active = -1

    if (this.items.length === 0) {
      const empty = document.createElement("li")
      empty.className = "combobox-empty"
      empty.textContent = "Ничего не найдено"
      this.listTarget.replaceChildren(empty)
    } else {
      this.listTarget.replaceChildren(...this.items.map((item, i) => {
        const li = document.createElement("li")
        li.setAttribute("role", "option")
        const title = document.createElement("div")
        title.textContent = item.title ?? item[this.keyValue]
        li.append(title)
        if (item.hint) {
          const hint = document.createElement("div")
          hint.className = "combobox-hint"
          hint.textContent = item.hint
          li.append(hint)
        }
        // mousedown, а не click: иначе blur поля закроет список раньше
        li.addEventListener("mousedown", (e) => { e.preventDefault(); this.select(i) })
        li.addEventListener("mouseenter", () => this.highlight(i))
        return li
      }))
    }

    this.listTarget.hidden = false
  }

  highlight(index) {
    this.active = index
    ;[...this.listTarget.children].forEach((li, i) => li.classList.toggle("active", i === index))
    this.listTarget.children[index]?.scrollIntoView({ block: "nearest" })
  }

  select(index) {
    const item = this.items[index]
    if (!item) return

    if (this.hasValueTarget) {
      this.inputTarget.value = item.title
      this.setValue(item[this.keyValue], item.title, item.hint)
    } else {
      this.inputTarget.value = item[this.keyValue] ?? ""
      this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
    }
    this.close()
  }

  setValue(value, label, note = "") {
    this.selectedLabel = label
    this.valueTarget.value = value ?? ""
    this.valueTarget.dispatchEvent(new Event("change", { bubbles: true }))
    if (this.hasNoteTarget) this.noteTarget.textContent = note
  }

  close() {
    this.listTarget.hidden = true
    this.active = -1
  }
}
