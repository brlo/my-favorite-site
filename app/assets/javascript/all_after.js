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

  // Клик на элементы, вызвающие меню
  const currBookLink = document.getElementById('current-book');
  if (currBookLink) {
    currBookLink.addEventListener('click', function(e){
      e.preventDefault(); e.stopPropagation();
      menuBooks.show('book-clicked');
  })};

  const bibLink = document.getElementById('bible-link');
  if (bibLink) {
    bibLink.addEventListener('click', function(e){
      e.preventDefault(); e.stopPropagation();
      menuBooks.show('bible-clicked');
  })};

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


// =======================================================================
// =================== SETTINGS AREA =====================================
// =======================================================================

// Настройки в шапке
window.settingsArea = {
  // меню
  el: document.getElementById('settings-area'),
  // Клик на btn показывает el
  btn: settingsBtn = document.getElementById('settings-btn'),
  isShown: false,
};

// ВКЛ
settingsArea.show = function () {
  settingsArea.el.classList.remove('hidden');
  settingsArea.isShown = true;
};

// ВЫКЛ
settingsArea.hide = function () {
  settingsArea.el.classList.add('hidden');
  settingsArea.isShown = false;
};

// КЛИК - откр
settingsArea.settingsBtnClicked = function () {
  if (settingsArea.isShown === false) {
    settingsArea.show();
  } else {
    settingsArea.hide();
  };
};

// выбор размера текста
settingsArea.textSizeBar = {
  // нельзя заранее искать область с текстом, т.к. она меняется при переключении глав
  // textEl: document.querySelector('article'),
  btns: document.querySelectorAll('#text-menu > a'),
}

settingsArea.textSizeBar.someTextSizeBtnClicked = function (e) {
  const btnClicked = e.target;
  // имя класса для article
  const fontSizeName = {
    'text-small-btn': 'text-small',
    'text-medium-btn': 'text-medium',
    'text-large-btn': 'text-large',
  }[btnClicked.id]
  // размер текста для кук
  const fontSizeCookie = {
    'text-small-btn': '1',
    'text-medium-btn': '2',
    'text-large-btn': '3',
  }[btnClicked.id]

  // все кнопки "отжимаем"
  for (const barBtn of settingsArea.textSizeBar.btns) { barBtn.classList.remove('active') };
  // нажатую "нажимаем"
  btnClicked.classList.add('active');
  // размер текста выставляем
  const textEl = document.querySelector('article');
  if (textEl) textEl.className = fontSizeName;
  // в куки сохраняем
  setCookie('textSize', fontSizeCookie, 999);
};

// СОБЫТИЯ НАСТРОЕК И ВНУТРЕННИХ ЭЛЕМЕНТОВ
settingsArea.enableListeners = function () {
  if (!settingsArea.el) return;

  settingsArea.btn.addEventListener('click', settingsArea.settingsBtnClicked, false);

  for (const barBtn of settingsArea.textSizeBar.btns) {
    barBtn.addEventListener('click', settingsArea.textSizeBar.someTextSizeBtnClicked, false);
  };

  // Клик за границами меню прячет меню
  document.addEventListener('click', event => {
    if (settingsArea.isShown) {
      const el = event.target;

      const isBtnClicked = settingsArea.btn === el;
      const isClickInsideMenu = settingsArea.el.contains(el);
      // прячем меню
      // нажали не на иконку показа, не на элементы меню
      if (!isBtnClicked && !isClickInsideMenu) settingsArea.hide();
    };
  });
};

settingsArea.enableListeners();

// ================================
// LOGOUT

window.BX.logout = function() {
  axios.delete('/ru/logout/')
  .then(function (response) {
    window.location.href = '/';
  })
  .catch(function (error) {
    console.log(error);
  });
};




