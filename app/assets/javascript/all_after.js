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

var element = document.querySelector('#ui-lang-select');
if (element) {
  new Choices(element, {
    allowHTML: true,
    shouldSort: false,
    shouldSortItems: false,
    placeholder: true,
    placeholderValue: 'Язык сайта',
    searchEnabled: false,
    prependValue: null,
    appendValue: null,
    renderSelectedChoices: 'auto',
    itemSelectText: '',
    position: 'auto',
    classNames: {
      containerOuter: 'choices ui-lang-select'
    },
  });
};

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
  // прячем меню трудов автора (он может быть открыто)
  menuABooks.hide();

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

  // оставляем только один постоянно нужный класс, а класс hidden стираем
  menuBooks.el.className = 'menu-books';
  if (needAddClass !== null) menuBooks.el.classList.add(needAddClass);
  menuBooks.isShown = true;

  // // фокус на поисковом поле
  // menuBooks.searchInput.focus();

  return false;
};

menuBooks.hide = function () {
  menuBooks.el.className = 'menu-books';
  menuBooks.el.classList.add('hidden');
  menuBooks.isShown = false;
  return false;
};

menuBooks.filterBooks = function(text, isNeedTranslit) {
  const els = menuBooks.booksLinks;
  // все буквы маленькие
  // оставляем только буквы и цифры
  // убираем цифры, -, "," и пробелы в конце строки
  let filterText = text.toLowerCase().replace(/[^a-zа-я0-9]/gi, '');
  filterText = filterText.replace(/[\d\-,\s]+$/g, '');

  if (isNeedTranslit) {
    // в конце этой ф-ции мы снова обращаемся к ней, но просим предварительно
    // исправить ползьовательский ввод в неправильной раскладке.
    // мы делаем это только если ничего не удалось найти в первый раз.
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
// =================== MENU FOR AUTHOR BOOK ==============================
// =======================================================================


// Меню для выбора книг
window.menuABooks = {
  isShown: false,
  el: document.getElementById('menu-author-books'),
  searchInput: document.getElementById('filter-author-books'),
  booksLinks: document.querySelectorAll('#menu-author-books a'),
}

menuABooks.show = function (needAddClass = null) {
  if (!window.menuABooks.el) return;

  // прячем меню Библии (оно может быть открыто)
  menuBooks.hide();

  // Скрываем. Это повторный клик на название книги.
  if (menuABooks.isShown == true) {
    menuABooks.hide()
  } else {
    // оставляем только один постоянно нужный класс, а класс hidden стираем
    menuABooks.el.className = 'page-menu menu-books book-clicked';
    if (needAddClass !== null) menuABooks.el.classList.add(needAddClass);
    menuABooks.isShown = true;

    // // фокус на поисковом поле
    // menuABooks.searchInput.focus();
  }

  return false;
};

menuABooks.hide = function () {
  if (!window.menuABooks.el) return;

  menuABooks.el.className = 'page-menu menu-books book-clicked';
  menuABooks.el.classList.add('hidden');
  menuABooks.isShown = false;
  return false;
};

menuABooks.filterBooks = function(text, isNeedTranslit) {
  const els = menuABooks.booksLinks;
  // все буквы маленькие
  // оставляем только буквы и цифры
  // убираем цифры, -, "," и пробелы в конце строки
  let filterText = text.toLowerCase().replace(/[^a-zа-я0-9]/gi, '');
  filterText = filterText.replace(/[\d\-,\s]+$/g, '');

  if (isNeedTranslit) {
    // в конце этой ф-ции мы снова обращаемся к ней, но просим предварительно
    // исправить ползьовательский ввод в неправильной раскладке.
    // мы делаем это только если ничего не удалось найти в первый раз.
    filterText = window.en2ruTranslit(filterText);
  };

  if (filterText === '') {
    // пользователь ничего не ввёл, надо всё почистить.
    // удалить общую метку
    menuABooks.el.classList.remove('dark');
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
      menuABooks.el.classList.add('dark');
    } else {
      // если нет результатов и транслит ещё не пробовали, то надо попробовать транслит поискать
      if (isNeedTranslit != true) {
        menuABooks.filterBooks(text, true);
      }
    };
  };
};

menuABooks.eraseSearch = function () {
  // отменяем подсветку искомых книг,
  menuABooks.el.querySelectorAll('a.h-light').forEach(el => el.classList.remove('h-light'));

  // стираем текст в поисковом поле
  menuABooks.searchInput.value = '';
}

menuABooks.goToSearch = function() {
  return false;
  // const text = menuABooks.searchInput.value;
  // let params = [];

  // if (text && text.length > 0) { params.push('t=' + text) };
  // const url = '/' + window.BX.locale + '/search?' + params.join('&');
  // document.location.href = url;
}

menuABooks.enableListeners = function () {
  if (!menuABooks.el) return;

  // Клик на элементы, вызвающие меню
  const currBookLink = document.getElementById('current-author-book');
  if (currBookLink) {
    currBookLink.addEventListener('click', function(e){
      e.preventDefault(); e.stopPropagation();
      menuABooks.show();
  })};

  // Клик за границами меню прячет меню
  document.addEventListener('click', event => {
    const el = event.target;

    // Прячем. Так как нажали не на открывающие меню ссылки, а само меню при этом показано
    if (el.id != 'current-author-book' && menuABooks.isShown) {
      const isClickInside = menuABooks.el.contains(event.target);
      if (!isClickInside) {
        menuABooks.hide();
        // отменить поиск книги и стереть значение в поле для поиска
        menuABooks.eraseSearch();
      }
    };
  });
};

menuABooks.enableListeners();

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
  activeBtn: document.querySelector('#text-menu > a.active')
}

