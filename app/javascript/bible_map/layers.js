// Слои поверх глобуса: подписи (HTML), слой события (области, пути, точки),
// границы народа Божьего и отпавших обществ, точки праведников и пророков
import * as THREE from 'three';
import { Line2 } from 'three/addons/lines/Line2.js';
import { LineMaterial } from 'three/addons/lines/LineMaterial.js';
import { LineGeometry } from 'three/addons/lines/LineGeometry.js';
import { ll, clamp01, easeInOut, smooth, densify, curve, now } from 'bible_map/geo';

const labelsHost = document.getElementById('labels');
const lineMaterials = new Set();
const allLabels = new Set();

export function resizeLines() {
  for (const m of lineMaterials) m.resolution.set(window.innerWidth, window.innerHeight);
}

function makeLine(pts, { color, width, dashed }) {
  const geo = new LineGeometry();
  geo.setPositions(pts.flatMap((p) => [p.x, p.y, p.z]));
  let len = 0;
  for (let i = 1; i < pts.length; i++) len += pts[i].distanceTo(pts[i - 1]);
  const mat = new LineMaterial({
    color, linewidth: width, transparent: true, depthWrite: false, opacity: 0,
    dashed: !!dashed, dashSize: Math.max(len / 70, 0.002), gapSize: Math.max(len / 110, 0.0013),
  });
  mat.resolution.set(window.innerWidth, window.innerHeight);
  lineMaterials.add(mat);
  const line = new Line2(geo, mat);
  line.computeLineDistances();
  line.userData.segments = pts.length - 1;
  return line;
}

function disposeGroup(group) {
  group.parent?.remove(group);
  group.traverse((o) => {
    if (o.geometry) o.geometry.dispose();
    if (o.material) { lineMaterials.delete(o.material); o.material.dispose(); }
  });
}

// Заливка многоугольника на сфере + контур
function areaMeshes(poly, { color, hyp, r = 1.0025, outlineWidth = 1.6, halo = 0 }) {
  const ring = densify(poly);
  const contour = ring.map(([la, lo]) => new THREE.Vector2(lo, la));
  const tris = THREE.ShapeUtils.triangulateShape(contour, []);
  // большие треугольники дробим, чтобы заливка ложилась на сферу, а не уходила хордой под поверхность
  const flat = [];
  const split = (a, b, c) => {
    const d = (p, q) => Math.hypot(p[0] - q[0], p[1] - q[1]);
    if (Math.max(d(a, b), d(b, c), d(c, a)) <= 2) { for (const [la, lo] of [a, b, c]) { const v = ll(la, lo, r); flat.push(v.x, v.y, v.z); } return; }
    const m = (p, q) => [(p[0] + q[0]) / 2, (p[1] + q[1]) / 2];
    const ab = m(a, b), bc = m(b, c), ca = m(c, a);
    split(a, ab, ca); split(ab, b, bc); split(ca, bc, c); split(ab, bc, ca);
  };
  for (const [i, j, k] of tris) split(ring[i], ring[j], ring[k]);
  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.Float32BufferAttribute(flat, 3));
  const fill = new THREE.Mesh(geo, new THREE.MeshBasicMaterial({
    color, transparent: true, opacity: 0, depthWrite: false, side: THREE.DoubleSide,
    polygonOffset: true, polygonOffsetFactor: -2, polygonOffsetUnits: -2,
  }));
  const outlinePts = ring.concat([ring[0]]).map(([la, lo]) => ll(la, lo, r + 0.0005));
  const outline = makeLine(outlinePts, { color: new THREE.Color(color), width: outlineWidth, dashed: hyp });
  const glow = halo ? makeLine(outlinePts, { color: new THREE.Color(color), width: halo }) : null;
  const center = ring.reduce((s, [la, lo]) => [s[0] + la, s[1] + lo], [0, 0]).map((x) => x / ring.length);
  return { fill, outline, glow, center };
}

