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

// TRANSLIT TABLE
window.en2ruTranslit = function(text) {
  const tr_en_ru_dict = {"q":"й","w":"ц","e":"у","r":"к","t":"е","y":"н","u":"г","i":"ш","o":"щ","p":"з","[":"х","]":"ъ","a":"ф","s":"ы","d":"в","f":"а","g":"п","h":"р","j":"о","k":"л","l":"д",";":"ж","'":"Э"," z":" я","x":"ч","c":"с","v":"м","b":"и","n":"т","m":"ь",",":"б",".":"ю","/":".","Q":"Й","W":"Ц","E":"У","R":"К","T":"Е","Y":"Н","U":"Г","I":"Ш","O":"Щ","P":"З","{":"Х","}":"Ъ","A":"Ф","S":"Ы","D":"В","F":"А","G":"П","H":"Р","J":"О","K":"Л","L":"Д",":":"Ж","|":"/","Z":"Я","X":"Ч","C":"С","V":"М","B":"И","N":"Т","M":"Ь","<":"Б",">":"Ю","?":",","@":"'","#":"№","$":";","^":":","&":"?"};
  return text.replace(/./g, m => (tr_en_ru_dict[m] || m) );
};

// ================================================
// LISTENERS
// ================================================

// Меню для выбора книг
window.menuBooks = {
  isShown: false,
  el: document.getElementById('menu-books'),
  searchInput: document.getElementById('filter-books'),
  booksLinks: document.querySelectorAll('#menu-books a'),
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

  // фокус на поисковом поле
  menuBooks.searchInput.focus();

  return false;
};

menuBooks.hide = function () {
  menuBooks.el.className = '';
  menuBooks.el.classList.add('hidden');
  menuBooks.isShown = false;
  return false;
};

menuBooks.filterBooks = function(text, isNeedTranslit) {
  const els = menuBooks.booksLinks;
  let filterText = text.toLowerCase().replace(/[^a-zа-я0-9]/gi, '');
  filterText = filterText.replace(/[\d\-,\s]+$/g, '');

  if (isNeedTranslit) {
    filterText = window.en2ruTranslit(filterText);
  };

  if (filterText === '') {
    // пользователь ничего не ввёл, надо всё почистить.
    // удалить общую метку
    menuBooks.el.classList.remove('dark');
    // удалить метку с подсвеченных элементов
    els.forEach(el => el.classList.remove('h-light'));
  } else {
    // ищем совпадения, если пользователь что-то ввёл
    let isSomethingMatch = false;

    // если есть совпадение по оригинальному тексту, или по транслиту, то подсвечиваем
    userPattern = filterText.split('').join('{1}.*');
    // получаем паттерн: б{1}.*ы{1}.*т{1}.*и{1}.*е
    const regex = new RegExp(userPattern);

    els.forEach(el => {
      // подсвечиваем элементы
      const elText = (el.innerText || el.textContent).toLowerCase();
      const isThisMatch = regex.test(elText);
      // if (elText.includes(filterText)) {
      if (isThisMatch) {
        el.classList.add('h-light');
        isSomethingMatch = true;
      } else {
        el.classList.remove('h-light')
      };
    });

    // если есть совпадения, то ставим общую метку на весь блок
    if (isSomethingMatch) {
      menuBooks.el.classList.add('dark');
    } else {
      // если нет результатов и транслит ещё не пробовали, то надо попробовать транслит поискать
      if (isNeedTranslit != true) {
        menuBooks.filterBooks(text, true);
      }
    };
  };
};

menuBooks.eraseSearch = function () {
  // отменяем подсветку искомых книг,
  menuBooks.el.querySelectorAll('a.h-light').forEach(el => el.classList.remove('h-light'));

  // стираем текст в поисковом поле
  menuBooks.searchInput.value = '';
}

menuBooks.goToSearch = function() {
  const text = menuBooks.searchInput.value;
  let params = [];

  if (text && text.length > 0) { params.push('t=' + text) };
  const url = '/' + window.BX.locale + '/search?' + params.join('&');
  document.location.href = url;
}

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
      if (!isClickInside) {
        menuBooks.hide();
        // отменить поиск книги и стереть значение в поле для поиска
        menuBooks.eraseSearch();
      }
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




