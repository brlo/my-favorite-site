// NOTIFICATION

window.BX.notifications = {
  stack: [],
};

// Показ одного уведомления из стэка
window.BX.notifications.show = function () {
  // если сейчас уже нарисовано увдеомление, то ничего не делаем
  // так как по таймауту из стэка само нарисуется слдующее уведомление
  if (document.getElementById('popup-notif')) return;
  // в стэке пусто
  if (BX.notifications.stack.length < 1) return;

  let htmlText = BX.notifications.stack.shift();

  if (htmlText == undefined) return;

  let el = document.createElement('div');

  el.id = 'popup-notif';
  el.innerHTML = htmlText;
  body = document.getElementsByTagName('body')[0];
  body.appendChild(el);

  // через 2 сек - затухаем
  setTimeout(() => document.getElementById('popup-notif').style.opacity = '0', 2000);
  // через 2.5 сек - исчезаем и рисуем следующее уведомлене
  setTimeout(function() {
    el = document.getElementById('popup-notif');
    body = document.getElementsByTagName('body')[0];
    body.removeChild(el);
    BX.notifications.show();
  }, 2500);
}

// Добавление уведомления в очередь на показ
window.BX.notifications.addNotification = function (htmlText) {
  BX.notifications.stack.push(htmlText);
  BX.notifications.show();
};


// ==========================================================================
// ==========================================================================
//       SELECT-BAR
// ==========================================================================
// ==========================================================================

// Меню для работы с текстом
window.selectBar = {
  isEnabled: false,
  el: document.getElementById('select-bar'),
  // регулярка для валидации введённого значения (пример: L1-3,5,10-11)
  // TIP: всего допускается не более 7 адресов.
  fragmentRegexp: /^L(\d{1,3}|\d{1,3}-\d{1,3})(,(\d{1,3}|\d{1,3}-\d{1,3})){0,6}$/,
};

selectBar.enable = function () {
  selectBar.el.classList.remove('hidden');
  selectBar.isEnabled = true;
};

selectBar.disable = function () {
  // прячем селект-бар
  selectBar.el.classList.add('hidden');
  // прячем меню копирования (вдруг было открыто)
  selectBar.copyBurger.hide();
  // отключаем режим выделения стихов (вдруг был включен)
  if (window.BX.options.isSelectMode === true) selectBar.selectModeClicked();
  // выключаем сам селект-бар
  selectBar.isEnabled = false;
};

selectBar.getSelectedText = function () {
  let lightClass = 'highlighted';
  let selectedLines = Array.prototype.slice.call( document.getElementsByClassName(lightClass) );

  if (selectedLines < 1) return '';

  let chunks = [];
  for (const line of selectedLines) {
    // убираем пробелы по краям
    chunks.push( BX.tools.strip(line.textContent) );
  };

  // лучше попробовать слить через \n, но сходу не получилось
  let text = chunks.join(' ');
  // убираем точки по краям
  text = BX.tools.stripDots(text);

  return text;
}

selectBar.getSelectedAddress = function () {
  let fragmentStr = window.location.hash;

  // это строка, не пустая и не только с решёткой
  if (typeof fragmentStr !== 'string') return '';
  if (fragmentStr == '') return '';
  if (fragmentStr == '#') return '';

  // фрагмент без первого символа, то есть без "#"
  let lineStr = fragmentStr.substr(1);

  let regexpLines = selectBar.fragmentRegexp;

  // адрес линий построен правильно
  if (!regexpLines.test(lineStr)) return '';

  // имеем строку: L1-3,5,10-11
  // убираем L, делим по ",", берём 7 элементов массива
  const lines = lineStr.substr(1)

  let bookInfo = document.getElementById('current-address').dataset;
  let bookName = bookInfo.bookShortName;
  let chapter = bookInfo.chapter;

  let address = bookName + '. ' + chapter + ':' + lines;

  return address;
}

selectBar.selectModeClicked = function () {
  let selectMode = document.getElementById('select-mode-btn');

  if (window.BX.options.isSelectMode != true) {
    window.BX.options.isSelectMode = true;
    selectMode.classList.add('active');
  } else {
    window.BX.options.isSelectMode = false;
    selectMode.classList.remove('active');
  };
  return;
};

selectBar.copyTextAndAddressClicked = function () {
  // сначала прячем контекстное меню, в котором эта ссылка была нажата
  selectBar.copyBurgerClicked();

  let text = selectBar.getSelectedText();
  let address = selectBar.getSelectedAddress();
  let result = '"' + text + '"' + ' (' + address + ')';

  BX.tools.copyText(result);
  BX.notifications.addNotification(
    '<t>' + window.BX.localization.copyTitle + ':</t>' +
    '"' + text.slice(0,30) + '..."' +
    '<br>' +
    '(' + address + ')'
  );
  return;
};

