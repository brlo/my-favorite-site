import { Controller } from "@hotwired/stimulus"
import { en2ruTranslit } from 'lib/tools'

export default class extends Controller {
  static targets = ["tree", "link"]
  static values = {
    filter: String,
    useTranslit: Boolean
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

    // Ищем совпадения
    const hasMatches = this.findMatches(cleanText)

    // Если нет совпадений и транслит еще не использовали
    if (!hasMatches && !this.useTranslitValue) {
      // Пробуем транслитерацию
      const translitText = en2ruTranslit(cleanText)
      this.useTranslitValue = true
      this.findMatches(translitText)
    } else {
      // Сбрасываем флаг транслита для следующего поиска
      this.useTranslitValue = false
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
    const pattern = searchText.split('').join('{1}.*')
    const regex = new RegExp(pattern)

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

    // Если есть совпадения, скрываем все подменю
    if (hasMatches) {
      this.treeTargets.forEach(tree => {
        tree.classList.add('hidden-children')
      })
    }

    return hasMatches
  }

  resetFilter() {
    // Показываем все элементы
    this.linkTargets.forEach(link => {
      link.classList.remove('visible')
    })

    // Убираем класс скрытия с подменю
    this.treeTargets.forEach(tree => {
      tree.classList.remove('hidden-children')
    })
  }
}
