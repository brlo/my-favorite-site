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
    modeSwitcher.innerHTML = "День";
  } else {
    body.classList.add(nightClass);
    setCookie('isNightMode', 1, 999);
    modeSwitcher.innerHTML = "Ночь";
  }

  return false;
};

// Ссылка на выделенный текст
window.getSelectedTextLink = function() {
  // if (window.getSelection()) return;

  let bookInfo = document.getElementById('current-book').dataset;
  let bookShortName = bookInfo.shortName;
  let chapter = bookInfo.chapter;
  let line1 = window.getSelection().anchorNode.parentNode.dataset.line;
  let line2 = window.getSelection().extentNode.parentNode.dataset.line;

  let lines;

  if (line1 == line2) {
    // 5
    // выделена одна строка, просто указываем её номер
    lines = line1;
  } else {
    // 5-10
    // выделено несколько строк, указываем их через дефис
    let min, max;
    [min, max] = [parseInt(line1), parseInt(line2)].sort(function(a, b) { return a - b });
    lines = min + '-' + max;
  };

  let link = bookShortName + '. ' + chapter + ':' + lines;

  return link;
};

// запоминаем выделенный текст
window.saveSelectedTextLink = function() {
  let link = window.getSelectedTextLink();
  let text = window.getSelectedText();
  text = text.replace(/\n/g, ' ');

  let quote = '"' + text + '" ' + '(' + link + ')';

  window.savedTextLink = quote;

  return quote;
};

// Предлагаем пользователю скопировать последний выделенный текст
window.copySelectedTextLink = function() {
  window.copyTextToClipboard(window.savedTextLink);
};

// Выделенный текст
window.getSelectedText = function() {
  if (window.getSelection) {
    return window.getSelection().toString();
  } else if (document.selection) {
    return document.selection.createRange().text;
  }
  return '';
};

// Предложение пользователю скопировать текст
window.copyTextToClipboard = function(text) {
  window.prompt("Copy to clipboard: Ctrl+C, Enter", text);
}



// ///////////////////////////////////////////////////

function selectLang() {
  searchInput = document.getElementById('lang-select');
  lang = searchInput.value;
  setCookie('b-lang', lang, 999);

  location.reload();
  return false;
};