selectBar.copyTextClicked = function () {
  // прячем контекстное меню, в котором эта ссылка была нажата
  selectBar.copyBurger.hide();

  const text = selectBar.getSelectedText();

  BX.tools.copyText(text);
  BX.notifications.addNotification('<t>' + window.BX.localization.copyTitle + ':</t>' + text.slice(0,30) + '...');
  return;
};

selectBar.copyAddressClicked = function () {
  // прячем контекстное меню, в котором эта ссылка была нажата
  selectBar.copyBurger.hide();

  const href = window.location.href;
  const address = selectBar.getSelectedAddress();

  BX.tools.copyTextLink(address, href);
  BX.notifications.addNotification('<t>' + window.BX.localization.copyTitle + ':</t>' + address);
  return;
};

selectBar.copyLinkClicked = function () {
  // прячем контекстное меню, в котором эта ссылка была нажата
  selectBar.copyBurger.hide();

  const link = window.location.href;
  BX.tools.copyText(link);
  BX.notifications.addNotification('<t>' + window.BX.localization.copyTitle + ':</t>' + link);
  return;
};

// =======
// COPY BURGER
// =======

// Меню копирования: элемент
selectBar.copyBurger = {
  // меню
  el: document.getElementById('copy-burger-menu'),
  // Клик на elIcon показывает el
  elIcon: document.getElementById('copy-burger-icon'),
  isShown: false,
}

// ВКЛ
selectBar.copyBurger.show = function () {
  selectBar.copyBurger.el.classList.remove('hidden');
  selectBar.copyBurger.isShown = true;
};

// ВЫКЛ
selectBar.copyBurger.hide = function () {
  selectBar.copyBurger.el.classList.add('hidden');
  selectBar.copyBurger.isShown = false;
};

// КЛИК
selectBar.copyBurgerClicked = function () {
  if (selectBar.copyBurger.isShown === false) {
    selectBar.copyBurger.show();
  } else {
    selectBar.copyBurger.hide();
  };
};

// СОБЫТИЯ ВСЕГО СЕЛЕКТ_БАРА
selectBar.enableListeners = function () {
  if (!selectBar.el) return;

  let selectMode = document.getElementById('select-mode-btn');
  selectMode.addEventListener('click', selectBar.selectModeClicked, false);

  let copyTextAndAddress = document.getElementById('copy-text-address-btn');
  copyTextAndAddress.addEventListener('click', selectBar.copyTextAndAddressClicked, false);

  let copyAddress = document.getElementById('copy-address-btn');
  copyAddress.addEventListener('click', selectBar.copyAddressClicked, false);

  let copyText = document.getElementById('copy-text-btn');
  copyText.addEventListener('click', selectBar.copyTextClicked, false);

  let copyLink = document.getElementById('copy-link-btn');
  copyLink.addEventListener('click', selectBar.copyLinkClicked, false);

  let copyBurgerIcon = document.getElementById('copy-burger-icon');
  copyBurgerIcon.addEventListener('click', selectBar.copyBurgerClicked, false);

  // Клик за границами меню прячет меню
  document.addEventListener('click', event => {
    if (selectBar.copyBurger.isShown) {
      const el = event.target;

      const isIconClicked = selectBar.copyBurger.elIcon.contains(el);
      const isClickInsideMenu = selectBar.copyBurger.el.contains(el);
      // прячем меню
      // нажали не на иконку показа, не на элементы меню
      if (!isIconClicked && !isClickInsideMenu) selectBar.copyBurger.hide();
    };
  });
};

selectBar.enableListeners();

// =======================================================================
// =======================================================================
// ПОДСВЕТКА СТРОК, ЗАГРУЗКА/СОХРАНЕНИЕ ИЗ/В FRAGMENT
// =======================================================================
// =======================================================================