settingsArea.textSizeBar.someTextSizeBtnClicked = function (e) {
  // id нажатой кнопки -> соответствующий ему класс article
  const textClassNames = {
    'text-small-btn': 'text-small',
    'text-medium-btn': 'text-medium',
    'text-large-btn': 'text-large',
  }
  // id нажатой кнопки -> соответствующее ему значение в куках
  const textCookieNames = {
    'text-small-btn': '1',
    'text-medium-btn': '2',
    'text-large-btn': '3',
  }

  // нажата кнопка (элемент)
  const btnClicked = e.target;
  // старое имя класса для article
  const oldTextSizeName = textClassNames[settingsArea.textSizeBar.activeBtn.id];
  // новое имя класса для article
  const TextSizeName = textClassNames[btnClicked.id];
  // размер текста для кук
  const fontSizeCookie = textCookieNames[btnClicked.id]

  // все кнопки "отжимаем"
  for (const barBtn of settingsArea.textSizeBar.btns) { barBtn.classList.remove('active') };
  // нажатую "нажимаем"
  btnClicked.classList.add('active');
  // размер текста выставляем
  const textEl = document.querySelector('article');
  if (textEl) {
    textEl.classList.replace(oldTextSizeName, TextSizeName);
  }
  // в куки сохраняем
  setCookie('textSize', fontSizeCookie, 999);
  // активную кнопку меняем
  settingsArea.textSizeBar.activeBtn = btnClicked;
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

// Аудио-плеер
window.BX.player = {
  el: undefined, // audio tag
  containerEl: document.getElementById('audio-player'),
  btnEnableEl: document.getElementById('btn-play-text'),
  isShown: false,
  isPlaing: false,
}

// play
window.BX.player.play = function() {
  // ничего не делаем, если нет плеера
  if (!window.BX.player.el) return;

  window.BX.player.el.play();
  window.BX.player.isPlaing = true;
  window.BX.player.el.innerHTML = window.BX.player.playIcon;
};
// stop
window.BX.player.stop = function() {
  // ничего не делаем, если нет плеера
  if (!window.BX.player.el) return;

  window.BX.player.el.pause();
  window.BX.player.isPlaing = false;
  window.BX.player.el.innerHTML = window.BX.player.pauseIcon;
};

// toggle: Play/Stop
window.BX.player.toggle = function() {
  if (window.BX.player.isPlaing == true) {
    window.BX.player.stop();
  } else {
    window.BX.player.play();
  };
};

// Update player SRC after AJAX page reloading
window.BX.player.update = function() {
  if (!window.BX.player.el) return;

  // собираемся доставать номер главы и код книги из path
  const path = window.location.pathname;
  // выкидываем пустые элементы после разделения по '/'
  const path_arr = path.split('/').filter(function (el) {
    return (el != null) && el != '';
  });
  const bookCode = path_arr[path_arr.length-2];
  const chapter = path_arr[path_arr.length-1];

  const audio_prefix = window.BX.player.containerEl.dataset.audioPrefix;
  const newAudioLink = audio_prefix + bookCode + '/' + bookCode + chapter + '.mp3';
  console.log(newAudioLink);
  window.BX.player.el.src = newAudioLink;
};

window.BX.player.showAndPlay = function() {
  // если элемент уже показан, то ничего не делаем
  if (window.BX.player.el) return;

  // создали элемент
  window.BX.player.containerEl.innerHTML = "<audio controls>test</audio><a class='copy' href='https://jesus-portal.ru/life/video/audiobibliya/'>© материал православного портала \"Иисус\"</a>";
  // запомнили html-элемент плеера
  window.BX.player.el = window.BX.player.containerEl.querySelector('audio');
  // показали
  window.BX.player.isShown = true;
  // настроили его (добавили актуальный src)
  window.BX.player.update();
  // настроили события
  window.BX.player.enableListeners();
  // воспроизвели
  window.BX.player.play();
};

window.BX.player.hide = function() {
  // остановили воспроизведение
  window.BX.player.stop();
  // скрыли элемент
  window.BX.player.containerEl.innerHTML = '';
  window.BX.player.el = undefined;
  window.BX.player.isShown = false;
};

// СОБЫТИЯ НАСТРОЕК И ВНУТРЕННИХ ЭЛЕМЕНТОВ
window.BX.player.enableListeners = function() {
  if (!window.BX.player.el) return;

  // когда аудио кончилось
  window.BX.player.el.onended = window.BX.player.hide;
}

// Переключить видимость audio-тэга
window.BX.player.toggleVision = function() {
  if (window.BX.player.isShown == true) {
    window.BX.player.hide();
  } else {
    window.BX.player.showAndPlay();
  };
};

// Кнопка "Озвучить"
if (window.BX.player.btnEnableEl) {
  window.BX.player.btnEnableEl.addEventListener('click', window.BX.player.toggleVision, false);
}

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




