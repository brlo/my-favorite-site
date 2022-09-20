var element = document.querySelector('#lang-select');
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