function labelEl(cls, html) {
  const el = document.createElement('div');
  el.className = 'lbl ' + cls;
  el.innerHTML = html;
  labelsHost.appendChild(el);
  return el;
}

function addLabel(owner, label) {
  label.owner = owner;
  allLabels.add(label);
  owner.labels.push(label);
  return label;
}

function removeLabels(owner) {
  for (const l of owner.labels) { l.el.remove(); allLabels.delete(l); }
  owner.labels = [];
}

const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

// ---------------------------------------------------------------- подписи

// Приоритет при наложении: области важнее городов, второстепенные — последними
function labelPriority(el) {
  if (el.classList.contains('christ')) return 3.5;
  if (el.classList.contains('theotokos')) return 2.8;
  if (el.classList.contains('community')) return 1.5;
  if (el.classList.contains('area')) return 4;
  if (el.classList.contains('pt') && !el.classList.contains('minor')) return 3;
  if (el.classList.contains('person')) return 2;
  return 1;
}

const _v = new THREE.Vector3();
const _toCam = new THREE.Vector3();

export function updateLabels(camera, t) {
  const w = window.innerWidth, h = window.innerHeight;
  const shown = [];
  for (const l of allLabels) {
    const o = l.owner;
    _toCam.copy(camera.position).sub(l.pos);
    const facing = _toCam.dot(_v.copy(l.pos).normalize()) / _toCam.length();
    _v.copy(l.pos).project(camera);
    const age = t - (l.t0 ?? o.t0);
    const vis = o.fade * (l.fade ?? 1) * smooth(0.0, 0.15, facing) * smooth(l.delay || 0, (l.delay || 0) + 0.6, age) * (l.hidden ? 0 : 1);
    if (vis < 0.01 || _v.z > 1) { l.el.style.display = 'none'; continue; }
    l.x = ((_v.x + 1) / 2) * w;
    l.y = ((1 - _v.y) / 2) * h;
    l.vis = vis;
    shown.push(l);
  }

  // убираем подписи, налезающие на более важные
  const boxes = [];
  shown.sort((a, b) => (b.prio ??= labelPriority(b.el)) - (a.prio ??= labelPriority(a.el)));
  for (const l of shown) {
    if (!l.traveler) {
      const span = l.el.querySelector('span');
      if (l.el.classList.contains('quiet')) l.w = 1;
      else if (!l.w) l.w = span ? span.offsetWidth || span.textContent.length * 8 : 0;
      const centered = l.el.classList.contains('area') || l.el.classList.contains('path') || l.el.classList.contains('region');
      const hits = (box) => boxes.some((b) => box[0] < b[2] && box[2] > b[0] && box[1] < b[3] && box[3] > b[1]);
      let box = null;
      let flip = false, dy = 0;
      if (centered) {
        box = [l.x - l.w / 2, l.y - 12, l.x + l.w / 2, l.y + 12];
        if (hits(box)) box = null;
      } else {
        // подпись справа от точки; если занято — слева, ниже или выше (праведники в людных местах не пропадают)
        const tries = l.el.classList.contains('person') ? [[false, 0], [true, 0], [false, 16], [true, 16], [false, -16], [true, -16]] : [[false, 0], [true, 0]];
        for (const [f, d] of tries) {
          const b = f ? [l.x - 12 - l.w, l.y - 10 + d, l.x + 6, l.y + 8 + d] : [l.x - 6, l.y - 10 + d, l.x + 12 + l.w, l.y + 8 + d];
          if (!hits(b)) { box = b; flip = f; dy = d; break; }
        }
      }
      if (!box) { l.el.style.display = 'none'; continue; }
      l.el.classList.toggle('flip', flip);
      l.el.style.setProperty('--dy', `${dy}px`);
      boxes.push(box);
    }
    l.el.style.display = '';
    l.el.style.opacity = l.vis;
    l.el.style.transform = `translate(${l.x}px, ${l.y}px)`;
  }
}