// Отдаёт номера строк из фрагмента URL.
// пример: http://.../path#L1-2,5,10-11
// -> [1,2,3,5,10,11]
const getLinesArrFromUrlFragment = function() {
  // фрагмент из URL
  let fragmentStr = window.location.hash;

  // это строка, не пустая и не только с решёткой
  if (typeof fragmentStr !== 'string') return '';
  if (fragmentStr == '') return '';
  if (fragmentStr == '#') return '';

  // фрагмент без первого символа, то есть без "#"
  let lineStr = fragmentStr.substr(1);

  // регулярка для валидации введённого значения (пример: L1-3,5,10-11)
  // TIP: всего допускается не более 7 адресов.
  let regexpLines = selectBar.fragmentRegexp;

  // адрес линий построен правильно
  if (!regexpLines.test(lineStr)) return '';

  // строим последовательность строк, которые нужно подсветить
  // хотим получить: [1,2,3,5,10,11]

  // имеем строку: L1-3,5,10-11
  // убираем L, делим по ",", берём 7 элементов массива
  const lines = lineStr.substr(1).split(',').slice(0, 6);
  const linesNums = [];

  // проходим по элементам массива с адресами
  lines.forEach(function(line) {
    line = line.split('-');
    if (line.length == 1) {
      // 1 элемент
      linesNums.push(parseInt(line[0]));

    } else if (line.length == 2) {
      // промежуток: 2 элемента
      let start = parseInt(line[0]);
      let end = parseInt(line[1]);

      if (start > 300) return;
      if (end > 300) return;

      let seq = [];
      for (var i = start; i <= end; i++) {
        seq.push(i);
      };

      linesNums.push(...seq);
      // или так, чтобы старые браузеры работали:
      // seq.forEach(function(l) {
      //   linesNums.push(l);
      // });
    };
  });

  return linesNums;
};

// подсветка строк по переданному в url-fragment параметру L.
// Пример: #L1,20-23
const highlightLines = function() {
  linesArr = getLinesArrFromUrlFragment();

  // проверяем, что пришёл массив
  if (Object.prototype.toString.call(linesArr) === '[object Array]' && linesArr.length > 0) {
    for (const l of linesArr) {
      // подсветить одну конкретную строку (verse)
      let elText = document.getElementById('T' + l);
      if (elText) elText.classList.add('highlighted');
    };

    // прокручиваем скрол к первому подсвеченному элементу.
    // элемент окажется у верхнего края экрана
    let elText = document.getElementById('T' + linesArr[0]);
    elText.scrollIntoView();
    // чтобы было красиво, приподнимемся ещё чуть-чуть выше (на 100px)
    window.scrollBy(0,-100);
  };
}

highlightLines();

// ---------------------
// сохранен адрес выделенных строк в fragment
// ---------------------
const saveHightlightedLinesToFragment = function() {
  let lightClass = 'highlighted';
  let addressElements = [];
  let linesHighlighted = Array.prototype.slice.call( document.getElementsByClassName(lightClass) );

  if (linesHighlighted.length > 0) {
    // добываем номера строкы
    let lineNumbers = [];
    for (const line of linesHighlighted) {
      lineNumbers.push(
        parseInt(line.dataset.line)
      );
    };

    // переводим массив в последовательности:
    // пример: [1,2,3,10] -> [[1,2,3], [10]]
    let seqs = window.arrayToSeqs(lineNumbers);

    // строим массив из готовых для фрагмента строк
    for (const seq of seqs) {
      if (seq.length == 1) {
        // "первый"
        addressElements.push( String(seq[0]) );
      } else if (seq.length > 1) {
        // "первый-последний"
        addressElements.push( String(seq[0]) + '-' + String(seq[seq.length - 1]) );
      };
    };
  };

  if (addressElements.length > 0) {
    // собираем адрес выделенных строк
    addressFragment = 'L' + addressElements.join(',');

    // после установки фрагмента, скролл уедете в браузере к упор к нему. Некрасиво.
    // сохранил текущую позицию скролла, чтобы потом её восстановить
    let oldScrollPosition = window.scrollY;
    // почему-то в Chrome позиция 0,0 не восстанавливается, и происходит нежелательный пееход к фрагменту
    if (oldScrollPosition == 0) oldScrollPosition = 1;

    window.location.hash = addressFragment;
    window.scrollTo(0, oldScrollPosition);
  } else {
    history.pushState({}, document.title, window.location.pathname + window.location.search);
  }
};

// =============================================================================
// Выделение линии
// =============================================================================

// Последняя отдельно выделенная строка. Должна быть в корне, чтобы сохранялась.
var lastLineSelected = null;
// Выделенные через Shift линии
var lastShiftLineSelectedRange = null;

