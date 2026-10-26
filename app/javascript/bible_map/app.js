// Библейская история на глобусе: связывает сцену, слои, таймлайн и карточку события
import * as THREE from 'three';
import { ll, clamp01, easeInOut, now } from 'bible_map/geo';
import { formatYear, formatAm } from 'bible_map/chrono';
import { createScene, SUN_DIR } from 'bible_map/scene';
import { EventOverlay, CommunityLayer, PersonsLayer, PoliticsLayer, updateLabels, resizeLines, pointInPoly } from 'bible_map/layers';
import { createTimeline } from 'bible_map/timeline';
import { createShelf } from 'bible_map/shelf';
import { EVENTS, PERIODS, PERSONS, COMMUNITIES, BOOKS, POLITICS, WORLD } from 'bible_map/data';

// адреса текстур (на res.bibleox.com) и ссылок на сайт приходят из разметки страницы
const CONFIG = document.body.dataset;
const SITE_URL = CONFIG.bibleUrl;

const card = document.getElementById('card');
const yearEl = document.getElementById('year');
const playBtn = document.getElementById('play');
const loaderEl = document.getElementById('loader');

const { scene, camera, controls, renderer, update: updateScene, flash, resize, globe } = createScene(
  document.getElementById('scene'),
  { earthDay: CONFIG.earthDay, earthRelief: CONFIG.earthRelief, clouds: CONFIG.clouds, moon: CONFIG.moon },
  (k) => { loaderEl.querySelector('i').style.width = `${k * 100}%`; },
  start,
);

// ---------------------------------------------------------------- состояние среды

const env = {};
for (const k of Object.keys(WORLD)) env[k] = { v: WORLD[k], from: WORLD[k], to: WORLD[k], t0: 0, dur: 0 };
const E = (k) => env[k].v;

function envSet(k, v) { Object.assign(env[k], { v, from: v, to: v, dur: 0 }); }
function envTo(k, v, dur, delay) { Object.assign(env[k], { from: env[k].v, to: v, t0: now() + delay, dur }); }
function envTick(t) {
  for (const e of Object.values(env)) {
    if (t < e.t0) continue;
    const p = e.dur > 0 ? clamp01((t - e.t0) / e.dur) : 1;
    e.v = e.from + (e.to - e.from) * easeInOut(p);
  }
}

function applyEnv(ev) {
  if (ev.from) for (const [k, v] of Object.entries(ev.from)) envSet(k, v);
  const full = { ...WORLD, ...ev.env };
  for (const [k, spec] of Object.entries(full)) {
    const [v, dur = 1.8, delay = 0] = Array.isArray(spec) ? spec : [spec];
    envTo(k, v, dur, delay);
  }
}

// ---------------------------------------------------------------- камера

let fly = null;

function cameraPose(c) {
  // towardSun — смещаем взгляд к солнцу, чтобы оно попало в кадр
  if (c.focus === false) return { pos: ll(c.lat, c.lon, 1 + c.alt), target: SUN_DIR.clone().multiplyScalar(c.towardSun || 0) };
  const tilt = c.tilt ?? c.alt * 12;
  return { pos: ll(c.lat - tilt, c.lon, 1 + c.alt), target: ll(c.lat, c.lon, 1) };
}

function flyTo(c, dur = 2.8) {
  const { pos, target } = cameraPose(c);
  const p0 = camera.position.clone();
  const hop = p0.clone().normalize().angleTo(pos.clone().normalize()) * 0.6;
  fly = { p0, p1: pos, tg0: controls.target.clone(), tg1: target, t0: now(), dur, hop };
  controls.enabled = false;
}

function updateFly(t) {
  if (!fly) return;
  const k = clamp01((t - fly.t0) / fly.dur);
  const e = easeInOut(k);
  const d0 = fly.p0.clone().normalize(), d1 = fly.p1.clone().normalize();
  const q = new THREE.Quaternion().setFromUnitVectors(d0, d1);
  const dir = d0.applyQuaternion(new THREE.Quaternion().slerp(q, e));
  const r = THREE.MathUtils.lerp(fly.p0.length(), fly.p1.length(), e) + fly.hop * Math.sin(Math.PI * e);
  camera.position.copy(dir.multiplyScalar(r));
  controls.target.lerpVectors(fly.tg0, fly.tg1, e);
  camera.lookAt(controls.target);
  if (k >= 1) { fly = null; controls.enabled = true; }
}

// Центр кадра сдвигаем в свободную от карточки и таймлайна часть экрана
const viewShift = { x: 0, y: 0, tx: 0, ty: 0 };

function measureFreeArea() {
  const W = window.innerWidth, H = window.innerHeight;
  const c = card.getBoundingClientRect();
  const tl = document.getElementById('timeline').getBoundingClientRect();
  let l = 0, t = 0;
  if (W > 720) l = c.right * 0.8; else t = c.bottom;
  viewShift.tx = l / 2;
  viewShift.ty = (t + tl.top + 20) / 2 - H / 2;
}