// ---------------------------------------------------------------- слой события

export class EventOverlay {
  constructor(scene, ev) {
    this.group = new THREE.Group();
    this.group.renderOrder = 2;
    this.labels = [];
    this.paths = [];
    this.areas = [];
    this.fade = 0;
    this.target = 1;
    this.t0 = now();
    scene.add(this.group);

    for (const a of ev.areas || []) this.addArea(a);
    (ev.paths || []).forEach((p, i) => this.addPath(p, i));
    for (const p of ev.points || []) this.addPoint(p);
  }

  addArea(a) {
    this.areaDefs = this.areaDefs || [];
    this.areaDefs.push(a);
    const m = areaMeshes(a.poly, { color: a.color, hyp: a.dashed ?? a.hyp });
    m.fillOpacity = a.fillOpacity ?? 0.2;
    m.outline.geometry.instanceCount = Infinity;
    this.group.add(m.fill, m.outline);
    this.areas.push(m);
    if (!a.name) return;
    const c = a.labelAt || m.center;
    const el = labelEl('area', `<span>${esc(a.name)}${a.hyp ? ' <em>?</em>' : ''}</span>`);
    el.style.setProperty('--c', a.color);
    addLabel(this, { el, pos: ll(c[0], c[1], 1.003), delay: 0.6 });
  }

  addPath(p, i) {
    const pts = curve(p.pts, 0.0035);
    const halo = makeLine(pts, { color: p.color, width: (p.width || 3) * 3.2 });
    const line = makeLine(pts, { color: p.color, width: p.width || 3, dashed: p.hyp });
    halo.geometry.instanceCount = 0;
    line.geometry.instanceCount = 0;
    this.group.add(halo, line);
    const lens = [0];
    for (let k = 1; k < pts.length; k++) lens.push(lens[k - 1] + pts[k].distanceTo(pts[k - 1]));
    const path = { pts, lens, halo, line, delay: p.delay ?? 1.4 + i * 0.35, dur: p.dur ?? 3 };
    if (p.travel) {
      const el = labelEl('traveler', '');
      el.style.setProperty('--c', p.color);
      path.traveler = addLabel(this, { el, pos: pts[0].clone(), traveler: true });
    }
    if (p.label) {
      const el = labelEl('path', `<span>${esc(p.label)}</span>`);
      el.style.setProperty('--c', p.color);
      addLabel(this, { el, pos: pts[Math.floor((pts.length - 1) * (p.labelAt ?? 0.55))], delay: path.delay + path.dur * 0.6 });
    }
    this.paths.push(path);
  }

  addPoint(p) {
    const cls = ['pt', p.kind || 'city', p.hyp ? 'hyp' : '', p.minor ? 'minor' : ''].join(' ');
    const el = labelEl(cls, `<i></i><span>${esc(p.name)}${p.hyp ? ' <em>?</em>' : ''}</span>`);
    addLabel(this, { el, pos: ll(p.lat, p.lon, 1.003), delay: 0.9 });
  }

  update(dt, t) {
    this.fade += Math.sign(this.target - this.fade) * Math.min(Math.abs(this.target - this.fade), dt * (this.target ? 1.2 : 2.5));
    const age = t - this.t0;
    for (const a of this.areas) {
      a.fill.material.opacity = a.fillOpacity * this.fade;
      a.outline.material.opacity = 0.85 * this.fade;
    }
    for (const p of this.paths) {
      const prog = clamp01((age - p.delay) / p.dur);
      const e = easeInOut(prog);
      const n = Math.floor(e * p.line.userData.segments);
      p.line.geometry.instanceCount = n;
      p.halo.geometry.instanceCount = n;
      p.line.material.opacity = this.fade;
      p.halo.material.opacity = 0.18 * this.fade;
      if (p.traveler) {
        // пока линия рисуется — точка на её конце, потом бежит по пути по кругу
        const total = p.lens[p.lens.length - 1];
        const cyc = prog < 1 ? e : ((age - p.delay - p.dur) / Math.max(3, p.dur * 1.3)) % 1;
        const target = cyc * total;
        let k = 1;
        while (k < p.lens.length - 1 && p.lens[k] < target) k++;
        const f = (target - p.lens[k - 1]) / Math.max(1e-9, p.lens[k] - p.lens[k - 1]);
        p.traveler.pos.copy(p.pts[k - 1]).lerp(p.pts[k], clamp01(f));
        p.traveler.hidden = age < p.delay;
      }
    }
  }

