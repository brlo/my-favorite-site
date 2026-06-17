import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toast"]

  toastTargetConnected(toast) {
    const timeoutId = setTimeout(() => {
      toast.classList.add('opacity-0', 'transition-opacity', 'duration-500')

      setTimeout(() => {
        if (toast.parentNode) toast.remove()
      }, 200)
    }, 3000)

    // Кладем id таймера в dataset, чтобы использовать в disconnect
    toast.dataset.timeoutId = timeoutId
  }

  toastTargetDisconnected(toast) {
    clearTimeout(Number(toast.dataset.timeoutId))
  }
}
