import { Controller } from "@hotwired/stimulus"
import Cookies from "lib/cookies"
import { t } from "lib/localization"

export default class extends Controller {
  static targets = ["menu", "button", "textSmallBtn", "textMediumBtn", "textLargeBtn", "nightModeSwitcher"]
  static values = { isShown: { type: Boolean, default: false } }

  connect() {
    this.preInitText()
    this.preInitColors()
  }

  // Предварительная инициализация размера текста
  preInitText() {
    // Устанавливаем класс и активную кнопку согласно кукам
    // к элементам страницы это применяется на старте, в initial_settings_controller
    if (document.cookie.includes('textSize=3')) {
      this.textLargeBtnTarget.classList.add('active')
    } else if (document.cookie.includes('textSize=2')) {
      this.textMediumBtnTarget.classList.add('active')
    } else {
      this.textSmallBtnTarget.classList.add('active')
    }
  }

  // Предварительная инициализация цветовой схемы
  preInitColors() {
    if (document.cookie.includes('isNightMode=1')) {
      document.body.classList.add('night-mode')
      if (this.hasNightModeSwitcherTarget) {
        this.nightModeSwitcherTarget.innerHTML = t('night')
      }
    }
  }

  // Клик по кнопке настроек
  toggleMenu(event) {
    event.preventDefault()
    if (this.isShownValue) {
      this.hide()
    } else {
      this.show()
    }
  }

  show() {
    this.menuTarget.classList.remove('hidden')
    this.isShownValue = true
  }

  hide() {
    this.menuTarget.classList.add('hidden')
    this.isShownValue = false
  }

  // Клик по кнопке размера текста
  textSizeClicked(event) {
    event.preventDefault()
    const btn = event.currentTarget

    // Определяем классы для article
    const textClassMap = {
      'text-small-btn': 'text-small',
      'text-medium-btn': 'text-medium',
      'text-large-btn': 'text-large'
    }

    // Определяем значения для кук
    const textCookieMap = {
      'text-small-btn': '1',
      'text-medium-btn': '2',
      'text-large-btn': '3'
    }

    const oldActiveBtn = this.getActiveTextBtn()
    const oldTextSizeClass = textClassMap[oldActiveBtn?.id]
    const newTextSizeClass = textClassMap[btn.id]
    const fontSizeCookie = textCookieMap[btn.id]

    // Деактивируем все кнопки
    this.textSmallBtnTarget.classList.remove('active')
    this.textMediumBtnTarget.classList.remove('active')
    this.textLargeBtnTarget.classList.remove('active')

    // Активируем нажатую
    btn.classList.add('active')

    // Меняем класс у article
    const articleEl = document.querySelector('article')
    if (articleEl && oldTextSizeClass) {
      articleEl.classList.replace(oldTextSizeClass, newTextSizeClass)
    }

    // Сохраняем в куки
    Cookies.set('textSize', fontSizeCookie, 999)
  }

  // Переключение ночного режима (переключение туда-сюда)
  toggleNightMode(event) {
    event.preventDefault()
    const modeSwitcher = document.getElementById("night-mode-switcher");
    const body = document.body;
    const nightClass = "night-mode";

    if (body.classList.contains(nightClass)) {
      body.classList.remove(nightClass);
      Cookies.set('isNightMode', 0, 999);
      modeSwitcher.innerHTML = t('day');
    } else {
      body.classList.add(nightClass);
      Cookies.set('isNightMode', 1, 999);
      modeSwitcher.innerHTML = t('night');
    }

    return false;
  }

  // Получить активную кнопку размера текста
  getActiveTextBtn() {
    if (this.textSmallBtnTarget.classList.contains('active')) return this.textSmallBtnTarget
    if (this.textMediumBtnTarget.classList.contains('active')) return this.textMediumBtnTarget
    if (this.textLargeBtnTarget.classList.contains('active')) return this.textLargeBtnTarget
    return null
  }

  // клик вне меню
  clickOutside(event) {
    if (!this.isShownValue) return

    const isButtonClick = this.buttonTarget.contains(event.target)
    const isInsideMenu = this.menuTarget.contains(event.target)

    if (!isButtonClick && !isInsideMenu) {
      this.hide()
    }
  }
}
