import { Controller } from "@hotwired/stimulus"
import { en2ruTranslit } from 'lib/tools'

export default class extends Controller {
  static targets = ["menu", "searchInput", "bookLink"]
  static values = { shown: Boolean }

  connect() {
    this.shownValue = false
  }

  // Показать меню
  show(event) {
    event?.preventDefault()
    event?.stopPropagation()

    const needAddClass = event?.currentTarget?.id === 'current-book' ? 'book-clicked' :
                         event?.currentTarget?.id === 'bible-link' ? 'bible-clicked' : null

    if (needAddClass === 'book-clicked') {
      const isSameMenuOpened = this.menuTarget.classList.contains('book-clicked')
      if (isSameMenuOpened) {
        this.hide()
        return
      }
    }

    if (needAddClass === 'bible-clicked') {
      const isSameMenuOpened = this.menuTarget.classList.contains('bible-clicked')
      if (isSameMenuOpened) {
        this.hide()
        return
      }
    }

    // Оставляем только один нужный класс, убираем hidden
    this.menuTarget.className = 'menu-books'
    if (needAddClass) this.menuTarget.classList.add(needAddClass)
    this.shownValue = true
  }

  // Скрыть меню
  hide() {
    this.menuTarget.className = 'menu-books hidden'
    this.shownValue = false
    this.eraseSearch()
  }

  // Обработчик клика вне меню
  clickOutside(event) {
    const isClickOnTrigger = event.target.id === 'current-book' ||
                            event.target.id === 'bible-link'

    if (isClickOnTrigger) return

    if (this.shownValue && !this.menuTarget.contains(event.target)) {
      this.hide()
    }
  }

  // Фильтрация книг
  filter(event) {
    this.filterBooks(event.target.value)
  }

  filterBooks(text, isNeedTranslit = false) {
    const els = this.bookLinkTargets
    let filterText = text.toLowerCase().replace(/[^a-zа-я0-9]/gi, '')
    filterText = filterText.replace(/[\d\-,\s]+$/g, '')

    if (isNeedTranslit) {
      filterText = en2ruTranslit(filterText)
    }

    if (filterText === '') {
      this.menuTarget.classList.remove('dark')
      els.forEach(el => el.classList.remove('h-light'))
    } else {
      const userPattern = filterText.split('').join('{1}.*')
      const regex = new RegExp(userPattern)
      let isSomethingMatch = false

      els.forEach(el => {
        const elText = (el.innerText || el.textContent).toLowerCase()
        const isThisMatch = regex.test(elText)

        if (isThisMatch) {
          el.classList.add('h-light')
          isSomethingMatch = true
        } else {
          el.classList.remove('h-light')
        }
      })

      if (isSomethingMatch) {
        this.menuTarget.classList.add('dark')
      } else if (!isNeedTranslit) {
        this.filterBooks(text, true)
      }
    }
  }

  eraseSearch() {
    this.bookLinkTargets.forEach(el => el.classList.remove('h-light'))
    if (this.hasSearchInputTarget) {
      this.searchInputTarget.value = ''
    }
  }
}
