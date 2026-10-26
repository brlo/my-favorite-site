// Таймлайн: сверху — полосы периодов, ниже — события выбранного периода
// (чем важнее событие, тем крупнее метка). Пустые периоды показаны как «в работе».

const markerSize = (ev) => 8 + ev.importance * 3.2;

// «1689–1624 гг. до Р. Х.», «538 г. до Р. Х. – 33 г.»
function periodYears(p) {
  if (p.days) return 'шесть дней творения';
  const y = (v) => Math.abs(Math.round(v));
  if (p.to === 0) return `${y(p.from)} г. до Р. Х. – Рождество Христово`;
  if (p.from === 0) return `Рождество Христово – ${y(p.to)} г.`;
  if (p.to < 0) return `${y(p.from)}–${y(p.to)} гг. до Р. Х.`;
  if (p.from < 0) return `${y(p.from)} г. до Р. Х. – ${y(p.to)} г. по Р. Х.`;
  return `${y(p.from)}–${y(p.to)} гг. по Р. Х.`;
}

export function createTimeline({ periodsEl, trackEl, events, periods, onSelect }) {
  let current = -1;
  let shownPeriod = null;
  const firstOf = (pid) => events.findIndex((e) => e.period === pid);

  // Подсказка над полосой периода: появляется сразу, в отличие от системной title
  const tip = document.createElement('div');
  tip.className = 'per-tip';
  periodsEl.parentElement.appendChild(tip);

  function showTip(b, p, has) {
    tip.innerHTML = `<b>${p.title}</b><span>${periodYears(p)}${has ? '' : ' · в работе'}</span>`;
    tip.style.setProperty('--c', p.color);
    tip.classList.add('on');
    const host = periodsEl.parentElement.getBoundingClientRect();
    const r = b.getBoundingClientRect();
    const w = tip.offsetWidth;
    const x = Math.min(Math.max(8, r.left + r.width / 2 - host.left - w / 2), host.width - w - 8);
    tip.style.left = `${x}px`;
    tip.style.top = `${r.top - host.top - tip.offsetHeight - 8}px`;
  }

  function buildPeriods() {
    periodsEl.innerHTML = '';
    for (const p of periods) {
      const b = document.createElement('button');
      const has = firstOf(p.id) >= 0;
      b.className = 'per' + (has ? '' : ' empty');
      b.style.setProperty('--c', p.color);
      b.setAttribute('aria-label', `${p.title}, ${periodYears(p)}${has ? '' : ', в работе'}`);
      b.dataset.id = p.id;
      b.addEventListener('mouseenter', () => showTip(b, p, has));
      b.addEventListener('focus', () => showTip(b, p, has));
      b.addEventListener('mouseleave', () => tip.classList.remove('on'));
      b.addEventListener('blur', () => tip.classList.remove('on'));
      if (has) b.addEventListener('click', () => onSelect(firstOf(p.id), true));
      periodsEl.appendChild(b);
    }
  }

  // Шкала периода — по его событиям: пока период заполнен не до конца, метки не жмутся к краю
  function periodRange(p, list) {
    if (p.days) return [0, 7];
    const ys = list.map((e) => e.year);
    const lo = Math.min(...ys), hi = Math.max(...ys);
    const span = Math.max(1, hi - lo);
    return [lo - span * 0.02, hi + span * 0.02];
  }

  function buildTrack(pid) {
    shownPeriod = pid;
    trackEl.innerHTML = '';
    const p = periods.find((x) => x.id === pid);
    const idx = events.map((e, i) => (e.period === pid ? i : -1)).filter((i) => i >= 0);
    const list = idx.map((i) => events[i]);
    const W = trackEl.clientWidth;
    const pad = 14;

    const line = document.createElement('div');
    line.className = 'tl-line';
    line.style.setProperty('--c', p.color);
    line.innerHTML = `<span>${p.title}</span>`;
    trackEl.appendChild(line);

    const [from, to] = periodRange(p, list);
    const xs = list.map((e) => {
      const v = p.days ? e.day - 0.5 : e.year;
      return pad + ((v - from) / Math.max(1e-9, to - from)) * (W - pad * 2);
    });
    // раздвигаем слипшиеся метки
    for (let i = 1; i < xs.length; i++) {
      const gap = (markerSize(list[i]) + markerSize(list[i - 1])) / 2 + 4;
      if (xs[i] < xs[i - 1] + gap) xs[i] = xs[i - 1] + gap;
    }
    for (let i = xs.length - 1; i >= 0; i--) {
      const limit = i === xs.length - 1 ? W - pad : xs[i + 1] - (markerSize(list[i]) + markerSize(list[i + 1])) / 2 - 4;
      if (xs[i] > limit) xs[i] = limit;
    }

    // подписи над метками: сначала самые важные, пересекающиеся пропускаем
    const shortLabels = {};
    const taken = [];
    const order = list.map((e, k) => k).filter((k) => !list[k].day && list[k].importance >= 3)
      .sort((a, b) => list[b].importance - list[a].importance);
    for (const k of order) {
      const text = list[k].short || list[k].title.split(/[:.]/)[0];
      const half = text.length * 4.3 + 8;
      const l = Math.max(0, xs[k] - half), r = Math.min(W, xs[k] + half);
      if (taken.some(([a, b]) => l < b && r > a)) continue;
      taken.push([l, r]);
      shortLabels[k] = text;
    }

    list.forEach((ev, k) => {
      const m = document.createElement('button');
      m.className = `mk imp${ev.importance}` + (ev.day ? ' day' : '');
      m.style.left = `${xs[k]}px`;
      m.style.setProperty('--s', `${markerSize(ev)}px`);
      m.style.setProperty('--c', p.color);
      m.title = ev.title;
      m.setAttribute('aria-label', ev.title);
      m.dataset.index = idx[k];
      if (ev.day) m.textContent = ev.day;
      if (shortLabels[k]) {
        m.dataset.short = shortLabels[k];
        // у краёв подпись прижимаем внутрь, чтобы не обрезалась
        const half = shortLabels[k].length * 4.3 + 8;
        if (xs[k] - half < 0) m.classList.add('edge-l');
        if (xs[k] + half > W) m.classList.add('edge-r');
      }
      m.addEventListener('click', () => onSelect(idx[k], true));
      trackEl.appendChild(m);
    });
  }

  function mark() {
    const pid = events[current]?.period;
    periodsEl.querySelectorAll('.per').forEach((b) => {
      const pi = periods.findIndex((x) => x.id === b.dataset.id);
      const ci = periods.findIndex((x) => x.id === pid);
      b.classList.toggle('active', b.dataset.id === pid);
      b.classList.toggle('past', pi < ci);
    });
    trackEl.querySelectorAll('.mk').forEach((m) => {
      const i = +m.dataset.index;
      m.classList.toggle('active', i === current);
      m.classList.toggle('past', i < current);
    });
  }

  buildPeriods();

  return {
    setCurrent(i) {
      current = i;
      if (events[i].period !== shownPeriod) buildTrack(events[i].period);
      mark();
    },
    rebuild() {
      if (shownPeriod) buildTrack(shownPeriod);
      mark();
    },
  };
}
