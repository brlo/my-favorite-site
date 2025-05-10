// Перенсти функции в хэш. Вызывать их из кэша
const localization = {
  ar: {
    copyTitle: 'نسخ',
    day: 'يوم',
    night: 'ليلة',
    linkIsCopied: 'تم نسخ الرابط',
  },
  cn: {
    copyTitle: '复制的',
    day: '天',
    night: '夜晚',
    linkIsCopied: '链接已复制',
  },
  de: {
    copyTitle: 'kopiert',
    day: 'Tag',
    night: 'Nacht',
    linkIsCopied: 'Der Link wurde kopiert',
  },
  en: {
    copyTitle: 'Copied',
    day: 'Day',
    night: 'Night',
    linkIsCopied: 'The link is copied',
  },
  gr: {
    copyTitle: 'αντιγράφηκε',
    day: 'Ημέρα',
    night: 'Νύχτα',
    linkIsCopied: 'Ο σύνδεσμος αντιγράφεται',
  },
  il: {
    copyTitle: 'מוּעֲתָק',
    day: 'יְוֹם',
    night: 'לַיְלָה',
    linkIsCopied: 'הקישור מועתק',
  },
  jp: {
    copyTitle: 'コピーされました',
    day: '昼',
    night: '夜',
    linkIsCopied: 'リンクがコピーされました',
  },
  ru: {
    copyTitle: 'Скопировано',
    day: 'День',
    night: 'Ночь',
    linkIsCopied: 'Ссылка скопирована',
  },
  "es": { // испанский
    "copyTitle": "Copiado",
    "day": "Día",
    "night": "Noche",
    "linkIsCopied": "Enlace copiado"
  },
  "fr": { // французский
    "copyTitle": "Copié",
    "day": "Jour",
    "night": "Nuit",
    "linkIsCopied": "Lien copié"
  },
  "in": { // хинди
    "copyTitle": "कॉपी किया गया",
    "day": "दिन",
    "night": "रात",
    "linkIsCopied": "लिंक कॉपी किया गया"
  },
  "ir": { // персидский
    "copyTitle": "کپی شد",
    "day": "روز",
    "night": "شب",
    "linkIsCopied": "لینک کپی شد"
  },
  "it": { // итальянский
    "copyTitle": "Copiato",
    "day": "Giorno",
    "night": "Notte",
    "linkIsCopied": "Link copiato"
  },
  "ke": { // суахили
    "copyTitle": "Imenakiliwa",
    "day": "Mchana",
    "night": "Usiku",
    "linkIsCopied": "Kiunga kimenakiliwa"
  },
  "kr": { // корейский
    "copyTitle": "복사됨",
    "day": "낮",
    "night": "밤",
    "linkIsCopied": "링크가 복사되었습니다"
  },
  "rs": { // сербский
    "copyTitle": "Копирано",
    "day": "Дан",
    "night": "Ноћ",
    "linkIsCopied": "Линк је копиран"
  },
  "tm": { // туркменский
    "copyTitle": "Kopyalandy",
    "day": "Gün",
    "night": "Gije",
    "linkIsCopied": "Link kopyalandy"
  },
  "tr": { // турецкий
    "copyTitle": "Kopyalandı",
    "day": "Gün",
    "night": "Gece",
    "linkIsCopied": "Bağlantı kopyalandı"
  },
  "uz": { // узбекский
    "copyTitle": "Nusxa olindi",
    "day": "Kun",
    "night": "Tun",
    "linkIsCopied": "Havola nusxa olindi"
  },
  "vn": { // вьетнамский
    "copyTitle": "Đã sao chép",
    "day": "Ngày",
    "night": "Đêm",
    "linkIsCopied": "Đã sao chép liên kết"
  }
};

window.BX = {
  locale: document.documentElement.lang,
  options: {
    // включен ли режим выделения стихов (нужен мобилам, которые не могут нажать CTRL)
    isSelectMode: false,
  },
  tools: {
    strip: function (str) {
      return ( str || '' ).replace( /^\s+|\s+$/g, '' );
    },

    stripDots: function (str) {
      return ( str || '' ).replace( /^[\s\.\,\?\!\;]+|[\s\.\,\;]+$/g, '' );
    },

    copyText: function (text) {
      var dummy = document.createElement('input');

      document.body.appendChild(dummy);
      dummy.value = text;

      // clear selection
      if (window.getSelection) {
        if (window.getSelection().empty) {  // Chrome
          window.getSelection().empty();
        } else if (window.getSelection().removeAllRanges) {  // Firefox
          window.getSelection().removeAllRanges();
        }
      };

      dummy.select();
      document.execCommand('copy');
      document.body.removeChild(dummy);
    },

    copyTextLink: function (textBefore, LinkText, TextAfter, href) {
      const html = textBefore + '<a href="' + href + '">' + LinkText + '</a>' + TextAfter;
      const dummy = document.createElement('div');

      // clear selection
      if (window.getSelection) {
        if (window.getSelection().empty) {  // Chrome
          window.getSelection().empty();
        } else if (window.getSelection().removeAllRanges) {  // Firefox
          window.getSelection().removeAllRanges();
        }
      };

      document.body.appendChild(dummy);
      dummy.innerHTML = html;
      const range = document.createRange();
      range.selectNode(dummy);
      window.getSelection().addRange(range);

      document.execCommand('copy');
      document.body.removeChild(dummy);
    },
  },
}