// обработка клика на номер строки
const lineNumberClicked = function(event, isTextClicked = false) {
  // снимаем все нативные-выделения текста, которые хотя и блокируется в CSS,
  // но в Chrome всё равно иногда срабатывают. Выделения текста нам тут не нужны.
  // Мы сами всё что нужно выделяем
  if (isTextClicked === false) {
    document.getSelection().removeAllRanges();
  }

  let elNum = event.target;
  let lineNumber = elNum.dataset.line;
  let lightClass = 'highlighted';
  let countOfHightlightedWas = document.getElementsByClassName(lightClass).length;

  // Ищем текст строки.
  // передают элемент с номером строки (на нём слушаем клики)
  // но подсвечиваем текст, а не номер.
  let elText = document.getElementById('T' + lineNumber);
  // или так:
  // let elText = elNum.nextElementSibling;

  // нажат CTRL: значит просто переключаем класс у кликнутой строки
  // в винде нужен CTRL, в маке — metaKey
  // Но в Firefox баг, поэтому приходится вот эти все getModifierState добавлять
  if (window.event.ctrlKey ||
      window.event.metaKey ||
      // либо в нашем меню включен select-mode (надо для мобил, т.к. они не могут нажать CTRL)
      window.BX.options.isSelectMode ||
      window.event.getModifierState("OS") ||
      window.event.getModifierState("Super") ||
      window.event.getModifierState("Win")) {
    // console.log('CTRL');
    if (elText.classList.contains(lightClass)) {
      elText.classList.remove(lightClass);
    } else {
      elText.classList.add(lightClass);
      // запоминаем, как последнюю отдельно нажатую строку
      lastLineSelected = lineNumber;
      // если были выделения через shift, то они должны остаться, стирать их не будем,
      // а значит и помнить их уже нен надо
      lastShiftLineSelectedRange = null;
    };

  // нажат SHIFT: значит просто переключаем класс у кликнутой строки
  } else if (window.event.shiftKey && lastLineSelected != null) {
    // console.log('SHIFT');
    // СНИМАЕМ СТАРОЕ ВЫДЕЛЕНИЕ:
    // сначала снимаем предыдущее выделение-через-Shift (если оно есть)
    // (которое могли делать прям только что, но в другую сторону)
    if (lastShiftLineSelectedRange != null && lastShiftLineSelectedRange.length == 2) {
      let startLine = parseInt(lastShiftLineSelectedRange[0]);
      let endLine = parseInt(lastShiftLineSelectedRange[1]);

      for (var n = startLine; n <= endLine; n++) {
        // находим строку
        let el = document.getElementById('T' + n);
        // подсвечиваем, если ещё не подсвечена
        if (el.classList.contains(lightClass)) {
          el.classList.remove(lightClass);
        }
      };
    };

    // ДОБАВЛЯЕМ НОВОЕ ВЫДЕЛЕНИЕ
    currentLine = lineNumber;

    // находим меньшее и большее число
    let rangeArr = [currentLine, lastLineSelected].sort(window.sortArrayInt);
    let startLine = parseInt(rangeArr[0]);
    let endLine = parseInt(rangeArr[1]);

    for (let j = startLine; j <= endLine; j++) {
      // находим строку
      let el = document.getElementById('T' + j);
      // подсвечиваем, если ещё не подсвечена
      if (!el.classList.contains(lightClass)) {
        el.classList.add(lightClass);
      };
    };

    // запоминаем последние выделенные через Shift линии,
    // чтобы при последующих попытках снимать это выделение,
    // если перевыделяем в противоположном направлении
    lastShiftLineSelectedRange = [startLine, endLine];

  // Просто 1 клик мышкой. Без клавишь.
  } else {
    // console.log('SINGLE');
    let isElementAlreadyHighlighted = elText.classList.contains(lightClass);

    // если есть другие выделенные строки, то снимаем все выделения
    if (countOfHightlightedWas > 0) {
      // снимаем старые выделения
      let olds = Array.prototype.slice.call( document.getElementsByClassName(lightClass) );

      for (const lightedEl of olds) {
        lightedEl.classList.remove(lightClass);
      };
    };

    // если у нажатого элемента не было выделения, то выделяем
    if (!isElementAlreadyHighlighted) {
      elText.classList.add(lightClass);
      // запоминаем, как последнюю отдельно нажатую строку
      lastLineSelected = lineNumber;
      // забываем выделения через Shift
      lastShiftLineSelectedRange = null;
    };
  };

  // Прячем или показываем меню для работы с текстом, в зависимости от того, есть ли выделенные строки
  let countNow = document.getElementsByClassName(lightClass).length;

  if (countOfHightlightedWas < 2 && countNow > 0) {
    // было много, стало 0 -> прячем селект-бар (он теперь не нужен).
    window.selectBar.enable();
  } else if (countNow == 0 && countOfHightlightedWas > 0) {
    // было 0, стало много -> прячем селект-бар (начали работать с тектом).
    window.selectBar.disable();
    lastLineSelected = null;
    lastShiftLineSelectedRange = null;
  };

  // Ок. Мы закончили с визуальной частью. Всё выделено.
  // Теперь надо сохранить адрес выделенных строк в фрагмент и положить в историю.
  saveHightlightedLinesToFragment();
};

