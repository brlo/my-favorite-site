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

var element = document.querySelector('#page-lang-select');
if (element) {
  new Choices(element, {
    allowHTML: true,
    shouldSort: false,
    shouldSortItems: false,
    placeholder: true,
    placeholderValue: 'Язык статьи',
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

// TRANSLIT TABLE
window.en2ruTranslit = function(text) {
  const tr_en_ru_dict = {"q":"й","w":"ц","e":"у","r":"к","t":"е","y":"н","u":"г","i":"ш","o":"щ","p":"з","[":"х","]":"ъ","a":"ф","s":"ы","d":"в","f":"а","g":"п","h":"р","j":"о","k":"л","l":"д",";":"ж","'":"Э"," z":" я","x":"ч","c":"с","v":"м","b":"и","n":"т","m":"ь",",":"б",".":"ю","/":".","Q":"Й","W":"Ц","E":"У","R":"К","T":"Е","Y":"Н","U":"Г","I":"Ш","O":"Щ","P":"З","{":"Х","}":"Ъ","A":"Ф","S":"Ы","D":"В","F":"А","G":"П","H":"Р","J":"О","K":"Л","L":"Д",":":"Ж","|":"/","Z":"Я","X":"Ч","C":"С","V":"М","B":"И","N":"Т","M":"Ь","<":"Б",">":"Ю","?":",","@":"'","#":"№","$":";","^":":","&":"?"};
  return text.replace(/./g, m => (tr_en_ru_dict[m] || m) );
};

// ================================================
// LISTENERS
// ================================================

// КЛИК НА НОМЕР ГЛАВЫ, ПЕРЕХОД К ДРУГОЙ ГЛАВЕ ПИСАНИЯ
function chapterBtnListeners() {
  // Находим все элементы с атрибутом data-chapter
  const chapterLinks = document.querySelectorAll('#menu-chapters a');

  // Добавляем обработчик для каждой ссылки
  chapterLinks.forEach(function(link) {
    link.addEventListener('click', function(event) {
      event.preventDefault();
      loadChapter(link);
    });
  });
};
chapterBtnListeners();

// КЛИК НА КОПИРОВАНИЕ ССЫЛКИ СТРАНИЦЫ
function shareBtnListeners() {
  const shareBtn = document.querySelector('.share-btn');

  if (shareBtn) {
    shareBtn.addEventListener('click', function(event) {
      event.preventDefault();
      BX.shareLink();
    });
  }
};
shareBtnListeners();

// СЛУШАЕМ КЛИК НА ВЫБОР ЯЗЫКА ТЕКСТА
function selectLangListeners() {
  // Выбор языка Библии
  const langSelect = document.getElementById('lang-select');

  if (langSelect) {
    langSelect.addEventListener('change', function(event) {
      // какой язык выбрал пользователь
      const selectedValue = event.target.value;
      selectLang(selectedValue);
    });
  }

  // Выбор языка статей
  const pageLangSelect = document.getElementById('page-lang-select');

  if (pageLangSelect) {
    pageLangSelect.addEventListener('change', function(event) {
      // какой язык выбрал пользователь
      selectPageLang(event.target);
    });
  }
};
selectLangListeners();


// СЛУШАЕМ КЛИК НА ВЫБОР ЯЗЫКА ИНТЕРФЕЙСА В ФУТЕРЕ
function selectUILangListeners() {
  const uiLangSelect = document.getElementById('ui-lang-select');

  if (uiLangSelect) {
    uiLangSelect.addEventListener('change', function(event) {
      selectUILang(event.target);
    });
  }
};
selectUILangListeners();

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

menuBooks.goToSearch = function(form) {
  let text = undefined;
  let lang = undefined;
  // если форму с input внутри передали, то она приоритетнее! Берём значение от туда.
  // Так делаем ради примитивного поля для поиска на главной странице
  if (form) {
    text = form.querySelector('.search-tree-input');
    lang = document.getElementById('lang-select');
  } else {
    text = menuBooks.searchInput.value;
  };

  let params = [];

  if (lang && lang.value.length > 0) { params.push('l=' + lang.value) };
  if (text && text.value.length > 0) { params.push('t=' + text.value) };

  const url = '/' + window.BX.locale + '/search?' + params.join('&');
  document.location.href = url;
}

menuBooks.enableListeners = function () {
  const forms = document.querySelectorAll('.search-form');
  const filterInput = document.getElementById('filter-books');
  const searchIcons = document.querySelectorAll('.search-icon');

  // ОТПРАВКА ФОРМЫ ПОИСКА БИБЛЕЙСКОГО СТИХА
  if (forms.length > 0) {
    // Перебираем все элементы и добавляем обработчик
    forms.forEach(function(form) {
      form.addEventListener('submit', function(e) {
        e.preventDefault(); // Отменить стандартное поведение формы
        menuBooks.goToSearch(e.target);
      });
    });
  };

  if (filterInput) {
    // ВВОД СИМВОЛА В ПОЛЕ ПОИСКА БИБЛЕЙСКОГО СТИХА, ПРИВОДИТ К ФИЛЬТРАЦИИ СПИСКА КНИГ
    filterInput.addEventListener('input', function(e) {
      menuBooks.filterBooks(e.target.value);
    });
  }

  // КЛИК НА ЛУПУ (ТО ЖЕ, ЧТО ОТПРАВКА ФОРМЫ)
  if (searchIcons.length > 0) {
    // Перебираем все элементы и добавляем обработчик
    searchIcons.forEach(function(searchIcon) {
      searchIcon.addEventListener('click', function(e) {
        e.preventDefault();
        // Находим ближайший родительский элемент <form>
        const form = e.target.closest('form');
        menuBooks.goToSearch(form)
      });
    });
  };


  // МЕНЮ С КНИГАМИ
  if (menuBooks.el) {

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
};

menuBooks.enableListeners();


// ТАКЖЕ ЗДЕСЬ ОБРАБОТАЕМ ОТПРАВКУ ФОРМЫ ДЛЯ ПОИСКА ПО СТРАНИЦАМ (PAGES)
enablePageSearchListeners = function () {
  const forms = document.querySelectorAll('.page-search-form');
  const searchIcons = document.querySelectorAll('.page-search-icon');

  // КЛИК НА ЛУПУ (ТО ЖЕ, ЧТО ОТПРАВКА ФОРМЫ)
  if (searchIcons.length > 0) {
    // Перебираем все элементы и добавляем обработчик
    searchIcons.forEach(function(searchIcon) {
      searchIcon.addEventListener('click', function(e) {
        e.preventDefault();
        // Находим ближайший родительский элемент <form>
        const form = e.target.closest('form');
        form.submit();
      });
    });
  };

  // фильтрация меню после ввода в поле для поиска по страницам
  forms.forEach(function(form) {
    const input = form.querySelector('.search-tree-input');
    input.addEventListener('input', function(e) {
      window.filterQueryPages(e.target.value);
    });
  });
};
enablePageSearchListeners();

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

// Предвариетнльная установка начального состояния кнопок и текста статьи в соответствии с куками:
// - размер текста
settingsArea.preInitText = function () {
  const articleEl = document.querySelector('article');
  // убираем все классы, чтобы далее поставить правильный
  if (articleEl) articleEl.classList.remove('text-large', 'text-medium', 'text-small');

  // теперь ставим класс, соответствующий кукам
  if (document.cookie.includes('textSize=3')) {
    // размер текста статьи
    if (articleEl) articleEl.classList.add('text-large');
    // включаем правильную пнопку в настройках
    document.getElementById('text-large-btn').classList.toggle('active', true);
  } else if (document.cookie.includes('textSize=2')) {
    if (articleEl) articleEl.classList.add('text-medium');
    document.getElementById('text-medium-btn').classList.toggle('active', true);
  } else {
    if (articleEl) articleEl.classList.add('text-small');
    document.getElementById('text-small-btn').classList.toggle('active', true);
  };
};
// - цветовая схема
settingsArea.preInitColors = function () {
  if (document.cookie.includes('isNightMode=1')) {
    document.body.classList.toggle('night-mode', true);
    document.getElementById('night-mode-switcher').innerHTML = window.BX.localization.night;
  }
};
settingsArea.preInitText();
settingsArea.preInitColors();

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
  // Если есть в шапке кнопка "настройки"
  if (settingsArea.el) {

    // КЛИК НА "НАСТРОЙКИ"
    settingsArea.btn.addEventListener('click', function(e) { e.preventDefault(); settingsArea.settingsBtnClicked() }, false);

    // КЛИК НА "ДЕНЬ/НОЧЬ"
    const nightModeSwitcher = document.getElementById('night-mode-switcher');
    if (nightModeSwitcher) {
      nightModeSwitcher.addEventListener('click', function(e) {
        e.preventDefault();
        window.switchNightMode();
      });
    }

    // КЛИК НА РАЗМЕР ТЕКСТА
    for (const barBtn of settingsArea.textSizeBar.btns) {
      barBtn.addEventListener('click', function(e) { e.preventDefault(); settingsArea.textSizeBar.someTextSizeBtnClicked(e) }, false);
    };

    // Клик за границами меню прячет меню
    document.addEventListener('click', e => {
      if (settingsArea.isShown) {
        const el = e.target;

        const isBtnClicked = settingsArea.btn === el;
        const isClickInsideMenu = settingsArea.el.contains(el);
        // прячем меню
        // нажали не на иконку показа, не на элементы меню
        if (!isBtnClicked && !isClickInsideMenu) settingsArea.hide();
      };
    });

  };
};

// Инициализация
settingsArea.enableListeners();

// Аудио-плеер
window.BX.player = {
  el: undefined, // audio tag
  containerEl: document.getElementById('audio-player'),
  btnEnableEl: document.getElementById('btn-play-text'),
  isShown: false,
  isPlaing: false,
  isAutoplay: false,
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

  let newAudioLink = '';
  const audio_src = window.BX.player.containerEl.dataset.audioSrc;
  const audio_prefix = window.BX.player.containerEl.dataset.audioPrefix;
  if (audio_src) {
    newAudioLink = audio_src + '.mp3';
  } else {
    newAudioLink = audio_prefix + bookCode + '/' + bookCode + chapter + '.mp3';
  }
  console.log(newAudioLink);
  window.BX.player.el.src = newAudioLink;

  // если в nextChapter устанавливали автозапуск после переключения главы,
  // то сразу запускать воспроизведение, так как апереключение автоматически произошло после окочания трэка
  if (window.BX.player.isAutoplay == true) {
    window.BX.player.play();
    window.BX.player.isAutoplay == false;
  };
};

window.BX.player.showAndPlay = function() {
  // если элемент уже показан, то ничего не делаем
  if (window.BX.player.el) return;

  // создали элемент
  if (window.BX.player.containerEl.dataset.audioPrefix) {
    window.BX.player.containerEl.innerHTML = "<audio controls>test</audio><a class='copy' href='https://jesus-portal.ru/life/video/audiobibliya/'>© материал православного портала \"Иисус\"</a>";
  } else {
    window.BX.player.containerEl.innerHTML = "<audio controls>test</audio>";
  }
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

// Переключить видимость audio-тэга
window.BX.player.nextChapter = function() {
  if (window.BX.player.isShown == true) {
    // AJAX переключаем номер активной главы
    const currChapter = document.getElementById('current-address').dataset.chapter;
    const nextChapter = parseInt(currChapter, 10) + 1;
    const nextChapterEl = document.querySelector('#menu-chapters #ch-' + nextChapter);
    if (nextChapterEl) {
      window.BX.player.isAutoplay = true;
      nextChapterEl.click();
    } else {
      window.BX.player.hide();
    };
  };
};

// СОБЫТИЯ НАСТРОЕК И ВНУТРЕННИХ ЭЛЕМЕНТОВ
window.BX.player.enableListeners = function() {
  if (!window.BX.player.el) return;

  // КОГДА АУДИО КОНЧИЛОСЬ - ЧТО ДЕЛАТЬ:
  window.BX.player.el.onended = window.BX.player.nextChapter;
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

// ---------------- FILTER MENU ------------------

window.filterQueryPages = function(text, isNeedTranslit) {
  const root = document.querySelectorAll(".menu-tree");
  const els = document.querySelectorAll(".menu-tree .menu-link");
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
    // subjects.forEach(el => el.classList.remove('hidden'));
    // els.forEach(el => el.classList.remove('hidden'));
    // удалить общую метку
    root.forEach(el => { el.classList.remove('hidden-children') });
    // удалить метку с подсвеченных элементов
    const visibleEls = document.querySelectorAll(".menu-tree .visible");
    visibleEls.forEach(el => el.classList.remove('visible'));
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
        el.classList.add('visible');
        isSomethingMatch = true;
      } else {
        el.classList.remove('visible')
      };
    });

    // если есть совпадения, то ставим общую метку на весь блок
    if (isSomethingMatch) {
      root.forEach(el => { el.classList.add('hidden-children') });
    } else {
      // если нет результатов и транслит ещё не пробовали, то надо попробовать транслит поискать
      if (isNeedTranslit != true) {
        filterQueryPages(text, true);
      }
    };
  };
};

// ================================================================
// =============== кнопка "вернуться вверх страницы" ==============
// ================================================================
const scrollToTopBtn = document.getElementById('scroll-to-top-btn');

if (scrollToTopBtn) {
  // Добавляем класс по умолчанию
  scrollToTopBtn.classList.add('scroll-down');

  window.addEventListener('scroll', () => {
    if (window.scrollY > 2000) {
      // Прокрутка ниже 2000px - показываем стрелку вверх
      scrollToTopBtn.classList.remove('scroll-down');
      scrollToTopBtn.classList.add('scroll-up');
    } else {
      // Прокрутка выше 2000px - показываем стрелку вниз
      scrollToTopBtn.classList.remove('scroll-up');
      scrollToTopBtn.classList.add('scroll-down');
    }
  });

  scrollToTopBtn.addEventListener('click', () => {
    if (window.scrollY > 2000) {
      // Если ниже 2000px - прокрутка наверх
      window.scrollTo({
        top: 0,
        behavior: 'smooth'
      });
    } else {
      // Если выше 2000px - прокрутка вниз
      window.scrollTo({
        top: document.body.scrollHeight,
        behavior: 'smooth'
      });
    }
  });
}

window.BX.shareLink = function(url) {
  if (url == undefined) { url = window.location.href };
  const url_dec = decodeURIComponent(url); // window.location.href
  BX.tools.copyText(url_dec)
  BX.notifications.addNotification('<t>' + BX.localization.linkIsCopied + ':</t>' + url_dec);
}


// Создаёт ссылки (цепь) возле заголовков, для копирования ссылки с якорем
window.BX.addShareHeaders = function() {
  const headers = document.querySelectorAll('h1[id], h2[id], h3[id], h4[id]');

  headers.forEach(header => {
    const link = document.createElement('a');
    if (header.tagName === 'H1') {
      // Текущий URL без фрагмента (#...)
      link.href = window.location.href.split('#')[0];
    } else {
      link.href = '#' + header.id;
    }
    link.className = 'copy-anchor';

    link.addEventListener('click', function (e) {
      e.preventDefault();
      window.BX.shareLink(e.target.href)
    });

    header.insertAdjacentElement('afterbegin', link);
  });
};
window.BX.addShareHeaders();


// Ссылки внутри text-bar иногда маленькие, тяжело нажать. Если был мисс-клик, то надо найти внутри элемента ссылку и донажать её.
window.BX.insideLinksClicker = function() {
  const barEls = document.querySelectorAll('.bar-el.btn'); // исправлен селектор (добавлены точки)

  barEls.forEach(el => {
    el.addEventListener('click', function(e) {
      // Проверяем, есть ли внутри элемента ссылка <a>
      const link = el.querySelector('a');

      if (link && !e.target.closest('a')) {
        // Если ссылка есть и клик был не по ней (или её потомкам),
        // то предотвращаем действие по умолчанию и программно кликаем по ссылке
        e.preventDefault();
        link.click();
      }
    });
  });
};
window.BX.insideLinksClicker();
