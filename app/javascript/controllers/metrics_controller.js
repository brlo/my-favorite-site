import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.debug = false;
    this.isFired = false
    this.setupScrollListener()
    this.log("Metrics controller connected")
    this.scrollDelay = 1000;
    this.yandexId = 90555809
  }

  disconnect() {
    // Очищаем слушатель при удалении контроллера
    if (this.scrollHandler) {
      window.removeEventListener('scroll', this.scrollHandler)
    }
  }

  setupScrollListener() {
    this.scrollHandler = this.handleScroll.bind(this)
    window.addEventListener('scroll', this.scrollHandler, { passive: true })
  }

  handleScroll() {
    if (this.isFired) return

    this.isFired = true
    this.log("Scroll detected, scheduling metrics load")

    setTimeout(() => {
      this.loadYandexMetrica()
    }, this.scrollDelay)
  }

  loadYandexMetrica() {
    // Проверяем, не загружена ли уже метрика
    if (document.querySelector('script[src="https://mc.yandex.ru/metrika/tag.js"]')) {
      this.log("Yandex Metrica already loaded")
      return
    }

    this.log("Loading Yandex Metrica...")

    // Создаем функцию ym, если её ещё нет
    window.ym = window.ym || function() {
      (window.ym.a = window.ym.a || []).push(arguments)
    }
    window.ym.l = 1 * new Date()

    // Загружаем скрипт
    const script = document.createElement('script')
    script.src = 'https://mc.yandex.ru/metrika/tag.js'
    script.async = true
    script.onload = () => this.initYandexMetrica()
    script.onerror = () => this.log('Failed to load Yandex Metrica', 'error')

    document.head.appendChild(script)
  }

  initYandexMetrica() {
    if (!this.yandexId) {
      this.log('Yandex Metrica ID not provided', 'warn')
      return
    }

    this.log(`Initializing Yandex Metrica with ID: ${this.yandexId}`)

    window.ym(this.yandexId, 'init', {
      clickmap: true,
      trackLinks: true,
      accurateTrackBounce: true,
      webvisor: false // можно включить при необходимости
    })

    // Диспатчим событие о загрузке метрики
    window.dispatchEvent(new CustomEvent('metrics:loaded', {
      detail: { type: 'yandex', id: this.yandexId }
    }))
  }

  log(message, level = 'info') {
    if (this.debug) {
      const prefix = '🔍 [Metrics]'
      if (level === 'error') console.error(prefix, message)
      else if (level === 'warn') console.warn(prefix, message)
      else console.log(prefix, message)
    }
  }
}
