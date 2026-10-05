import { Controller } from "@hotwired/stimulus"

// Показывает/скрывает блок по id (например, форму пункта меню) и ставит фокус в первое поле.
// <button data-action="reveal#toggle" data-reveal-id-param="menu-edit-5">
export default class extends Controller {
  toggle(event) {
    const panel = document.getElementById(event.params.id)
    if (!panel) return

    panel.hidden = !panel.hidden
    if (!panel.hidden) panel.querySelector("input:not([type=hidden]), select, textarea")?.focus()
  }

  hide(event) {
    document.getElementById(event.params.id)?.setAttribute("hidden", "")
  }
}
