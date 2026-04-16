import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["verseLine", "verseText"]

  static outlets = ["select-bar"]

  connect() {
    // Инициализация состояния
    this.lastLineSelected = null
    this.lastShiftLineSelectedRange = null
    this.lightClass = 'highlighted'

    // Применяем подсветку из фрагмента URL при загрузке
    this.applyHighlightingFromFragment()
  }

  // Вызывается, когда select-bar подключается к этому контроллеру
  selectBarConnected(selectBarController) {
    this.selectBar = selectBarController
  }

  // Хелпер для безопасного доступа к select-bar
  get selectBar() {
    // Если outlet подключен — используем его
    if (this.hasSelectBarOutlet && this.selectBarOutlets[0]) {
      return this.selectBarOutlets[0]
    }
    // Фолбэк на глобальный объект для обратной совместимости
    return window.selectBarController || window.selectBar
  }

  // Парсит фрагмент вида #L1-2,5,10-11 → [1,2,3,5,10,11]
  // старый вариант: https://github.com/brlo/my-favorite-site/blob/cdca7b2510a037eabded6733bf6ead58ae80fc03/app/assets/javascript/index.js#L112
  getLinesArrFromUrlFragment() {
    let fragmentStr = window.location.hash

    if (typeof fragmentStr !== 'string' || fragmentStr === '' || fragmentStr === '#') {
      return []
    }

    let lineStr = fragmentStr.substring(1)

    // Используем внешнюю регулярку или дефолтную
    const regexpLines = /^L(\d{1,3}|\d{1,3}-\d{1,3})(,(\d{1,3}|\d{1,3}-\d{1,3})){0,6}$/

    if (!regexpLines.test(lineStr)) return []

    const lines = lineStr.substring(1).split(',').slice(0, 6)
    const linesNums = []

    lines.forEach((line) => {
      const parts = line.split('-')
      if (parts.length === 1) {
        linesNums.push(parseInt(parts[0], 10))
      } else if (parts.length === 2) {
        const start = parseInt(parts[0], 10)
        const end = parseInt(parts[1], 10)
        if (start > 300 || end > 300) return
        for (let i = start; i <= end; i++) {
          linesNums.push(i)
        }
      }
    })

    return linesNums
  }

  // Применяет подсветку на основе фрагмента URL
  applyHighlightingFromFragment() {
    const linesToHighlight = this.getLinesArrFromUrlFragment()
    if (linesToHighlight.length === 0) return

    // Подсвечиваем строки
    linesToHighlight.forEach((lineNum) => {
      const elText = document.getElementById(`T${lineNum}`)
      if (elText) {
        elText.classList.add(this.lightClass)
      }
    })

    // Показываем select-bar, если есть выделения
    if (linesToHighlight.length > 0 && this.selectBar) {
      this.selectBar.enable?.()
    }

    // Скроллим к выделенным строкам (только при первой загрузке!)
    setTimeout(() => {
      this.scrollToHighlightedLines(linesToHighlight)
    }, 50)
  }

  // Сохраняет выделенные строки во фрагмент URL
  saveHightlightedLinesToFragment() {
    const addressElements = []
    const linesHighlighted = this.element.getElementsByClassName(this.lightClass)

    if (linesHighlighted.length > 0) {
      const lineNumbers = Array.from(linesHighlighted).map(el =>
        parseInt(el.dataset.line, 10)
      )

      // Используем внешний хелпер или встроенный
      const seqs = typeof window.arrayToSeqs === 'function'
        ? window.arrayToSeqs(lineNumbers)
        : this.arrayToSeqs(lineNumbers)

      seqs.forEach((seq) => {
        if (seq.length === 1) {
          addressElements.push(String(seq[0]))
        } else if (seq.length > 1) {
          addressElements.push(`${seq[0]}-${seq[seq.length - 1]}`)
        }
      })
    }

    if (addressElements.length > 0) {
      const addressFragment = `L${addressElements.join(',')}`
      const oldScrollPosition = window.scrollY === 0 ? 1 : window.scrollY

      window.location.hash = addressFragment
      window.scrollTo(0, oldScrollPosition)
    } else {
      history.pushState({}, document.title, window.location.pathname + window.location.search)
    }
  }

  // Хелпер: [1,2,3,10] → [[1,2,3], [10]]
  arrayToSeqs(arr) {
    if (!arr || arr.length === 0) return []

    const sorted = [...arr].sort((a, b) => a - b)
    const result = []
    let currentSeq = [sorted[0]]

    for (let i = 1; i < sorted.length; i++) {
      if (sorted[i] === sorted[i - 1] + 1) {
        currentSeq.push(sorted[i])
      } else {
        result.push(currentSeq)
        currentSeq = [sorted[i]]
      }
    }
    result.push(currentSeq)
    return result
  }

  // показать/скрыть select-bar:
  updateSelectBarVisibility(countWas, countNow) {
    if (!this.selectBar) return

    if (countWas < 2 && countNow > 0) {
      this.selectBar.enable?.()
    } else if (countNow === 0 && countWas > 0) {
      this.selectBar.disable?.()
      this.lastLineSelected = null
      this.lastShiftLineSelectedRange = null
    }
  }

  // Проверка модификаторов (Ctrl/Cmd/SelectMode)
  isModifierPressed(event) {
    return event.ctrlKey ||
           event.metaKey ||
           this.selectBar?.isSelectModeActive ||
           event.getModifierState?.("OS") ||
           event.getModifierState?.("Super") ||
           event.getModifierState?.("Win")
  }

  // Обработчик клика по номеру строки
  lineNumberClicked(event) {
    event.preventDefault()
    document.getSelection().removeAllRanges()

    const elNum = event.currentTarget
    const lineNumber = elNum.dataset.line
    const elText = document.getElementById(`T${lineNumber}`)

    if (!elText) return

    const countOfHightlightedWas = this.element.getElementsByClassName(this.lightClass).length

    // CTRL/CMD: переключение класса у кликнутой строки
    if (this.isModifierPressed(event)) {
      if (elText.classList.contains(this.lightClass)) {
        elText.classList.remove(this.lightClass)
      } else {
        elText.classList.add(this.lightClass)
        this.lastLineSelected = lineNumber
        this.lastShiftLineSelectedRange = null
      }

    // SHIFT: выделение диапазона
    } else if (event.shiftKey && this.lastLineSelected != null) {
      // Снимаем предыдущее Shift-выделение
      if (this.lastShiftLineSelectedRange?.length === 2) {
        const [startLine, endLine] = this.lastShiftLineSelectedRange.map(n => parseInt(n, 10))
        for (let n = startLine; n <= endLine; n++) {
          const el = document.getElementById(`T${n}`)
          if (el?.classList.contains(this.lightClass)) {
            el.classList.remove(this.lightClass)
          }
        }
      }

      // Добавляем новое выделение
      const currentLine = parseInt(lineNumber, 10)
      const lastSelected = parseInt(this.lastLineSelected, 10)
      const [startLine, endLine] = [currentLine, lastSelected].sort((a, b) => a - b)

      for (let j = startLine; j <= endLine; j++) {
        const el = document.getElementById(`T${j}`)
        if (el && !el.classList.contains(this.lightClass)) {
          el.classList.add(this.lightClass)
        }
      }

      this.lastShiftLineSelectedRange = [startLine, endLine]

    // Одиночный клик: очистить всё и выделить только кликнутое
    } else {
      const isElementAlreadyHighlighted = elText.classList.contains(this.lightClass)

      // Снимаем все старые выделения
      const olds = Array.from(this.element.getElementsByClassName(this.lightClass))
      olds.forEach(el => el.classList.remove(this.lightClass))

      // Выделяем кликнутое, если не было выделено
      if (!isElementAlreadyHighlighted) {
        elText.classList.add(this.lightClass)
        this.lastLineSelected = lineNumber
        this.lastShiftLineSelectedRange = null
      }
    }

    // Показ/скрытие селект-бара
    const countNow = this.element.getElementsByClassName(this.lightClass).length

    // Вместо прямого вызова window.selectBar:
    this.updateSelectBarVisibility(countOfHightlightedWas, countNow)

    // Сохраняем в URL
    this.saveHightlightedLinesToFragment()
  }

  // Обработчик клика по тексту стиха (когда включён select-mode)
  lineTextClicked(event) {
    if (this.selectBar?.isSelectModeActive === true) {
      this.lineNumberClicked(event)
    }
  }

  scrollToHighlightedLines(lineNumbers) {
    const firstEl = document.getElementById(`T${lineNumbers[0]}`)
    if (!firstEl) return

    firstEl.scrollIntoView({
      behavior: 'smooth',
      block: 'start' // или 'center'
    })

    // Компенсация фиксированного хедера после скролла
    setTimeout(() => {
      window.scrollBy(0, -this.scrollOffsetValue)
    }, 600) // чуть позже начала анимации скролла
  }
}