  get isDone() { return this.target === 0 && this.fade <= 0; }

  dispose() {
    disposeGroup(this.group);
    removeLabels(this);
  }
}

// ---------------------------------------------------------------- народ Божий и отпавшие общества

export const COMMUNITY_COLORS = {
  church: '#3d9bff',   // народ Божий, Церковь
  fallen: '#ff5f5f',   // отпавшие (Северный Израиль, иудеи после отвержения Христа…)
  human: '#ff6a4a',    // самочинные человеческие общества
};

export function pointInPoly(lat, lon, poly) {
  let inside = false;
  for (let i = 0, j = poly.length - 1; i < poly.length; j = i++) {
    const [ai, oi] = poly[i], [aj, oj] = poly[j];
    if ((ai > lat) !== (aj > lat) && lon < ((oj - oi) * (lat - ai)) / (aj - ai) + oi) inside = !inside;
  }
  return inside;
}

// Все общины одного рода сливаются в одно поле: Церковь — голубое, отделившиеся и самочинные — красное.
// Каждая запись рисуется «ядром» (её областью) и широким слабым «ореолом»: где ореолы соседних общин
// перекрываются, поле переходит порог и области сливаются в общую границу; густота внутри — «очаги».
// Поле рисуется на развёртке (canvas) и накладывается на шар шейдером; при смене года — плавный переход.
const FIELD_W = 2048, FIELD_H = 1024, HUE_W = 1024, HUE_H = 512;
// SEAM_DEG — обводка стран, чтобы соседние срастались без щелей; MIN_DEG — наименьший радиус очага
const SEAM_DEG = 0.3, MIN_DEG = 0.4;

function makeCanvas(w, h) {
  const c = document.createElement('canvas');
  c.width = w; c.height = h;
  return c;
}

