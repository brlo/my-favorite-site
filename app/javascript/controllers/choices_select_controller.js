import { Controller } from "@hotwired/stimulus"
import Choices from "choices.js"

export default class extends Controller {
  static values = {
    placeholder: String,
    searchEnabled: { type: Boolean, default: false },
    position: { type: String, default: 'auto' }
  }

  disconnect() {
    if (this.choices) {
      this.choices.destroy()
    }
  }

  connect() {
    // Ищем select внутри родительского элемента
    const select = this.element.querySelector('select')
    if (!select) {
      console.error('No select element found inside controller element')
      return
    }

    if (this.choices) return

    const params = {
      allowHTML: true,
      shouldSort: false,
      shouldSortItems: false,
      placeholder: true,
      placeholderValue: this.placeholderValue,
      searchEnabled: this.searchEnabledValue,
      prependValue: null,
      appendValue: null,
      renderSelectedChoices: 'auto', // top, bottom
      searchPlaceholderValue: 'поиск',
      loadingText: 'Поиск...',
      noResultsText: 'Ничего не найдено',
      noChoicesText: 'Ничего не выбрано',
      itemSelectText: '',
      position: this.positionValue,
    }

    try {
      this.choices = new Choices(select, params)
    } catch (error) {
      console.error('[choices] init error:', error)
    }
  }

  // выбор языка контента Библии (в выпыдающем списке языков возле текста)
  selectLang(el) {
    const langInput = el.target;
    const contentLang = langInput.value;

    // Элемент в котором хранятся все идентификаторы адреса
    const bookInfo = document.getElementById('current-address').dataset;

    let path = '/' +
      bookInfo.langUi + '/' +
      contentLang + '/'

    if (bookInfo.bookCode.length) {
      path = path +
        bookInfo.bookCode + '/' +
        bookInfo.chapter + '/' +
        window.location.search +
        window.location.hash;
    }

    Turbo.visit(path);
  };

  // выбор языка перевода
  selectLink(el) {
    const langInput = el.target;
    const fullPath = langInput.value;

    // ссылку в выпадающем списке могли указать уже с query-параметрами,
    // а вот фрагменты # никак не могли добавить, поэтому забираем их из текущей ссылки
    const path =
      fullPath +
      window.location.hash;

    Turbo.visit(path);
  };

  // выбор языка контента (в выпыдающем списке языков возле текста)
  selectPageLang(el) {
    const langInput = el.target;
    const fullPath = langInput.value;

    // Элемент в котором хранятся все идентификаторы адреса
    // const bookInfo = document.getElementById('current-address').dataset;

    const path =
      fullPath + '/' +
      window.location.search +
      window.location.hash;

    Turbo.visit(path);
  };

  // Клик на выбор языка интерфейса в футере
  selectUILang(el) {
    const langUIInput = el.target;
    const newUILang = langUIInput.value;

    // Разбиваем путь на части, удаляем пустые сегменты
    let currentPath = window.location.pathname;
    const pathParts = currentPath.split('/').filter(part => part.length > 0);

    let newPath;

    if (pathParts.length > 0) {
      // Заменяем первый сегмент (текущую локаль) на новую
      pathParts[0] = newUILang;
      newPath = '/' + pathParts.join('/');
    } else {
      // Путь пустой (главная страница) - просто добавляем локаль
      newPath = '/' + newUILang;
    }

    // Добавляем query string и hash
    const fullPath = newPath + window.location.search + window.location.hash;

    Turbo.visit(fullPath);
  };
}

