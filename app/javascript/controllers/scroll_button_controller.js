import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Добавляем класс по умолчанию при инициализации
    this.element.classList.add('scroll-down')
    this.threshold = 2000

    // Используем passive: true для оптимизации производительности скролла
    this.onScroll = this.onScroll.bind(this)
    window.addEventListener('scroll', this.onScroll, { passive: true })

    // Инициализируем состояние на случай, если страница уже загружена со скроллом
    this.onScroll()
  }

  disconnect() {
    window.removeEventListener('scroll', this.onScroll)
  }

  onScroll() {
    if (window.scrollY > this.threshold) {
      this.element.classList.remove('scroll-down')
      this.element.classList.add('scroll-up')
    } else {
      this.element.classList.remove('scroll-up')
      this.element.classList.add('scroll-down')
    }
  }

  scrollToTarget(event) {
    event.preventDefault()

    if (window.scrollY > this.threshold) {
      // Если ниже порога - прокрутка наверх
      window.scrollTo({
        top: 0,
        behavior: 'smooth'
      })
    } else {
      // Если выше порога - прокрутка вниз
      window.scrollTo({
        top: document.body.scrollHeight,
        behavior: 'smooth'
      })
    }
  }
}