export class CommunityLayer {
  constructor(scene, entries) {
    this.entries = entries;
    this.enabled = true;
    this.active = [];
    this.labels = [];
    this.raw = makeCanvas(FIELD_W, FIELD_H);
    this.fields = [makeCanvas(FIELD_W, FIELD_H), makeCanvas(FIELD_W, FIELD_H)];
    this.hues = [makeCanvas(HUE_W, HUE_H), makeCanvas(HUE_W, HUE_H)];
    this.fieldTex = this.fields.map((c) => new THREE.CanvasTexture(c));
    this.hueTex = this.hues.map((c) => new THREE.CanvasTexture(c));
    this.front = 0;
    this.mix = { v: 0, to: 0 };
    this.key = null;

    this.uniforms = {
      fieldA: { value: this.fieldTex[0] }, fieldB: { value: this.fieldTex[1] },
      hueA: { value: this.hueTex[0] }, hueB: { value: this.hueTex[1] },
      mixAB: { value: 0 }, church: { value: new THREE.Color(COMMUNITY_COLORS.church) }, human: { value: new THREE.Color(COMMUNITY_COLORS.human) },
    };
    this.mesh = new THREE.Mesh(
      new THREE.SphereGeometry(1.0016, 192, 96),
      new THREE.ShaderMaterial({
        uniforms: this.uniforms,
        transparent: true,
        depthWrite: false,
        vertexShader: /* glsl */`
          varying vec2 vUv;
          void main() { vUv = uv; gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0); }`,
        fragmentShader: /* glsl */`
          uniform sampler2D fieldA, fieldB, hueA, hueB;
          uniform float mixAB;
          uniform vec3 church, human;
          varying vec2 vUv;
          // граница по порогу поля
          float edgeOf(float d) {
            float w = min(fwidth(d), 0.2) + 0.02;
            return 1.0 - smoothstep(w * 1.2, w * 3.5, abs(d - 0.5));
          }
          float insideOf(float d) {
            float w = min(fwidth(d), 0.2) + 0.02;
            return smoothstep(0.5 - w, 0.5 + w, d);
          }
          void main() {
            vec4 fa = texture2D(fieldA, vUv), fb = texture2D(fieldB, vUv);
            vec4 ha = texture2D(hueA, vUv), hb = texture2D(hueB, vUv);
            float dc = mix(fa.r, fb.r, mixAB);
            float dh = mix(fa.g, fb.g, mixAB);
            vec3 hue = mix(ha.rgb / max(ha.a, 0.02), hb.rgb / max(hb.a, 0.02), mixAB);
            hue = mix(human, hue, smoothstep(0.02, 0.15, mix(ha.a, hb.a, mixAB)));

            // отделившиеся и самочинные: контур и штриховка, без заливки
            float inH = insideOf(dh);
            float stripe = step(0.72, fract((gl_FragCoord.x + gl_FragCoord.y) / 8.0));
            float aH = max(inH * stripe * 0.5, edgeOf(dh));
            // Церковь: ровная слабая заливка и контур; там, где красная область, голубое не рисуем
            float keep = 1.0 - inH;
            float aC = max(insideOf(dc) * 0.3, edgeOf(dc) * 0.95) * keep;

            // очаги Церкви поверх всего
            float db = mix(fa.b, fb.b, mixAB);
            float aB = max(insideOf(db) * 0.4, edgeOf(db));
            aC = max(aC, aB);

            vec3 col = (aH > aC) ? hue : church;
            gl_FragColor = vec4(col, clamp(max(aC, aH), 0.0, 0.95));
            #include <colorspace_fragment>
          }`,
      }),
    );
    this.mesh.renderOrder = 1;
    scene.add(this.mesh);
  }

  // контур записи в пикселях развёртки
  path(ctx, e, w, h, grow = 0) {
    const x = (lon) => ((lon + 180) / 360) * w;
    const y = (lat) => ((90 - lat) / 180) * h;
    ctx.beginPath();
    if (e.circle) {
      const [la, lo, r] = e.circle;
      const rr = Math.max(r, MIN_DEG) + grow;
      ctx.ellipse(x(lo), y(la), (rr / 360) * w / Math.cos(la * Math.PI / 180), (rr / 180) * h, 0, 0, Math.PI * 2);
    } else {
      e.poly.forEach(([la, lo], i) => (i ? ctx.lineTo(x(lo), y(la)) : ctx.moveTo(x(lo), y(la))));
      ctx.closePath();
    }
  }

