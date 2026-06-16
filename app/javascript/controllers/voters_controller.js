import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  toggle(event) {
    const frameId = event.currentTarget.dataset.turboFrame
    const currentFrame = document.getElementById(frameId)

    if (currentFrame && currentFrame.innerHTML.trim() !== '') {
      // Если уже загружено — просто показываем/скрываем
      if (currentFrame.style.display === 'none') {
        console.log('block')
        currentFrame.style.display = 'block'
      } else {
        console.log('none')
        currentFrame.style.display = 'none'
      }
    }
  }
}
