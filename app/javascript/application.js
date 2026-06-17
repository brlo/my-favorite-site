// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// import "./old/first_needs"


// --- ГЛОБАЛЬНАЯ ОБРАБОТКА ОШИБОК TURBO ---

// // 1. Ошибка сети, таймаут или 500 от сервера
// document.addEventListener("turbo:fetch-error", (event) => {
//   showToast("Проблемы с соединением. Проверьте интернет.", "error")
// })

// // 2. Сервер вернул не тот HTML (например, редирект на логин вместо фрейма)
// document.addEventListener("turbo:frame-missing", (event) => {
//   const { response, visit } = event.detail

//   if (response.redirected) {
//     // Разрешаем Turbo перейти на новую страницу целиком
//     // visit(response.url)
//     showToast("Произошла непредвиденная ошибка. Обновите страницу.", "error")
//   } else {
//     showToast("Произошла непредвиденная ошибка. Обновите страницу.", "error")
//     event.preventDefault()
//   }
// })

// // 3. Перехват глобальных 500/404 ошибок (если они не пойманы fetch-error)
// document.addEventListener("turbo:before-fetch-response", (event) => {
//   const fetchResponse = event.detail.fetchResponse
//   if (fetchResponse.statusCode >= 500) {
//     // Можно показать тост, но лучше позволить браузеру показать стандартную страницу ошибки
//     // или сделать кастомную логику
//   }
// })

// // --- ВСПОМОГАТЕЛЬНАЯ ФУНКЦИЯ ДЛЯ ТОСТОВ ---
// function showToast(message, type = "info") {
//   // const container = document.querySelector(".flash-messages")
//   // if (!container) return

//   // const toast = document.createElement("div")
//   // toast.className = `toast toast-${type} p-4 bg-red-500 text-white rounded shadow-lg transition-opacity duration-500`
//   // toast.textContent = message
//   // toast.setAttribute("data-flash-toast", "")

//   // container.prepend(toast)

//   // // Автоудаление
//   // setTimeout(() => {
//   //   toast.classList.add('opacity-0')
//   //   setTimeout(() => toast.remove(), 100)
//   // }, 3000)
// }