  draw(active) {
    const raw = this.raw.getContext('2d');
    raw.clearRect(0, 0, FIELD_W, FIELD_H);
    raw.globalCompositeOperation = 'lighter';
    const back = 1 - this.front;
    const hue = this.hues[back].getContext('2d');
    hue.clearRect(0, 0, HUE_W, HUE_H);
    const pxDeg = FIELD_W / 360;
    for (const e of active) {
      const isChurch = e.kind === 'church';
      // маски: Церковь — в красный канал, отделившиеся и самочинные — в зелёный; соседние страны
      // срастаются за счёт узкой обводки (SEAM_DEG), без размытых ореолов
      // очаги Церкви (круги) — в синий канал: они видны и поверх красных областей (православные в городах)
      raw.fillStyle = raw.strokeStyle = isChurch ? (e.circle ? 'rgb(0,0,255)' : 'rgb(255,0,0)') : 'rgb(0,255,0)';
      this.path(raw, e, FIELD_W, FIELD_H);
      raw.fill();
      if (!e.circle) { raw.lineWidth = SEAM_DEG * 2 * pxDeg; raw.lineJoin = 'round'; raw.stroke(); }
      if (!isChurch) {
        hue.fillStyle = hue.strokeStyle = e.color || COMMUNITY_COLORS[e.kind];
        this.path(hue, e, HUE_W, HUE_H, e.circle ? 1 : 0);
        hue.fill();
        if (!e.circle) { hue.lineWidth = 2 * (HUE_W / 360); hue.lineJoin = 'round'; hue.stroke(); }
      }
    }
    const field = this.fields[back].getContext('2d');
    field.clearRect(0, 0, FIELD_W, FIELD_H);
    if ('filter' in field) field.filter = 'blur(1px)';
    field.drawImage(this.raw, 0, 0);
    field.filter = 'none';
    this.fieldTex[back].needsUpdate = true;
    this.hueTex[back].needsUpdate = true;
    this.front = back;
    this.mix.to = back;
  }

  setYear(year, show) {
    const active = show && this.enabled ? this.entries.filter((e) => e.from <= year && year < e.to) : [];
    const key = active.map((e) => e.id).join(',');
    this.active = active;
    if (key === this.key) return;
    this.key = key;
    this.draw(active);
  }

  // какие общины в этой точке (для подсказки при наведении)
  at(lat, lon) {
    return this.active.filter((e) => {
      if (e.circle) {
        const [la, lo, r] = e.circle;
        const dx = (lon - lo) * Math.cos(la * Math.PI / 180);
        return Math.hypot(lat - la, dx) <= Math.max(r, MIN_DEG);
      }
      return pointInPoly(lat, lon, e.poly);
    });
  }

  update(dt) {
    const k = 1 - Math.exp(-dt * 1.6);
    this.mix.v += (this.mix.to - this.mix.v) * k;
    this.uniforms.mixAB.value = this.mix.v;
  }
}

// ---------------------------------------------------------------- праведники, пророки, апостолы

// Человек виден, пока жив; places — где он жил в разные годы: [[с какого года, lat, lon], ...]
export class PersonsLayer {
  constructor(persons, siteUrl) {
    this.persons = persons;
    this.siteUrl = siteUrl;
    this.items = new Map();
    this.labels = [];
    this.fade = 1;
    this.t0 = now();
    this.enabled = true;
  }

  placeAt(p, year) {
    let at = p.places[0];
    for (const pl of p.places) if (pl[0] <= year) at = pl;
    return ll(at[1], at[2], 1.003);
  }

