import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  logout(event) {
    event.preventDefault()

    // Получаем CSRF-токен из meta-тега (стандарт для Rails)
    const csrfToken = document.querySelector("[name='csrf-token']")?.content

    fetch("/ru/logout/", {
      method: "DELETE",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken
      }
    })
    .then(response => {
      if (response.ok) {
        window.location.href = "/"
      } else {
        console.error("Logout failed:", response.status)
      }
    })
    .catch(error => {
      console.error("Logout error:", error)
    })
  }
}
