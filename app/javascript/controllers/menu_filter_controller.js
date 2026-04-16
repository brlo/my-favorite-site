import { Controller } from "@hotwired/stimulus"
import { en2ruTranslit } from 'lib/tools'

export default class extends Controller {
  static targets = ["tree", "link"]
  static values = {
    filter: String
  }

  filter(event) {
    // Получаем текст из поля ввода
    const filterText = event?.target?.value || ""

    // Очищаем фильтр
    const cleanText = this.cleanFilterText(filterText)

    // Если текст пустой - показываем все элементы
    if (!cleanText) {
      this.resetFilter()
      return
    }

    // Пробуем прямой поиск
    let hasMatches = this.findMatches(cleanText)

    // Если нет совпадений, пробуем транслитерацию
    if (!hasMatches) {
      const translitText = en2ruTranslit(cleanText)
      if (translitText !== cleanText) {
        hasMatches = this.findMatches(translitText)
      }
    }
  }

  cleanFilterText(text) {
    // Приводим к нижнему регистру, оставляем буквы и цифры
    let cleanText = text.toLowerCase().replace(/[^a-zа-я0-9]/gi, '')
    // Убираем цифры, дефисы, запятые и пробелы в конце
    cleanText = cleanText.replace(/[\d\-,\s]+$/g, '')
    return cleanText
  }

  findMatches(searchText) {
    // Создаем паттерн для поиска последовательности символов
    const pattern = searchText.split('').join('.*')
    const regex = new RegExp(pattern, 'i')

    let hasMatches = false

    // Проверяем каждый элемент меню
    this.linkTargets.forEach(link => {
      const linkText = (link.innerText || link.textContent).toLowerCase()
      const isMatch = regex.test(linkText)

      if (isMatch) {
        link.classList.add('visible')
        hasMatches = true
      } else {
        link.classList.remove('visible')
      }
    })

    // Управляем видимостью подменю
    if (hasMatches) {
      this.treeTargets.forEach(tree => {
        tree.classList.add('hidden-children')
      })
    } else {
      // Если нет совпадений, показываем все подменю
      this.treeTargets.forEach(tree => {
        tree.classList.remove('hidden-children')
      })
    }

    return hasMatches
  }

  resetFilter() {
    // Скрываем все элементы
    this.linkTargets.forEach(link => {
      link.classList.remove('visible')
    })

    // Убираем класс скрытия с подменю
    this.treeTargets.forEach(tree => {
      tree.classList.remove('hidden-children')
    })
  }
}