  // Подписан только тот, о ком говорит текущее событие; остальные — точкой, имя видно при наведении
  static tokens(p) {
    if (p.match) return p.match;
    let name = p.name;
    const prefix = /^(Господь|Пресвятая|Праведный|Праведные|Сщмч\.|Свт\.|Мч\.|Прп\.|Блж\.|Апостол|Евангелист|Пророк|Пророчица|Первомученик|Диакон|Первосвященник|Мученики)\s+/;
    while (prefix.test(name)) name = name.replace(prefix, '');
    const word = name.split(/[\s,(]/)[0];
    return [word.length > 5 ? word.slice(0, word.length - 1) : word];
  }

  setYear(year, show, ev) {
    const said = ev ? `${ev.title} ${ev.when || ''} ${ev.text}` : '';
    for (const p of this.persons) {
      const alive = show && this.enabled && p.from <= year && year <= p.to;
      const quiet = !PersonsLayer.tokens(p).some((t) => said.includes(t));
      let it = this.items.get(p.id);
      if (alive && !it) {
        const tag = p.link ? 'a' : 'div';
        const el = document.createElement(tag);
        el.className = `lbl person ${p.kind || ''}${p.hyp ? ' hyp' : ''}`;
        el.innerHTML = `<i></i><span>${esc(p.name)}</span>`;
        if (p.link) { el.href = this.siteUrl + 'w/' + p.link; el.target = '_blank'; el.rel = 'noopener'; el.title = 'Открыть страницу на сайте'; }
        labelsHost.appendChild(el);
        const pos = this.placeAt(p, year);
        it = { p, label: addLabel(this, { el, pos: pos.clone(), delay: 1.5, t0: now(), fade: 0 }), target: 1, from: pos.clone(), to: pos, moveT0: 0 };
        this.items.set(p.id, it);
      }
      if (it && it.label.el.classList.contains('quiet') !== quiet) {
        it.label.el.classList.toggle('quiet', quiet);
        it.label.w = 0;
      }
      if (it) {
        it.target = alive ? 1 : 0;
        if (alive) {
          const pos = this.placeAt(p, year);
          if (!pos.equals(it.to)) { it.from = it.label.pos.clone(); it.to = pos; it.moveT0 = now() + 0.8; }
        }
      }
    }
  }

  update(dt, t) {
    for (const [id, it] of this.items) {
      const l = it.label;
      l.fade += Math.sign(it.target - l.fade) * Math.min(Math.abs(it.target - l.fade), dt * 1.5);
      const k = easeInOut(clamp01((t - it.moveT0) / 2.5));
      l.pos.copy(it.from).lerp(it.to, k).normalize().multiplyScalar(1.003);
      if (it.target === 0 && l.fade <= 0) {
        l.el.remove();
        allLabels.delete(l);
        this.labels = this.labels.filter((x) => x !== l);
        this.items.delete(id);
      }
    }
  }
}

// ---------------------------------------------------------------- державы (политическая карта)

// Бледные пунктирные границы держав по годам. Видны, если включён переключатель
// или если событие само просит их показать (например, гонение шло в границах империи).
export class PoliticsLayer {
  constructor(scene, entries) {
    this.scene = scene;
    this.entries = entries;
    this.enabled = false;
    this.items = new Map();
    this.labels = [];
    this.fade = 1;
    this.t0 = now();
  }

  setYear(year, forced) {
    const on = this.enabled || forced;
    const active = new Set(on ? this.entries.filter((e) => e.from <= year && year < e.to).map((e) => e.id) : []);
    for (const [id, it] of this.items) if (!active.has(id)) it.target = 0;
    for (const e of this.entries) {
      if (!active.has(e.id)) continue;
      const it = this.items.get(e.id);
      if (it) { it.target = 1; continue; }
      const group = new THREE.Group();
      const parts = (e.polys || [e.poly]).map((poly) => areaMeshes(poly, { color: e.color, hyp: true, outlineWidth: 1.4, r: 1.0012 }));
      for (const m of parts) { m.outline.geometry.instanceCount = Infinity; group.add(m.fill, m.outline); }
      this.scene.add(group);
      const item = { group, parts, fade: 0, target: 1, labels: [], t0: now() };
      if (e.name) {
        const c = e.labelAt || parts[0].center;
        const el = labelEl('area polity', `<span>${esc(e.name)}</span>`);
        el.style.setProperty('--c', e.color);
        addLabel(item, { el, pos: ll(c[0], c[1], 1.003), delay: 0.8 });
      }
      this.items.set(e.id, item);
    }
  }

  update(dt) {
    for (const [id, it] of this.items) {
      it.fade += Math.sign(it.target - it.fade) * Math.min(Math.abs(it.target - it.fade), dt * 1.5);
      for (const m of it.parts) { m.fill.material.opacity = 0.045 * it.fade; m.outline.material.opacity = 0.6 * it.fade; }
      if (it.target === 0 && it.fade <= 0) { disposeGroup(it.group); removeLabels(it); this.items.delete(id); }
    }
  }
}