function updateViewShift(dt) {
  const k = 1 - Math.exp(-dt * 3);
  viewShift.x += (viewShift.tx - viewShift.x) * k;
  viewShift.y += (viewShift.ty - viewShift.y) * k;
  const W = window.innerWidth, H = window.innerHeight;
  camera.setViewOffset(W, H, -viewShift.x, -viewShift.y, W, H);
}

// ---------------------------------------------------------------- карточка и год

const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

function linkHref(l) {
  if (l.href) return l.href;
  return `${SITE_URL}w/${l.page}${l.anchor ? '#' + l.anchor : ''}`;
}

function renderCard(ev) {
  const period = PERIODS.find((p) => p.id === ev.period);
  const links = (ev.links || []).map((l) => `<li><a href="${esc(linkHref(l))}" target="_blank" rel="noopener">${esc(l.title)}</a></li>`).join('');
  card.classList.remove('show', 'expanded');
  void card.offsetWidth;
  card.innerHTML = `
    <div class="era" style="--c:${period.color}">${esc(period.title)}</div>
    <h1>${esc(ev.title)}</h1>
    ${ev.when ? `<div class="when">${esc(ev.when)}</div>` : ''}
    <p>${esc(ev.text)}</p>
    ${ev.ref ? `<a class="ref" href="${SITE_URL}${ev.ref.link}" target="_blank" rel="noopener">${esc(ev.ref.label)} <span>→</span></a>` : ''}
    ${links ? `<ul class="links">${links}</ul>` : ''}`;
  card.classList.add('show');
}

// Год в середине экрана; при переходе цифры «докручиваются» до нового значения
let yearAnim = null;

function showYear(ev) {
  if (ev.period === 'hexa') {
    yearAnim = null;
    yearEl.innerHTML = `<b>Шестоднев · день ${ev.day}</b><small>${CREATION_BC_LABEL}</small>`;
    return;
  }
  const from = yearAnim ? yearAnim.cur : ev.year;
  yearAnim = { from, to: ev.year, t0: now(), cur: from };
}

const CREATION_BC_LABEL = 'сотворение мира — 5508 г. до Р. Х. (по Септуагинте)';

function updateYear(t) {
  if (!yearAnim) return;
  const k = easeInOut(clamp01((t - yearAnim.t0) / 1.8));
  const y = yearAnim.from + (yearAnim.to - yearAnim.from) * k;
  if (yearAnim.shown === Math.round(y)) return;
  yearAnim.cur = y;
  yearAnim.shown = Math.round(y);
  yearEl.innerHTML = `<b>${formatYear(y)}</b>${y < -1500 ? `<small>${formatAm(y)}</small>` : ''}`;
}

// ---------------------------------------------------------------- слои

const communities = new CommunityLayer(scene, COMMUNITIES);
const persons = new PersonsLayer(PERSONS, SITE_URL);
const politics = new PoliticsLayer(scene, POLITICS);
const shelf = createShelf(document.getElementById('shelf'), BOOKS, SITE_URL);
let overlays = [];

function setupToggle(id, layer) {
  const b = document.getElementById(id);
  b.addEventListener('click', () => {
    layer.enabled = !layer.enabled;
    b.classList.toggle('off', !layer.enabled);
    b.setAttribute('aria-pressed', String(layer.enabled));
    syncLayers(EVENTS[current]);
  });
}
setupToggle('toggle-people', communities);
setupToggle('toggle-persons', persons);
setupToggle('toggle-politics', politics);

function syncLayers(ev) {
  const historic = ev.period !== 'hexa';
  communities.setYear(ev.year, historic);
  persons.setYear(ev.year, historic, ev);
  politics.setYear(ev.year, historic && !!ev.politics);
  shelf.setYear(ev.year, !historic);
}

// ---------------------------------------------------------------- навигация

let current = -1;
let enteredAt = 0;
let playing = false;

const timeline = createTimeline({
  periodsEl: document.getElementById('periods'),
  trackEl: document.getElementById('track'),
  events: EVENTS,
  periods: PERIODS,
  onSelect: (i, byUser) => { if (byUser) stopPlay(); go(i); },
});

function go(i) {
  if (i < 0 || i >= EVENTS.length || i === current) return;
  current = i;
  enteredAt = now();
  const ev = EVENTS[i];
  for (const o of overlays) o.target = 0;
  // ошибка в данных одного события не должна ломать переход: карточка и камера всё равно обновятся
  try { overlays.push(new EventOverlay(scene, ev)); } catch (e) { console.error(`bible_map: слой события ${ev.id}`, e); }
  applyEnv(ev);
  flyTo(ev.camera);
  if (ev.flash) flash(ev.flash);
  renderCard(ev);
  showYear(ev);
  syncLayers(ev);
  measureFreeArea();
  timeline.setCurrent(i);
  history.replaceState(null, '', `#${ev.id}`);
}

