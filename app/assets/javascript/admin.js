// <input type='text' class='filter' oninput='window.filterQueryPages(this.value);' value='' placeholder='Фильтр' autofocus>
// <div id="quotes_pages">
//   <% @quotes_pages.each do |page| %>
//     <div class='q_page'>
//       <%= page.title.to_s[0].upcase %> | <b><%= link_to(page.title, [:admin, page], class: 'q_title') %></b> (<%= page.position %>) | <%= flag_by_lang(page.lang) %> | <%= @page_visits[page.id.to_s] %>
//     </div>
//   <% end %>
// </div>

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
