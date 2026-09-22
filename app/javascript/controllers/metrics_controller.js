import { Controller } from "@hotwired/stimulus"

// Состояние на уровне модуля — живёт между экземплярами контроллера
let isMetricaFired = false
let metricaLoaded = false

export default class extends Controller {
  connect() {
    this.debug = false;
    this.setupScrollListener()
    this.log("Metrics controller connected")
    this.scrollDelay = 1000;
    this.yandexId = 90555809

    // Подписываемся на turbo:load
    this.turboLoadHandler = this.handleTurboLoad.bind(this)
    document.addEventListener("turbo:load", this.turboLoadHandler)

    // Если скролл уже был до этого (например, до Turbo-перехода),
    //     но метрика ещё не загружена — загрузим сразу
    if (isMetricaFired && !metricaLoaded) {
      this.loadYandexMetrica()
    }
  }

  disconnect() {
    if (this.scrollHandler) {
      window.removeEventListener('scroll', this.scrollHandler)
    }
    if (this.turboLoadHandler) {
      document.removeEventListener("turbo:load", this.turboLoadHandler)
    }
  }

  setupScrollListener() {
    this.scrollHandler = this.handleScroll.bind(this)
    window.addEventListener('scroll', this.scrollHandler, { passive: true })
  }

  handleScroll() {
    if (isMetricaFired) return

    isMetricaFired = true
    this.log("Scroll detected, scheduling metrics load")

    setTimeout(() => {
      this.loadYandexMetrica()
    }, this.scrollDelay)
  }

  handleTurboLoad() {
    this.log(`turbo:load fired. isMetricaFired=${isMetricaFired}, metricaLoaded=${metricaLoaded}`)

    if (!isMetricaFired) {
      this.log("Metrica not fired yet, skipping hit")
      return
    }

    if (typeof window.ym === 'function') {
      this.log(`Sending hit to Metrica for: ${window.location.href}`)
      window.ym(this.yandexId, 'hit', window.location.href, {
        title: document.title,
        referer: document.referrer
      })
    }
  }

  loadYandexMetrica() {
    if (metricaLoaded) {
      this.log("Yandex Metrica already loaded")
      return
    }
    if (document.querySelector('script[src="https://mc.yandex.ru/metrika/tag.js"]')) {
      this.log("Yandex Metrica script already in DOM")
      metricaLoaded = true
      return
    }

    this.log("Loading Yandex Metrica...")

    window.ym = window.ym || function() {
      (window.ym.a = window.ym.a || []).push(arguments)
    }
    window.ym.l = 1 * new Date()

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
      webvisor: false
    })

    metricaLoaded = true

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