window.BX.localization = localization[ window.BX.locale ];

// COOKIES LIBS
function setCookie(cname, cvalue, exdays) {
  const d = new Date();
  d.setTime(d.getTime() + (exdays * 24 * 60 * 60 * 1000));
  let expires = "expires="+d.toUTCString();
  document.cookie = cname + "=" + cvalue + ";" + expires + ";path=/";
}

function getCookie(cname) {
  let name = cname + "=";
  let ca = document.cookie.split(';');
  for(let i = 0; i < ca.length; i++) {
    let c = ca[i];
    while (c.charAt(0) == ' ') {
      c = c.substring(1);
    }
    if (c.indexOf(name) == 0) {
      return c.substring(name.length, c.length);
    }
  }
  return "";
}

function isMobileDevice() {
  return (( window.innerWidth <= 400 ) && ( window.innerHeight >= 400 ));
}

// найти параметр в query (обращаться как к хэшу: params.my_param_name)
const params = new Proxy(new URLSearchParams(window.location.search), {
  get: (searchParams, prop) => searchParams.get(prop),
});

// // ON READY FUNCTION
// function docReady(fn) {
//   // see if DOM is already available
//   if (document.readyState === "complete" || document.readyState === "interactive") {
//     // call on next available tick
//     setTimeout(fn, 1);
//   } else {
//     document.addEventListener("DOMContentLoaded", fn);
//   }
// }

// docReady(function() {
//   const el = document.body;
//   const nightClass = "night-mode";

//   console.log(getCookie("isNightMode"));
//   if (getCookie("isNightMode") == 1) {
//     el.classList.add(nightClass);
//   } else {
//     el.classList.remove(nightClass);
//   }
// });

// NIGHT MODE SWITCHER (переключение туда-сюда)
window.switchNightMode = function() {
  const modeSwitcher = document.getElementById("night-mode-switcher");
  const body = document.body;
  const nightClass = "night-mode";

  if (body.classList.contains(nightClass)) {
    body.classList.remove(nightClass);
    setCookie('isNightMode', 0, 999);
    modeSwitcher.innerHTML = window.BX.localization.day;
  } else {
    body.classList.add(nightClass);
    setCookie('isNightMode', 1, 999);
    modeSwitcher.innerHTML = window.BX.localization.night;
  }

  return false;
};

// выбор языка контента Библии (в выпыдающем списке языков возле текста)
function selectLang() {
  const langInput = document.getElementById('lang-select');
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

  window.location.href = path;
};


// выбор языка контента (в выпыдающем списке языков возле текста)
function selectPageLang(el) {
  const langInput = el;
  const fullPath = langInput.value;

  // Элемент в котором хранятся все идентификаторы адреса
  // const bookInfo = document.getElementById('current-address').dataset;

  const path =
    fullPath + '/' +
    window.location.search +
    window.location.hash;

  window.location.href = path;
};

// Клик на выбор языка интерфейса в футере
function selectUILang(el) {
  const langUIInput = el;
  const newUILang = langUIInput.value;

  // Элемент в котором хранятся все идентификаторы адреса
  // const bookInfo = document.getElementById('current-address').dataset;

  let new_path = window.location.pathname;
  // удаляем локаль вначале /ru
  new_path = new_path.substr(3);

  const path = '/' +
    newUILang + '/' +
    window.location.search +
    window.location.hash;

  window.location.href = path;
};

// ===========================
// ARRAY FUNCTIONS
// ===========================
window.sortArrayInt = function(a, b) {
  if(a === Infinity) {
    return 1;
  } else if(isNaN(a)) {
    return -1;
  } else {
    return a - b;
  };
};

// Переводим массив в последовательности:
// Пример: [1,2,3,10] -> [[1,2,3], [10]]
window.arrayToSeqs = function(arr) {
  // сортируем
  sorted = arr.sort(window.sortArrayInt);

  // первым элементом первой последовательности будет первый элемент массива
  seqs = [[sorted.shift()]];

  // последняя последовательность
  seq = seqs[seqs.length - 1];

  // проходим по [1,2,3,10]
  sorted.forEach(e => {
    // последний элемент в первой последовательности
    let lastNum = seq[seq.length - 1];
    // если последний элемент в последней последовательности меньше на 1 текущего элемента
    if ((lastNum + 1) == e) {
      // то добавляем его в конец последней последовательности
      seq.push(e);
    } else {
      // иначе создаем новую последовательность с текущим элементом
      seq = [e];
      // и добавляем новую последовательность в массив
      seqs.push(seq);
    };
  });

  return(seqs);
};

function _setupAxios_() {
  const csrfToken = document.querySelector("meta[name=csrf-token]").content;
  axios.defaults.headers.common['X-CSRF-Token'] = csrfToken;
};
_setupAxios_();
