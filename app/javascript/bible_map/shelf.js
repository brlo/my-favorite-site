// Полка «Библия»: корешки книг загораются по мере того, как книги появляются в истории.
// Корешок — ссылка на книгу на сайте; подсказка — кем и когда написана.

export function createShelf(el, books, siteUrl) {
  const spines = el.querySelector('.spines');
  const count = el.querySelector('.count');
  const items = books.map((b) => {
    const a = document.createElement('a');
    a.className = 'spine' + (b.nt ? ' nt' : '') + (b.canon === false ? ' noncanon' : '');
    a.href = `${siteUrl}${b.code}/1/`;
    a.target = '_blank';
    a.rel = 'noopener';
    a.title = `${b.name} — ${b.label}`;
    a.setAttribute('aria-label', a.title);
    spines.appendChild(a);
    return { b, a };
  });
  // зазор между Ветхим и Новым Заветом
  const firstNt = items.find((it) => it.b.nt);
  if (firstNt) firstNt.a.classList.add('gap');

  let last = null;
  return {
    setYear(year, isHexaemeron) {
      const key = isHexaemeron ? 'hexa' : Math.round(year);
      if (key === last) return;
      last = key;
      let n = 0;
      for (const { b, a } of items) {
        const on = !isHexaemeron && year >= b.year;
        if (on) n++;
        a.classList.toggle('on', on);
      }
      count.textContent = n ? `${n} ${plural(n, 'книга', 'книги', 'книг')}` : 'ещё не написана';
      el.classList.toggle('empty', n === 0);
    },
  };
}

function plural(n, one, few, many) {
  const m10 = n % 10, m100 = n % 100;
  if (m10 === 1 && m100 !== 11) return one;
  if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return few;
  return many;
}
