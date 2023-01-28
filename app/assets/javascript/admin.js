//= require vendor/pell

window.filterQueryPages = function(text) {
  const pages = document.querySelectorAll("#quotes_pages .q_page");
  let filter = text.toLowerCase();
  if (filter === '') {
    pages.forEach(page => page.classList.remove('hidden'));
  } else {
    pages.forEach(page => {
      const pageTitleEl = page.querySelectorAll('.q_title')[0];
      const pageTitle = (pageTitleEl.innerText || pageTitleEl.textContent).toLowerCase();
      pageTitle.includes(filter)
      ? page.classList.remove('hidden')
      : page.classList.add('hidden');
    });
  };
};
