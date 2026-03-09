// import notifications from "../services/notification_service"

// Простое уведомление
// notifications.add('Ссылка скопирована')

// Уведомление с типом
// notifications.success('Операция выполнена успешно!')
// notifications.error('Произошла ошибка')
// notifications.info('Информационное сообщение')

// С кастомной длительностью
// notifications.add('Важное сообщение', {
//   type: 'warning',
//   duration: 5000,
//   fadeTime: 3000
// })

class NotificationService {
  constructor() {
    this.stack = []
    this.isVisible = false
    this.defaultOptions = {
      type: 'info', // 'info', 'success', 'error', 'warning'
      duration: 2500,
      fadeTime: 2000
    }
  }

  add(message, options = {}) {
    const notification = {
      message,
      options: { ...this.defaultOptions, ...options },
      id: Date.now() + Math.random()
    }

    this.stack.push(notification)
    this.show()
  }

  success(message, duration) {
    this.add(message, { type: 'success', duration })
  }

  error(message, duration) {
    this.add(message, { type: 'error', duration })
  }

  info(message, duration) {
    this.add(message, { type: 'info', duration })
  }

  show() {
    if (this.isVisible || this.stack.length === 0) return

    const notification = this.stack.shift()
    if (!notification) return

    this.isVisible = true
    this.render(notification)
  }

  render(notification) {
    this.removeExisting()

    const el = this.createElement(notification)
    document.body.appendChild(el)

    setTimeout(() => {
      el.style.opacity = '0'
    }, notification.options.fadeTime)

    setTimeout(() => {
      el.remove()
      this.isVisible = false
      this.show()
    }, notification.options.duration)
  }

  createElement(notification) {
    const colors = {
      info: '#2196F3',
      success: '#4CAF50',
      error: '#F44336',
      warning: '#FF9800'
    }

    const el = document.createElement('div')
    el.id = 'popup-notif'
    el.innerHTML = notification.message
    if (notification.options.type != 'info') {
      el.style.cssText = `
        background: ${colors[notification.options.type]};
      `
    }
    return el
  }

  removeExisting() {
    const existing = document.getElementById('popup-notif')
    if (existing) existing.remove()
  }
}

export default new NotificationService()
