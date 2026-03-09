import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    page: Number
  }

  connect() {
    this.observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting && !this.isLoading) {
          this.loadMore()
        }
      })
    })
    this.observer.observe(this.element)
    this.isLoading = false
  }

  disconnect() {
    this.observer?.disconnect()
  }

  get spinnerElement() {
    return this.element.querySelector('.infinite-scroll-spinner')
  }

  showSpinner() {
    this.isLoading = true
    const spinner = this.spinnerElement
    if (spinner) spinner.hidden = false
  }

  hideSpinner() {
    this.isLoading = false
    const spinner = this.spinnerElement
    if (spinner) spinner.hidden = true
  }

  loadMore() {
    this.showSpinner()

    const nextPage = this.pageValue + 1
    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set('page', nextPage)

    fetch(url.toString(), {
      headers: { 'Accept': 'text/vnd.turbo-stream.html' }
    })
      .then(response => {
        if (!response.ok) {
          this.hideSpinner()
          this.disconnect()
          return null
        }
        return response.text()
      })
      .then(html => {
        this.hideSpinner()

        if (html === null || !html.trim()) {
          this.disconnect()
          return
        }

        // Опционально: проверка на наличие turbo-stream
        if (!/<turbo-stream/i.test(html)) {
          this.disconnect()
          return
        }

        return Turbo.renderStreamMessage(html)
      })
      .then(() => {
        this.pageValue = nextPage
      })
      .catch(error => {
        console.warn('Infinite scroll failed:', error)
        this.hideSpinner()
        this.disconnect()
      })
  }
}









  // loadMore() {
  //   const nextPage = this.pageValue + 1
  //   const url = new URL(this.urlValue, window.location.origin)
  //   url.searchParams.set('page', nextPage)

  //   fetch(url.toString(), {
  //     headers: { 'Accept': 'text/vnd.turbo-stream.html' }
  //   })
  //   .then(response => {
  //     if (!response.ok) {
  //       // Например, 404, 500 и т.д. — считаем, что данных больше нет
  //       this.disconnect()
  //       return null
  //     }
  //     return response.text()
  //   })
  //   .then(html => {
  //     if (html === null || !html.trim()) {
  //       // Пустой ответ — тоже конец списка
  //       this.disconnect()
  //       return
  //     }

  //     // // Дополнительно можно проверить, содержит ли HTML хоть один <turbo-stream>
  //     // const hasTurboStream = /<turbo-stream/i.test(html)
  //     // if (!hasTurboStream) {
  //     //   this.disconnect()
  //     //   return
  //     // }

  //     return Turbo.renderStreamMessage(html)
  //   })
  //   .then(() => {
  //     // Обновляем номер страницы только если всё прошло успешно
  //     this.pageValue = nextPage
  //   })
  //   .catch(error => {
  //     // Опционально: логировать ошибку, но не продолжать загрузку
  //     console.warn('Infinite scroll failed:', error)
  //     this.disconnect()
  //   })
  // }
// }
