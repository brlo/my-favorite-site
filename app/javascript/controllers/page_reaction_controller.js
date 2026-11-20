import { Controller } from "@hotwired/stimulus"

// Выбор положительной реакции на статью. Форма отправляется обычным POST
// (в ней есть CSRF-токен), ответ приходит JSON — обновляем счётчики и активный
// вид без перезагрузки. Без submitter'а не мешаем обычной отправке формы.
export default class extends Controller {
  static targets = ["choice"]

  submit(event) {
    const kind = event.submitter?.value
    if (!kind) return

    event.preventDefault()
    if (this.busy) return

    const form = this.element
    this.busy = true
    this.choiceTargets.forEach((button) => { button.disabled = true })

    const data = new FormData(form)
    data.append("kind", kind)

    fetch(form.action, {
      method: "POST",
      body: data,
      headers: { Accept: "application/json" },
      credentials: "same-origin"
    })
      .then((response) => {
        if (!response.ok) throw new Error(`HTTP ${response.status}`)
        return response.json()
      })
      .then((payload) => this.render(payload))
      .catch(() => {
        // Если JSON не пришёл, отправляем форму обычным способом,
        // сохранив выбранный вид реакции
        let input = form.querySelector('input[data-kind-fallback]')
        if (!input) {
          input = document.createElement("input")
          input.type = "hidden"
          input.name = "kind"
          input.dataset.kindFallback = "1"
          form.appendChild(input)
        }
        input.value = kind
        form.submit()
      })
      .finally(() => {
        this.busy = false
        this.choiceTargets.forEach((button) => { button.disabled = false })
      })
  }

  render(payload) {
    this.choiceTargets.forEach((button) => {
      const kind = button.dataset.kind
      const count = (payload.counts || {})[kind] || 0
      const countElement = button.querySelector(".page-reaction__count")
      if (countElement) {
        countElement.textContent = count
        countElement.hidden = count === 0
      }

      const label = button.dataset.label
      if (label) button.setAttribute("aria-label", `${label} (${count})`)

      const active = payload.active === kind
      button.classList.toggle("is-active", active)
      button.classList.toggle("is-empty", count === 0)
      button.setAttribute("aria-pressed", active ? "true" : "false")
    })
  }
}
