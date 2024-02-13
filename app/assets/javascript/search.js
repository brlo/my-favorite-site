// Кнопка: искать
function goToSearch() {
  searchInput = document.getElementById('search-input');
  text = searchInput.value; //. /[^\sA-Za-zА-Яа-я0-9-]*/, ''
  book = document.getElementById('search-books').value;
  acc = document.getElementById('search-accuracy').value;
  lang = document.getElementById('search-lang').value;

  let params = [];
  if (book && book.length > 0) { params.push('book=' + book) };
  if (acc && acc.length > 0) { params.push('acc=' + acc) };
  if (lang && lang.length > 0) { params.push('l=' + lang) };
  if (text && text.length > 0) { params.push('t=' + text) };
  document.location.href = '/' + window.BX.locale + '/search?' + params.join('&');
};

// Выпадающие списки: выбор книги для поиска
var element = document.querySelector('#search-books');
new Choices(element, {
  allowHTML: false,
  shouldSort: false,
  shouldSortItems: false,
  // removeItemButton: true,
  placeholder: true,
  placeholderValue: 'Искать в книгах',
  searchEnabled: !isMobileDevice(),
  searchPlaceholderValue: 'поиск',
  prependValue: null,
  appendValue: null,
  renderSelectedChoices: 'auto',
  loadingText: 'Поиск...',
  noResultsText: 'Ничего не найдено',
  noChoicesText: 'Ничего не выбрано',
  itemSelectText: '',
  position: 'down',
  classNames: {
    containerOuter: 'choices search-books'
  },
});

// Выпадающие списки: выбор точности поиска
var element = document.querySelector('#search-accuracy');
new Choices(element, {
  allowHTML: false,
  shouldSort: false,
  shouldSortItems: false,
  placeholder: true,
  placeholderValue: 'Искать в книгах',
  searchEnabled: false,
  prependValue: null,
  appendValue: null,
  renderSelectedChoices: 'auto',
  itemSelectText: '',
  position: 'down',
  classNames: {
    containerOuter: 'choices search-accuracy'
  },
});

// Выпадающие списки: выбор языка поиска
var element = document.querySelector('#search-lang');
new Choices(element, {
  allowHTML: false,
  shouldSort: false,
  shouldSortItems: false,
  placeholder: true,
  placeholderValue: 'Язык текста',
  searchEnabled: false,
  prependValue: null,
  appendValue: null,
  renderSelectedChoices: 'auto',
  itemSelectText: '',
  position: 'down',
  classNames: {
    containerOuter: 'choices search-lang'
  },
});

// подсветка найденных слов
// let searchAccuracy = document.getElementById('search-accuracy').value;
// let searchText = document.getElementById('search-input').value;
// let verses = document.getElementsByClassName('line');

// if (typeof searchText === 'string') {
//   searchWords = searchText.split(' ');

//   // проходим по стихам
//   for (var i = 0; i < verses.length; i++) {
//     let el = verses.item(i);
//     let text = el.innerHTML;

//     // if (searchAccuracy == 'exact') {
//     //   // подствечиваем всю фразу целиком
//     //   let regex = new RegExp(searchWords, 'gi');
//     //   text = text.replace(regex, "<span class='highlight'>" + searchWords + "</span>");
//     // } else {
//       // подсвечиваем слова запроса по отдельности
//       for (var n = 0; n < searchWords.length; n++) {
//         let word = searchWords[n]
//         if (word.length > 2) {
//           let regex = new RegExp(word, 'gi');
//           text = text.replace(regex, "<span class='highlight'>" + word + "</span>");
//         };
//       };
//     // };

//     el.innerHTML = text;
//   };
// };
