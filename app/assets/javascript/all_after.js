var element = document.querySelector('#lang-select');
if (element) {
  new Choices(element, {
    allowHTML: true,
    shouldSort: false,
    shouldSortItems: false,
    placeholder: true,
    placeholderValue: 'Язык Библии',
    searchEnabled: false,
    prependValue: null,
    appendValue: null,
    renderSelectedChoices: 'auto',
    itemSelectText: '',
    position: 'down',
    classNames: {
      containerOuter: 'choices lang-select'
    },
  });
};

window.selectLocale = function(locale) {
  if (window.BX.locale == locale) return;

  const path = location.pathname;
  const query = location.search;

  // формируем новую ссылку
  if (path.length > 0) {
    let new_path = path;
    // удаляем локаль, если она уже есть в адресе
    if (/^\/en|ru\//.test(new_path)) {
      new_path = new_path.substr(3);
    }

    // добавляем новую локаль
    new_path = '/' + locale + new_path;

    // идём на новый адрес, если старый и новый path отличается
    if (path != new_path) {
      // переключаем язык Писания на соответствующий, чтобы человек сразу оказался в понятной обстановке
      if (locale == 'ru') {
        setCookie('b-lang', 'ru', 999);
      } else if (locale == 'en') {
        setCookie('b-lang', 'eng-nkjv', 999);
      };

      // пошли
      window.location.href = new_path + query;
    }
  };
}

// ================================================
// LISTENERS
// ================================================

// Меню для выбора книг
window.menuBooks = {
  isShown: false,
  el: document.getElementById('menu-books'),
}

menuBooks.show = function (needAddClass = null) {
  if (needAddClass == 'book-clicked') {
    // Скрываем. Это повторный клик на название книги.
    let isSameMenuOpened = document.getElementsByClassName('book-clicked').length > 0;
    if (isSameMenuOpened) { menuBooks.hide(); return; };
  };

  if (needAddClass == 'bible-clicked') {
    // Скрываем. Это повторный клик на Библию (в меню).
    let isSameMenuOpened = document.getElementsByClassName('bible-clicked').length > 0;
    if (isSameMenuOpened) { menuBooks.hide(); return; };
  };

  // меню было скрыто, поэтому мы его покажем с нужным классом, предварительно всё почистив
  menuBooks.el.className = '';
  if (needAddClass !== null) menuBooks.el.classList.add(needAddClass);
  menuBooks.isShown = true;

  return false;
};

menuBooks.hide = function () {
  menuBooks.el.className = '';
  menuBooks.el.classList.add('hidden');
  menuBooks.isShown = false;
  return false;
};

menuBooks.enableListeners = function () {
  if (!menuBooks.el) return;

  // Клик за границами меню прячет меню
  document.addEventListener('click', event => {
    const el = event.target;

    // Прячем. Так как нажали не на открывающие меню ссылки, а само меню при этом показано
    if (el.id != 'current-book' && el.id != 'bible-link' && menuBooks.isShown) {
      const isClickInside = menuBooks.el.contains(event.target);
      if (!isClickInside) menuBooks.hide();
    };
  });
};

menuBooks.enableListeners();