// клик на текст стиха
function lineTextClicked(event) {
  // если режим выделения включен, то выделение работает
  // не только по клику на номер стиха, но и на сам стих
  if (window.BX.options.isSelectMode == true) {
    lineNumberClicked(event, true);
  };
  return;
};

const addListenersForHighlightVerses = function(event) {
  // прослушка кликов на номерах строк
  var elements = Array.prototype.slice.call( document.getElementsByClassName('verse-line') );
  for (const elNum of elements) elNum.addEventListener('click', lineNumberClicked, false);

  // прослушка кликов на тексте строк
  var elements = Array.prototype.slice.call( document.getElementsByClassName('verse-text') );
  for (const elText of elements) elText.addEventListener('click', lineTextClicked, false);
};

addListenersForHighlightVerses();

// =======================================================================
// =======================================================================
// Динамический переход по главам
// =======================================================================
// =======================================================================

// подгрузка текста другой главы
function loadChapter(linkEl) {
  let path = linkEl.getAttribute('href');
  var xmlhttp = new XMLHttpRequest();

  xmlhttp.onreadystatechange = function() {
    if (xmlhttp.readyState == XMLHttpRequest.DONE) { // XMLHttpRequest.DONE == 4
      if (xmlhttp.status == 200) {
        // рендерим новый контент
        document.getElementById("chapter-content").innerHTML = xmlhttp.responseText;
        // вешаем события
        addListenersForHighlightVerses();
        // переключаем адрес стрианцы
        window.history.pushState({}, '', path);
        // прям меню работы с текстом
        selectBar.disable();
      }
      else if (xmlhttp.status == 400) {
        alert('Erorr 400');
      }
      else {
        alert('Not trivial error (VFF7)');
      }
    }
  };

  // path.substr(3) - выкидываем из начала ссылки /ru
  xmlhttp.open("GET", '/' + window.BX.locale + '/chapters/' + path.substr(3), true);
  xmlhttp.send();
};

// Чтобы работала кнопка "Назад" после того как искусственно наполнили историю через window.history.pushState
window.onpopstate = (event) => {
  // window.location.replace(event.path[0].location.href);
  // то же самое, только проще:
  var state = event.state;
  if (state !== null) {
    window.location.replace(location.href);
  };
};

// =============================================================================
// Ссылка на выделенный текст
// =============================================================================

// window.getSelectedTextLink = function() {
//   // if (window.getSelection()) return;

//   let bookInfo = document.getElementById('current-address').dataset;
//   let bookShortName = bookInfo.bookShortName;
//   let chapter = bookInfo.chapter;
//   let line1 = window.getSelection().anchorNode.parentNode.dataset.line;
//   let line2 = window.getSelection().extentNode.parentNode.dataset.line;

//   let lines;

//   if (line1 == line2) {
//     // 5
//     // выделена одна строка, просто указываем её номер
//     lines = line1;
//   } else {
//     // 5-10
//     // выделено несколько строк, указываем их через дефис
//     let min, max;
//     [min, max] = [parseInt(line1), parseInt(line2)].sort(function(a, b) { return a - b });
//     lines = min + '-' + max;
//   };

//   let link = bookShortName + '. ' + chapter + ':' + lines;

//   return link;
// };



// // запоминаем выделенный текст
// window.saveSelectedTextLink = function() {
//   let link = window.getSelectedTextLink();
//   let text = window.getSelectedText();
//   text = text.replace(/\n/g, ' ');

//   let quote = '"' + text + '" ' + '(' + link + ')';

//   window.savedTextLink = quote;

//   return quote;
// };

// // Предлагаем пользователю скопировать последний выделенный текст
// window.copySelectedTextLink = function() {
//   window.copyTextToClipboard(window.savedTextLink);
// };

// // Выделенный текст
// window.getSelectedText = function() {
//   if (window.getSelection) {
//     return window.getSelection().toString();
//   } else if (document.selection) {
//     return document.selection.createRange().text;
//   }
//   return '';
// };

// // Предложение пользователю скопировать текст
// window.copyTextToClipboard = function(text) {
//   window.prompt("Copy to clipboard: Ctrl+C, Enter", text);
// }
