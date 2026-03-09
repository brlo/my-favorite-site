import { Controller } from "@hotwired/stimulus"
import notifications from "../services/notifications_service.js"
import { strip, stripDots, copyText, copyTextLink } from "../lib/tools/"
import { t, t_cont } from "../lib/localization/"

export default class extends Controller {
  static targets = [
    "selectBar",
    "selectMode",
    "copyTextAddress",
    "copyAddress",
    "copyText",
    "copyLink",
    "copyBurgerIcon",
    "copyBurgerMenu"
  ]

  static outlets = ["verse-highlighter"]

  connect() {
    // Переносим все свойства и методы из window.selectBar
    this.isEnabled = false
    this.isSelectMode = false
    this.el = this.selectBarTarget
    this.fragmentRegexp = /^L(\d{1,3}|\d{1,3}-\d{1,3})(,(\d{1,3}|\d{1,3}-\d{1,3})){0,6}$/

    // Инициализируем copyBurger как свойство контроллера
    this.copyBurger = {
      el: this.copyBurgerMenuTarget,
      elIcon: this.copyBurgerIconTarget,
      isShown: false,
      show: () => {
        this.copyBurger.el.classList.remove('hidden')
        this.copyBurger.isShown = true
      },
      hide: () => {
        this.copyBurger.el.classList.add('hidden')
        this.copyBurger.isShown = false
      }
    }

    this.checkExistingHighlights()

    // Сохраняем ссылку на контроллер в window, если нужно для обратной совместимости
    window.selectBarController = this

    this.verseHighlighterOutlets.forEach(outlet => {
      outlet.selectBarConnected?.(this)
    })
  }

  checkExistingHighlights() {
    const highlightedCount = document.body.querySelectorAll('.highlighted').length

    if (highlightedCount > 0) {
      // Небольшая задержка, чтобы DOM успел отрисоваться
      setTimeout(() => {
        this.enable()
      }, 10)
    }
  }

  // Методы из оригинального объекта
  enable() {
    this.selectBarTarget.classList.remove('hidden')
    this.isEnabled = true
    document.body.classList.add('select-bar-enabled')
  }

  disable() {
    this.selectBarTarget.classList.add('hidden')
    this.copyBurger.hide()
    if (this.isSelectMode === true) this.selectModeClicked()
    this.isEnabled = false
    document.body.classList.remove('select-bar-enabled')
  }

  get isSelectModeActive() { return this.isSelectMode }

  // Метод для обновления состояния select-mode извне
  setSelectMode(value) {
    if (value !== this.isSelectMode) {
      this.isSelectMode = value
      this.selectModeTarget?.classList.toggle('active', value)
      // При необходимости диспатчим событие
      // this.dispatch("select-mode-changed", { detail: { enabled: value } })
    }
  }

  getSelectedText() {
    let lightClass = 'highlighted'
    let selectedLines = Array.prototype.slice.call(document.getElementsByClassName(lightClass))

    if (selectedLines < 1) return ''

    let chunks = []
    let prevLineNumb = 0
    for (const line of selectedLines) {
      let currentLineNumb = parseInt(line.dataset.line)
      if (prevLineNumb != (currentLineNumb - 1)) {
        if (chunks.length != 0) {
          chunks.push('<...>')
        }
      }
      chunks.push(strip(line.textContent))
      prevLineNumb = currentLineNumb
    }

    let text = chunks.join(' ')
    text = stripDots(text)
    return text
  }

  getSelectedAddress() {
    let fragmentStr = window.location.hash

    if (typeof fragmentStr !== 'string') return ''
    if (fragmentStr == '') return ''
    if (fragmentStr == '#') return ''

    let lineStr = fragmentStr.substr(1)

    if (!this.fragmentRegexp.test(lineStr)) return ''

    const lines = lineStr.substr(1)
    let bookInfo = document.getElementById('current-address').dataset
    let bookName = bookInfo.bookShortName
    let chapter = bookInfo.chapter
    let isDisableChapters = bookInfo.disableChapters

    let address = bookName + '. '
    if (isDisableChapters != '1') { address += chapter + ':' }
    address += lines

    return address
  }

  // Action методы для Stimulus
  selectModeClicked(event) {
    let selectMode = this.selectModeTarget

    if (this.isSelectMode != true) {
      this.isSelectMode = true
      selectMode.classList.add('active')
    } else {
      this.isSelectMode = false
      selectMode.classList.remove('active')
    }
    return
  }

  copyTextAndAddressClicked(event) {
    this.copyBurgerClicked()

    let text = this.getSelectedText()
    let address = this.getSelectedAddress()

    let textBefore = t_cont('quoteStart') + text + t_cont('quoteEnd') + t_cont('bracketStart')
    let textAfter = t_cont('bracketEnd')
    let linkText = address
    const href = window.location.href
    copyTextLink(textBefore, linkText, textAfter, href)

    notifications.add(
      '<t>' + t('copyTitle') + ':</t>' +
      t_cont('quoteStart') + text.slice(0,30) + '...' + t_cont('quoteEnd') +
      '<br>' +
      t_cont('bracketStart') + address + t_cont('bracketEnd')
    )
    return
  }

  copyTextClicked(event) {
    this.copyBurger.hide()

    const text = this.getSelectedText()

    copyText(text)
    notifications.add('<t>' + t('copyTitle') + ':</t>' + text.slice(0,30) + '...')
    return
  }

  copyAddressClicked(event) {
    this.copyBurger.hide()

    const href = window.location.href
    const address = this.getSelectedAddress()

    copyTextLink('', address, '', href)
    notifications.add('<t>' + t('copyTitle') + ':</t>' + address)
    return
  }

  copyLinkClicked(event) {
    this.copyBurger.hide()

    const link = window.location.href
    copyText(link)
    notifications.add('<t>' + t('copyTitle') + ':</t>' + link)
    return
  }

  copyBurgerClicked(event) {
    if (this.copyBurger.isShown === false) {
      this.copyBurger.show()
    } else {
      this.copyBurger.hide()
    }
  }

  // Обработчик клика вне меню
  handleOutsideClick(event) {
    if (this.copyBurger.isShown) {
      const el = event.target
      const isIconClicked = this.copyBurger.elIcon.contains(el)
      const isClickInsideMenu = this.copyBurger.el.contains(el)

      if (!isIconClicked && !isClickInsideMenu) this.copyBurger.hide()
    }
  }

  saveHighlightedLines() {
    // Получаем все выделенные строки
    const highlightedLines = Array.from(document.getElementsByClassName('highlighted'))
      .map(el => el.dataset.line)
      .filter(line => line) // убираем undefined
      .sort((a, b) => a - b)

    if (highlightedLines.length > 0) {
      // Формируем строку для фрагмента URL
      // Например: L1-3,5,7-10
      const lineRanges = this.compressToRanges(highlightedLines)
      window.location.hash = 'L' + lineRanges.join(',')
    } else {
      // Если выделений нет, убираем фрагмент
      window.location.hash = ''
    }
  }

  compressToRanges(lines) {
    const ranges = []
    let start = lines[0]
    let end = lines[0]

    for (let i = 1; i < lines.length; i++) {
      if (parseInt(lines[i]) === parseInt(end) + 1) {
        end = lines[i]
      } else {
        ranges.push(start === end ? `${start}` : `${start}-${end}`)
        start = lines[i]
        end = lines[i]
      }
    }
    ranges.push(start === end ? `${start}` : `${start}-${end}`)
    return ranges
  }
}
