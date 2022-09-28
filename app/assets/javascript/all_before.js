// Перенсти функции в хэш. Вызывать их из кэша
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
      dummy.select();
      document.execCommand('copy');
      document.body.removeChild(dummy);
    },
  },
}

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

// NIGHT MODE SWITCHER
window.switchNightMode = function() {
  const modeSwitcher = document.getElementById("night-mode-switcher");
  const body = document.body;
  const nightClass = "night-mode";

  if (body.classList.contains(nightClass)) {
    body.classList.remove(nightClass);
    setCookie('isNightMode', 0, 999);
    modeSwitcher.innerHTML = window.BX.locale == 'ru' ? "День" : "Day";
  } else {
    body.classList.add(nightClass);
    setCookie('isNightMode', 1, 999);
    modeSwitcher.innerHTML = window.BX.locale == 'ru' ? "Ночь" : "Night";
  }

  return false;
};

// выбор языка
function selectLang() {
  searchInput = document.getElementById('lang-select');
  lang = searchInput.value;
  setCookie('b-lang', lang, 999);

  location.reload();
  return false;
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