function stopPlay() { playing = false; playBtn.classList.remove('on'); }

playBtn.addEventListener('click', () => {
  playing = !playing;
  playBtn.classList.toggle('on', playing);
  if (playing && current === EVENTS.length - 1) go(0);
  enteredAt = now();
});
document.getElementById('prev').addEventListener('click', () => { stopPlay(); go(current - 1); });
document.getElementById('next').addEventListener('click', () => { stopPlay(); go(current + 1); });
window.addEventListener('keydown', (e) => {
  if (e.target.closest && e.target.closest('input, textarea')) return;
  if (e.key === 'ArrowRight') { stopPlay(); go(current + 1); }
  if (e.key === 'ArrowLeft') { stopPlay(); go(current - 1); }
  if (e.key === ' ') { e.preventDefault(); playBtn.click(); }
});

// на телефоне текст свёрнут до трёх строк, по нажатию раскрывается
card.addEventListener('click', (e) => {
  if (e.target.tagName !== 'P') return;
  card.classList.toggle('expanded');
  measureFreeArea();
});

// Подсказка при наведении на область: общины поля и области события (у многих нет подписи на карте)
const hoverTip = document.getElementById('hover-tip');
const raycaster = new THREE.Raycaster();
const pointer = new THREE.Vector2();
let hoverQueued = null;

function hoverNames(lat, lon) {
  const names = [];
  for (const e of communities.at(lat, lon)) names.push([e.name || (e.kind === 'church' ? 'Церковь Христова' : ''), e.kind === 'church' ? '#74c6ff' : (e.color || '#e88a6a')]);
  for (const o of overlays) {
    if (o.target === 0) continue;
    for (const a of o.areaDefs || []) if (a.name && pointInPoly(lat, lon, a.poly)) names.push([a.name, a.color]);
  }
  const seen = new Set();
  return names.filter(([n]) => n && !seen.has(n) && seen.add(n));
}

function updateHover() {
  const ev = hoverQueued;
  hoverQueued = null;
  pointer.set((ev.clientX / window.innerWidth) * 2 - 1, -(ev.clientY / window.innerHeight) * 2 + 1);
  raycaster.setFromCamera(pointer, camera);
  const hit = raycaster.intersectObject(globe)[0];
  const names = hit ? hoverNames(Math.asin(hit.point.y / hit.point.length()) * 180 / Math.PI, Math.atan2(-hit.point.z, hit.point.x) * 180 / Math.PI) : [];
  if (!names.length) { hoverTip.classList.remove('on'); return; }
  hoverTip.innerHTML = names.map(([n, c]) => `<span style="--c:${c}">${esc(n)}</span>`).join('');
  hoverTip.style.transform = `translate(${ev.clientX + 14}px, ${ev.clientY + 12}px)`;
  hoverTip.classList.add('on');
}

renderer.domElement.addEventListener('pointermove', (e) => {
  if (e.buttons) { hoverTip.classList.remove('on'); return; }
  if (!hoverQueued) requestAnimationFrame(updateHover);
  hoverQueued = e;
});
renderer.domElement.addEventListener('pointerleave', () => hoverTip.classList.remove('on'));

window.addEventListener('hashchange', () => {
  const i = EVENTS.findIndex((e) => e.id === location.hash.slice(1));
  if (i >= 0) { stopPlay(); go(i); }
});

window.addEventListener('resize', () => {
  resize();
  resizeLines();
  timeline.rebuild();
  measureFreeArea();
});

// ---------------------------------------------------------------- цикл

let last = now();

function frame() {
  const t = now();
  const dt = Math.min(0.1, t - last);
  last = t;

  envTick(t);
  updateViewShift(dt);
  updateFly(t);
  controls.autoRotate = E('spin') > 0.5 && !fly;
  if (!fly) controls.update();
  if (camera.position.length() < 1.02) camera.position.setLength(1.02);

  updateScene(t, E);
  updateYear(t);

  for (const o of overlays) o.update(dt, t);
  overlays = overlays.filter((o) => { if (o.isDone) { o.dispose(); return false; } return true; });
  communities.update(dt, t);
  politics.update(dt);
  persons.update(dt, t);
  updateLabels(camera, t);

  if (playing && t - enteredAt > (EVENTS[current].hold || 10)) {
    if (current < EVENTS.length - 1) go(current + 1);
    else stopPlay();
  }

  renderer.render(scene, camera);
  requestAnimationFrame(frame);
}

function start() {
  loaderEl.classList.add('done');
  const i = Math.max(0, EVENTS.findIndex((e) => e.id === location.hash.slice(1)));
  const first = EVENTS[i];
  const { pos, target } = cameraPose({ ...first.camera, alt: first.camera.alt + 2 });
  camera.position.copy(pos);
  controls.target.copy(target);
  go(i);
  requestAnimationFrame(frame);
}
