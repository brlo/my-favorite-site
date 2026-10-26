import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { Line2 } from 'three/addons/lines/Line2.js';
import { LineMaterial } from 'three/addons/lines/LineMaterial.js';
import { LineGeometry } from 'three/addons/lines/LineGeometry.js';
import { ERAS, EVENTS, WORLD, CREATION_BC } from 'bible_map/events';

const DEG = Math.PI / 180;
// адреса текстур (на res.bibleox.com) и ссылок на стихи приходят из разметки страницы
const CONFIG = document.body.dataset;
const BIBLE_URL = CONFIG.bibleUrl;

// Широта/долгота → точка на сфере (совпадает с UV-развёрткой SphereGeometry)
function ll(lat, lon, r = 1) {
  const phi = (90 - lat) * DEG;
  const l = lon * DEG;
  return new THREE.Vector3(Math.sin(phi) * Math.cos(l) * r, Math.cos(phi) * r, -Math.sin(phi) * Math.sin(l) * r);
}

const clamp01 = (x) => Math.min(1, Math.max(0, x));
const easeInOut = (t) => (t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2);
const smooth = (a, b, x) => { const t = clamp01((x - a) / (b - a)); return t * t * (3 - 2 * t); };

// ---------------------------------------------------------------- сцена

const host = document.getElementById('scene');
const labelsHost = document.getElementById('labels');
const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setSize(window.innerWidth, window.innerHeight);
host.appendChild(renderer.domElement);

const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(40, window.innerWidth / window.innerHeight, 0.01, 2000);
camera.position.set(0, 0, 4);

const controls = new OrbitControls(camera, renderer.domElement);
controls.enableDamping = true;
controls.dampingFactor = 0.08;
controls.enablePan = false;
controls.rotateSpeed = 0.45;
controls.zoomSpeed = 0.7;
controls.minDistance = 0.06;
controls.maxDistance = 12;
controls.autoRotateSpeed = 0.35;

const manager = new THREE.LoadingManager();
const loader = new THREE.TextureLoader(manager);
const maxAniso = renderer.capabilities.getMaxAnisotropy();
function texture(url, color = true) {
  const t = loader.load(url);
  if (color) t.colorSpace = THREE.SRGBColorSpace;
  t.anisotropy = maxAniso;
  return t;
}

const dayMap = texture(CONFIG.earthDay);
const reliefMap = texture(CONFIG.earthRelief, false);
const cloudMap = texture(CONFIG.clouds, false);
const moonMap = texture(CONFIG.moon);

// ---------------------------------------------------------------- состояние среды

const now = () => performance.now() / 1000;
const env = {};
for (const k of Object.keys(WORLD)) env[k] = { v: WORLD[k], from: WORLD[k], to: WORLD[k], t0: 0, dur: 0 };

function envSet(k, v) { Object.assign(env[k], { v, from: v, to: v, dur: 0 }); }
function envTo(k, v, dur, delay) { Object.assign(env[k], { from: env[k].v, to: v, t0: now() + delay, dur }); }
function envTick(t) {
  for (const e of Object.values(env)) {
    if (t < e.t0) continue;
    const p = e.dur > 0 ? clamp01((t - e.t0) / e.dur) : 1;
    e.v = e.from + (e.to - e.from) * easeInOut(p);
  }
}
const E = (k) => env[k].v;

function applyEnv(ev) {
  if (ev.from) for (const [k, v] of Object.entries(ev.from)) envSet(k, v);
  const full = { ...WORLD, ...ev.env };
  for (const [k, spec] of Object.entries(full)) {
    const [v, dur = 1.8, delay = 0] = Array.isArray(spec) ? spec : [spec];
    envTo(k, v, dur, delay);
  }
}

// ---------------------------------------------------------------- Земля

const lightDir = new THREE.Vector3(1, 0.3, 0.5).normalize();
const SUN_DIR = ll(4, 168).normalize();

const globeUniforms = {
  dayMap: { value: dayMap },
  reliefMap: { value: reliefMap },
  water: { value: 0 },
  veg: { value: 1 },
  light: { value: 1 },
  ambient: { value: 0.15 },
  warm: { value: 0 },
  time: { value: 0 },
  lightDir: { value: lightDir },
};

const globe = new THREE.Mesh(
  new THREE.SphereGeometry(1, 256, 128),
  new THREE.ShaderMaterial({
    uniforms: globeUniforms,
    vertexShader: /* glsl */`
      varying vec2 vUv;
      varying vec3 vPos;
      void main() {
        vUv = uv;
        vPos = position;
        gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
      }`,
    fragmentShader: /* glsl */`
      uniform sampler2D dayMap, reliefMap;
      uniform float water, veg, light, ambient, warm, time;
      uniform vec3 lightDir;
      varying vec2 vUv;
      varying vec3 vPos;

      float hash(vec3 p) { return fract(sin(dot(p, vec3(12.9898, 78.233, 45.164))) * 43758.5453); }
      float noise(vec3 p) {
        vec3 i = floor(p), f = fract(p);
        f = f * f * (3.0 - 2.0 * f);
        return mix(mix(mix(hash(i), hash(i + vec3(1,0,0)), f.x), mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
                   mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x), mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y), f.z);
      }

      void main() {
        vec3 relief = texture2D(reliefMap, vUv).rgb;
        float h = relief.r;
        float ocean = smoothstep(0.3, 0.7, relief.g);
        vec3 day = texture2D(dayMap, vUv).rgb;

        // суша видна, если она выше уровня воды
        float land = (1.0 - ocean) * smoothstep(water - 0.006, water + 0.006, h + 0.004);

        float lum = dot(day, vec3(0.299, 0.587, 0.114));
        vec3 barren = vec3(lum) * vec3(1.05, 0.86, 0.66) + vec3(0.03, 0.02, 0.0);
        vec3 landCol = mix(barren, day, veg);

        // первозданные воды и потоп — однотонная глубокая вода с рябью
        float primeval = smoothstep(0.04, 0.25, water);
        float depth = clamp(water - h, 0.0, 1.0);
        float ripple = noise(vPos * 90.0 + vec3(time * 0.15)) * 0.5 + noise(vPos * 23.0 - vec3(time * 0.05)) * 0.5;
        vec3 floodCol = mix(vec3(0.025, 0.09, 0.13), vec3(0.004, 0.018, 0.045), smoothstep(0.0, 0.3, depth));
        floodCol *= 0.8 + ripple * 0.4;
        vec3 seaCol = mix(day, floodCol, primeval);
        vec3 col = mix(seaCol, landCol, land);

        vec3 N = normalize(vPos);
        float d = dot(N, lightDir);
        float diff = smoothstep(-0.12, 0.55, d);
        vec3 V = normalize(cameraPosition - vPos);
        vec3 H = normalize(lightDir + V);
        float spec = pow(max(dot(N, H), 0.0), 160.0) * 0.3 * (1.0 - land) * step(0.0, d) * (0.6 + ripple * 0.8);

        vec3 lit = col * (ambient + diff * light) + spec * light * vec3(1.0, 0.95, 0.85);
        lit = mix(lit, lit * vec3(1.18, 1.02, 0.78) + vec3(0.03, 0.02, 0.0), warm);
        gl_FragColor = vec4(lit, 1.0);
        #include <colorspace_fragment>
      }`,
  }),
);
scene.add(globe);

// Облака
const cloudUniforms = {
  map: { value: cloudMap }, amount: { value: 0 }, dark: { value: 0 }, light: { value: 1 }, ambient: { value: 0.1 }, lightDir: { value: lightDir },
};
const clouds = new THREE.Mesh(
  new THREE.SphereGeometry(1.006, 128, 64),
  new THREE.ShaderMaterial({
    uniforms: cloudUniforms,
    transparent: true,
    depthWrite: false,
    vertexShader: /* glsl */`
      varying vec2 vUv; varying vec3 vN;
      void main() { vUv = uv; vN = normalize(position); gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0); }`,
    fragmentShader: /* glsl */`
      uniform sampler2D map; uniform float amount, dark, light, ambient; uniform vec3 lightDir;
      varying vec2 vUv; varying vec3 vN;
      void main() {
        float c = texture2D(map, vUv).r;
        float a = smoothstep(0.15 + dark * 0.1, 0.9, c + dark * 0.12) * amount * (1.0 - dark * 0.3);
        float diff = smoothstep(-0.12, 0.55, dot(normalize(vN), lightDir));
        vec3 col = mix(vec3(1.0), vec3(0.32, 0.34, 0.38), dark) * (ambient + diff * light);
        gl_FragColor = vec4(col, a * (0.85 + dark * 0.15));
        #include <colorspace_fragment>
      }`,
  }),
);
scene.add(clouds);

// Атмосфера — свечение по краю диска
const atmoUniforms = { amount: { value: 1 }, lightDir: { value: lightDir }, light: { value: 1 }, warm: { value: 0 } };
const atmosphere = new THREE.Mesh(
  new THREE.SphereGeometry(1.1, 96, 48),
  new THREE.ShaderMaterial({
    uniforms: atmoUniforms,
    side: THREE.BackSide,
    transparent: true,
    depthWrite: false,
    blending: THREE.AdditiveBlending,
    vertexShader: /* glsl */`
      varying vec3 vN; varying vec3 vView;
      void main() {
        vN = normalize(position);
        vec4 wp = modelMatrix * vec4(position, 1.0);
        vView = normalize(cameraPosition - wp.xyz);
        gl_Position = projectionMatrix * viewMatrix * wp;
      }`,
    fragmentShader: /* glsl */`
      uniform float amount, light, warm; uniform vec3 lightDir;
      varying vec3 vN; varying vec3 vView;
      void main() {
        float rim = pow(clamp(1.0 + dot(vView, vN) * 1.0, 0.0, 1.0), 2.5);
        float sun = smoothstep(-0.35, 0.6, dot(vN, lightDir));
        vec3 col = mix(vec3(0.35, 0.6, 1.0), vec3(1.0, 0.8, 0.5), warm * 0.6);
        gl_FragColor = vec4(col * rim * (0.25 + sun * light) * amount * 1.4, 1.0);
      }`,
  }),
);
scene.add(atmosphere);

// Звёзды
const starGeo = new THREE.BufferGeometry();
{
  const n = 7000, pos = new Float32Array(n * 3), col = new Float32Array(n * 3);
  for (let i = 0; i < n; i++) {
    const v = new THREE.Vector3().randomDirection().multiplyScalar(600);
    pos.set([v.x, v.y, v.z], i * 3);
    const b = 0.35 + Math.pow(Math.random(), 3) * 0.65;
    const tint = Math.random();
    col.set([b * (tint > 0.85 ? 1 : 0.85), b * 0.9, b * (tint < 0.2 ? 0.75 : 1)], i * 3);
  }
  starGeo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  starGeo.setAttribute('color', new THREE.BufferAttribute(col, 3));
}
const starMat = new THREE.PointsMaterial({ size: 1.6, sizeAttenuation: false, vertexColors: true, transparent: true, depthWrite: false });
scene.add(new THREE.Points(starGeo, starMat));

// Солнце — спрайт с радиальным градиентом
function glowTexture(stops) {
  const c = document.createElement('canvas');
  c.width = c.height = 256;
  const g = c.getContext('2d');
  const grad = g.createRadialGradient(128, 128, 0, 128, 128, 128);
  for (const [o, s] of stops) grad.addColorStop(o, s);
  g.fillStyle = grad;
  g.fillRect(0, 0, 256, 256);
  const t = new THREE.CanvasTexture(c);
  t.colorSpace = THREE.SRGBColorSpace;
  return t;
}
const sunMat = new THREE.SpriteMaterial({
  map: glowTexture([[0, 'rgba(255,255,250,1)'], [0.12, 'rgba(255,245,215,1)'], [0.22, 'rgba(255,210,140,0.55)'], [0.5, 'rgba(255,170,80,0.12)'], [1, 'rgba(255,150,60,0)']]),
  transparent: true, depthWrite: false, blending: THREE.AdditiveBlending,
});
const sun = new THREE.Sprite(sunMat);
sun.position.copy(SUN_DIR).multiplyScalar(120);
sun.scale.setScalar(40);
scene.add(sun);

// Луна
const moon = new THREE.Mesh(
  new THREE.SphereGeometry(0.27, 64, 32),
  new THREE.MeshLambertMaterial({ map: moonMap, transparent: true }),
);
scene.add(moon);
const moonLight = new THREE.DirectionalLight(0xffffff, 2.2);
scene.add(moonLight);
scene.add(new THREE.AmbientLight(0xffffff, 0.08));

// Птицы — точки, летящие по большим кругам над Землёй
const BIRDS = 900;
const birdData = Array.from({ length: BIRDS }, () => {
  // стаи: несколько центров, вокруг них разброс
  const flock = Math.floor(Math.random() * 14);
  const rnd = (s) => { const x = Math.sin(s * 999.1) * 43758.5; return x - Math.floor(x); };
  const axis = new THREE.Vector3(rnd(flock + 1) - 0.5, rnd(flock + 2) - 0.5, rnd(flock + 3) - 0.5).normalize();
  const jitter = new THREE.Vector3().randomDirection().multiplyScalar(0.06);
  axis.add(jitter).normalize();
  return { axis, phase: rnd(flock + 4) * Math.PI * 2 + (Math.random() - 0.5) * 0.12, r: 1.012 + Math.random() * 0.02, speed: 0.06 + rnd(flock + 5) * 0.05 };
});
const birdGeo = new THREE.BufferGeometry();
birdGeo.setAttribute('position', new THREE.BufferAttribute(new Float32Array(BIRDS * 3), 3));
const birdMat = new THREE.PointsMaterial({ size: 2.2, sizeAttenuation: false, color: 0xfff6e0, transparent: true, depthWrite: false });
const birds = new THREE.Points(birdGeo, birdMat);
scene.add(birds);
const _q = new THREE.Quaternion();
const _base = new THREE.Vector3();
function updateBirds(t) {
  const pos = birdGeo.attributes.position.array;
  for (let i = 0; i < BIRDS; i++) {
    const b = birdData[i];
    // вектор, перпендикулярный оси, поворачиваем вокруг оси
    _base.set(1, 0, 0);
    if (Math.abs(b.axis.x) > 0.9) _base.set(0, 1, 0);
    _base.cross(b.axis).normalize();
    _q.setFromAxisAngle(b.axis, b.phase + t * b.speed);
    _base.applyQuaternion(_q).multiplyScalar(b.r);
    pos[i * 3] = _base.x; pos[i * 3 + 1] = _base.y; pos[i * 3 + 2] = _base.z;
  }
  birdGeo.attributes.position.needsUpdate = true;
}

// ---------------------------------------------------------------- слои события: области, пути, точки

const linesMaterials = new Set();

function densify(latlons, stepDeg = 0.25) {
  const out = [];
  for (let i = 0; i < latlons.length; i++) {
    const a = latlons[i], b = latlons[(i + 1) % latlons.length];
    const n = Math.max(1, Math.ceil(Math.hypot(b[0] - a[0], b[1] - a[1]) / stepDeg));
    for (let j = 0; j < n; j++) out.push([a[0] + (b[0] - a[0]) * j / n, a[1] + (b[1] - a[1]) * j / n]);
  }
  return out;
}

// Гладкая кривая по опорным точкам, прижатая к поверхности
function curve(latlons, alt) {
  const vs = latlons.map(([la, lo]) => ll(la, lo));
  let pts;
  if (vs.length > 2) {
    let len = 0;
    for (let i = 1; i < vs.length; i++) len += vs[i].angleTo(vs[i - 1]);
    pts = new THREE.CatmullRomCurve3(vs, false, 'centripetal').getSpacedPoints(Math.max(40, Math.ceil(len / 0.0015)));
  } else {
    const n = Math.max(20, Math.ceil(vs[0].angleTo(vs[1]) / 0.0015));
    pts = [];
    for (let i = 0; i <= n; i++) pts.push(vs[0].clone().lerp(vs[1], i / n));
  }
  return pts.map((p) => p.normalize().multiplyScalar(1 + alt));
}

function makeLine(pts, { color, width, dashed, opacity = 1 }) {
  const geo = new LineGeometry();
  geo.setPositions(pts.flatMap((p) => [p.x, p.y, p.z]));
  let len = 0;
  for (let i = 1; i < pts.length; i++) len += pts[i].distanceTo(pts[i - 1]);
  const mat = new LineMaterial({
    color, linewidth: width, transparent: true, depthWrite: false, opacity: 0,
    dashed: !!dashed, dashSize: Math.max(len / 70, 0.002), gapSize: Math.max(len / 110, 0.0013),
  });
  mat.resolution.set(window.innerWidth, window.innerHeight);
  linesMaterials.add(mat);
  const line = new Line2(geo, mat);
  line.computeLineDistances();
  line.userData = { segments: pts.length - 1, baseOpacity: opacity };
  geo.instanceCount = 0;
  return line;
}

function labelEl(cls, html) {
  const el = document.createElement('div');
  el.className = 'lbl ' + cls;
  el.innerHTML = html;
  labelsHost.appendChild(el);
  return el;
}

class Overlay {
  constructor(ev) {
    this.group = new THREE.Group();
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
    const ring = densify(a.poly);
    const contour = ring.map(([la, lo]) => new THREE.Vector2(lo, la));
    const tris = THREE.ShapeUtils.triangulateShape(contour, []);
    const pos = ring.flatMap(([la, lo]) => { const v = ll(la, lo, 1.0025); return [v.x, v.y, v.z]; });
    const geo = new THREE.BufferGeometry();
    geo.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
    geo.setIndex(tris.flat());
    const fill = new THREE.Mesh(geo, new THREE.MeshBasicMaterial({
      color: a.color, transparent: true, opacity: 0, depthWrite: false, side: THREE.DoubleSide,
      polygonOffset: true, polygonOffsetFactor: -2, polygonOffsetUnits: -2,
    }));
    const outlinePts = ring.concat([ring[0]]).map(([la, lo]) => ll(la, lo, 1.003));
    const outline = makeLine(outlinePts, { color: a.color, width: 1.6, dashed: a.hyp, opacity: 0.85 });
    outline.geometry.instanceCount = Infinity;
    this.group.add(fill, outline);
    this.areas.push({ fill, outline });

    // подпись области — в «центре тяжести» кольца
    const c = a.labelAt || ring.reduce((s, [la, lo]) => [s[0] + la, s[1] + lo], [0, 0]).map((x) => x / ring.length);
    if (!a.name) return;
    const el = labelEl('area', `<span>${a.name}${a.hyp ? ' <em>?</em>' : ''}</span>`);
    el.style.setProperty('--c', a.color);
    this.labels.push({ el, pos: ll(c[0], c[1], 1.003), delay: 0.6 });
  }

  addPath(p, i) {
    const pts = curve(p.pts, 0.0035);
    const halo = makeLine(pts, { color: p.color, width: (p.width || 3) * 3.2, opacity: 0.18 });
    const line = makeLine(pts, { color: p.color, width: p.width || 3, dashed: p.hyp, opacity: 1 });
    this.group.add(halo, line);
    const lens = [0];
    for (let k = 1; k < pts.length; k++) lens.push(lens[k - 1] + pts[k].distanceTo(pts[k - 1]));
    const path = {
      pts, lens, halo, line,
      delay: p.delay ?? 1.4 + i * 0.35,
      dur: p.dur ?? 3,
      traveler: p.travel ? labelEl('traveler', '') : null,
    };
    if (path.traveler) {
      path.traveler.style.setProperty('--c', p.color);
      this.labels.push({ el: path.traveler, pos: pts[0].clone(), traveler: true });
    }
    if (p.label) {
      const mid = pts[Math.floor((pts.length - 1) * (p.labelAt ?? 0.55))];
      const el = labelEl('path', `<span>${p.label}</span>`);
      el.style.setProperty('--c', p.color);
      this.labels.push({ el, pos: mid, delay: path.delay + path.dur * 0.6 });
    }
    this.paths.push(path);
  }

  addPoint(p) {
    const cls = ['pt', p.kind || 'city', p.hyp ? 'hyp' : '', p.minor ? 'minor' : ''].join(' ');
    const el = labelEl(cls, `<i></i><span>${p.name}${p.hyp ? ' <em>?</em>' : ''}</span>`);
    this.labels.push({ el, pos: ll(p.lat, p.lon, 1.003), delay: 0.9 });
  }

  update(dt, t) {
    this.fade += Math.sign(this.target - this.fade) * Math.min(Math.abs(this.target - this.fade), dt * (this.target ? 1.2 : 2.5));
    const age = t - this.t0;

    for (const a of this.areas) {
      a.fill.material.opacity = 0.2 * this.fade;
      a.outline.material.opacity = 0.85 * this.fade;
    }
    for (const p of this.paths) {
      const prog = clamp01((age - p.delay) / p.dur);
      const e = easeInOut(prog);
      const segs = p.line.userData.segments;
      p.line.geometry.instanceCount = Math.floor(e * segs);
      p.halo.geometry.instanceCount = Math.floor(e * segs);
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
        const lbl = this.labels.find((l) => l.el === p.traveler);
        lbl.pos.copy(p.pts[k - 1]).lerp(p.pts[k], clamp01(f));
        lbl.hidden = age < p.delay;
      }
    }
  }

  dispose() {
    scene.remove(this.group);
    this.group.traverse((o) => {
      if (o.geometry) o.geometry.dispose();
      if (o.material) { linesMaterials.delete(o.material); o.material.dispose(); }
    });
    for (const l of this.labels) l.el.remove();
  }
}

const _v = new THREE.Vector3();
const _toCam = new THREE.Vector3();
// Приоритет подписи при наложении: области важнее городов, второстепенные — последними
const labelPriority = (el) => (el.classList.contains('area') ? 3 : el.classList.contains('minor') ? 1 : el.classList.contains('pt') ? 2 : 1);

function updateLabels(overlays, t) {
  const w = window.innerWidth, h = window.innerHeight;
  const shown = [];
  for (const o of overlays) {
    const age = t - o.t0;
    for (const l of o.labels) {
      _toCam.copy(camera.position).sub(l.pos);
      const facing = _toCam.dot(_v.copy(l.pos).normalize()) / _toCam.length();
      _v.copy(l.pos).project(camera);
      const vis = o.fade * smooth(0.0, 0.15, facing) * smooth(l.delay || 0, (l.delay || 0) + 0.6, age) * (l.hidden ? 0 : 1);
      if (vis < 0.01 || _v.z > 1) { l.el.style.display = 'none'; continue; }
      l.x = ((_v.x + 1) / 2) * w;
      l.y = ((1 - _v.y) / 2) * h;
      l.vis = vis;
      shown.push(l);
    }
  }

  // убираем подписи, налезающие на более важные
  const boxes = [];
  shown.sort((a, b) => (b.prio ??= labelPriority(b.el)) - (a.prio ??= labelPriority(a.el)));
  for (const l of shown) {
    if (!l.traveler) {
      const span = l.el.querySelector('span');
      l.w ??= span ? span.offsetWidth || span.textContent.length * 8 : 0;
      const area = l.el.classList.contains('area') || l.el.classList.contains('path') || l.el.classList.contains('region');
      const box = area ? [l.x - l.w / 2, l.y - 12, l.x + l.w / 2, l.y + 12] : [l.x - 6, l.y - 10, l.x + 12 + l.w, l.y + 8];
      if (boxes.some((b) => box[0] < b[2] && box[2] > b[0] && box[1] < b[3] && box[3] > b[1])) { l.el.style.display = 'none'; continue; }
      boxes.push(box);
    }
    l.el.style.display = '';
    l.el.style.opacity = l.vis;
    l.el.style.transform = `translate(${l.x}px, ${l.y}px)`;
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

const _qa = new THREE.Quaternion();
function updateFly(t) {
  if (!fly) return;
  const k = clamp01((t - fly.t0) / fly.dur);
  const e = easeInOut(k);
  const d0 = fly.p0.clone().normalize(), d1 = fly.p1.clone().normalize();
  _qa.setFromUnitVectors(d0, d1);
  const dir = d0.applyQuaternion(new THREE.Quaternion().slerp(_qa, e));
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

// ---------------------------------------------------------------- UI

const card = document.getElementById('card');
const track = document.getElementById('track');
const playBtn = document.getElementById('play');

function yearLabel(ev) {
  if (ev.era === 'hexa') return ev.when;
  const bc = CREATION_BC - ev.am;
  const years = `ок. ${bc} г. до Р. Х. · ${ev.am} г. от сотворения мира`;
  return ev.when ? `${ev.when}<br>${years}` : years;
}

function renderCard(ev) {
  const era = ERAS.find((e) => e.id === ev.era);
  card.classList.remove('show');
  void card.offsetWidth;
  card.innerHTML = `
    <div class="era">${era.title}</div>
    <h1>${ev.title}</h1>
    <div class="when">${yearLabel(ev)}</div>
    <p>${ev.text}</p>
    <a class="ref" href="${BIBLE_URL}${ev.ref.link}" target="_blank" rel="noopener">${ev.ref.label} <span>→</span></a>`;
  card.classList.add('show');
}

// Положение события на таймлайне: эпохи занимают доли по весу,
// внутри эпохи — линейно по годам; затем раздвигаем слипшиеся метки.
const markerSize = (ev) => 8 + ev.importance * 3.2;

function buildTimeline() {
  track.innerHTML = '';
  const W = track.clientWidth;
  const totalWeight = ERAS.reduce((s, e) => s + e.weight, 0);
  let x = 0;
  const eraBox = {};
  for (const era of ERAS) {
    const w = (era.weight / totalWeight) * W;
    eraBox[era.id] = { x, w };
    const seg = document.createElement('div');
    seg.className = 'era-seg';
    seg.style.left = `${x}px`;
    seg.style.width = `${w}px`;
    seg.innerHTML = `<span>${era.title}</span>`;
    track.appendChild(seg);
    x += w;
  }

  const pad = 12;
  const xs = EVENTS.map((ev) => {
    const era = ERAS.find((e) => e.id === ev.era);
    const box = eraBox[era.id];
    const v = era.days ? ev.at : ev.am;
    const f = (v - era.from) / (era.to - era.from);
    return box.x + pad + f * (box.w - pad * 2);
  });
  for (let i = 1; i < xs.length; i++) {
    const gap = (markerSize(EVENTS[i]) + markerSize(EVENTS[i - 1])) / 2 + 3;
    if (xs[i] < xs[i - 1] + gap) xs[i] = xs[i - 1] + gap;
  }
  for (let i = xs.length - 2; i >= 0; i--) {
    const gap = (markerSize(EVENTS[i]) + markerSize(EVENTS[i + 1])) / 2 + 3;
    if (xs[i] > xs[i + 1] - gap) xs[i] = xs[i + 1] - gap;
  }

  // Подписи над метками: сначала самые важные, пересекающиеся пропускаем
  const shortLabels = {};
  const taken = [];
  const byImportance = EVENTS.map((ev, i) => i).filter((i) => !EVENTS[i].day && EVENTS[i].importance >= 3)
    .sort((a, b) => EVENTS[b].importance - EVENTS[a].importance);
  for (const i of byImportance) {
    const text = EVENTS[i].short || EVENTS[i].title.split(/[:.]/)[0];
    const half = text.length * 3.6 + 6;
    const l = Math.max(0, xs[i] - half), r = Math.min(W, xs[i] + half);
    if (taken.some(([a, b]) => l < b && r > a)) continue;
    taken.push([l, r]);
    shortLabels[i] = text;
  }

  EVENTS.forEach((ev, i) => {
    const m = document.createElement('button');
    m.className = `mk imp${ev.importance}` + (ev.day ? ' day' : '');
    m.style.left = `${xs[i]}px`;
    m.style.setProperty('--s', `${markerSize(ev)}px`);
    m.title = ev.title;
    m.setAttribute('aria-label', ev.title);
    if (ev.day) m.textContent = ev.day;
    if (shortLabels[i]) m.dataset.short = shortLabels[i];
    m.addEventListener('click', () => { stopPlay(); go(i); });
    track.appendChild(m);
  });
  markActive();
}

function markActive() {
  track.querySelectorAll('.mk').forEach((m, i) => {
    m.classList.toggle('active', i === current);
    m.classList.toggle('past', i < current);
  });
}

// ---------------------------------------------------------------- навигация

let current = -1;
let enteredAt = 0;
let overlays = [];
let playing = false;

function go(i) {
  if (i < 0 || i >= EVENTS.length || i === current) return;
  current = i;
  enteredAt = now();
  const ev = EVENTS[i];
  for (const o of overlays) o.target = 0;
  overlays.push(new Overlay(ev));
  applyEnv(ev);
  flyTo(ev.camera);
  renderCard(ev);
  measureFreeArea();
  markActive();
  history.replaceState(null, '', `#${ev.id}`);
}

// на телефоне текст свёрнут до трёх строк, по нажатию раскрывается
card.addEventListener('click', (e) => {
  if (e.target.tagName !== 'P') return;
  card.classList.toggle('expanded');
  measureFreeArea();
});

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
  if (e.key === 'ArrowRight') { stopPlay(); go(current + 1); }
  if (e.key === 'ArrowLeft') { stopPlay(); go(current - 1); }
  if (e.key === ' ') { e.preventDefault(); playBtn.click(); }
});

window.addEventListener('hashchange', () => {
  const i = EVENTS.findIndex((e) => e.id === location.hash.slice(1));
  if (i >= 0) { stopPlay(); go(i); }
});

window.addEventListener('resize', () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
  for (const m of linesMaterials) m.resolution.set(window.innerWidth, window.innerHeight);
  buildTimeline();
  measureFreeArea();
});

// ---------------------------------------------------------------- цикл

const _camRight = new THREE.Vector3();
const _camUp = new THREE.Vector3();
const _camLight = new THREE.Vector3();
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

  // свет: «из-за плеча зрителя» (сверху слева) либо от солнца
  _camRight.setFromMatrixColumn(camera.matrixWorld, 0);
  _camUp.setFromMatrixColumn(camera.matrixWorld, 1);
  _camLight.copy(camera.position).normalize().addScaledVector(_camUp, 0.55).addScaledVector(_camRight, -0.45).normalize();
  lightDir.copy(_camLight).lerp(SUN_DIR, E('sunLight')).normalize();

  globeUniforms.water.value = E('water');
  globeUniforms.veg.value = E('veg');
  globeUniforms.light.value = E('light');
  globeUniforms.ambient.value = E('ambient');
  globeUniforms.warm.value = E('warm');
  globeUniforms.time.value = t;
  cloudUniforms.amount.value = E('clouds');
  cloudUniforms.dark.value = E('cloudDark');
  cloudUniforms.light.value = E('light');
  cloudUniforms.ambient.value = E('ambient') + 0.05;
  atmoUniforms.amount.value = E('atmo');
  atmoUniforms.light.value = E('light');
  atmoUniforms.warm.value = E('warm');
  clouds.rotation.y = t * 0.004;

  starMat.opacity = E('stars');
  sunMat.opacity = E('sun');
  sun.visible = E('sun') > 0.01;
  moon.material.opacity = E('moon');
  moon.visible = E('moon') > 0.01;
  const ma = 2.2 + t * 0.01;
  moon.position.set(Math.cos(ma) * 3.4, Math.sin(ma) * 0.6, -Math.sin(ma) * 3.4);
  moon.rotation.y = -ma;
  moonLight.position.copy(SUN_DIR);
  birdMat.opacity = E('birds');
  birds.visible = E('birds') > 0.01;
  if (birds.visible) updateBirds(t);

  for (const o of overlays) o.update(dt, t);
  overlays = overlays.filter((o) => {
    if (o.target === 0 && o.fade <= 0) { o.dispose(); return false; }
    return true;
  });
  updateLabels(overlays, t);

  if (playing && t - enteredAt > (EVENTS[current].hold || 10)) {
    if (current < EVENTS.length - 1) go(current + 1);
    else stopPlay();
  }

  renderer.render(scene, camera);
  requestAnimationFrame(frame);
}

// ---------------------------------------------------------------- старт

const loaderEl = document.getElementById('loader');
manager.onProgress = (_url, loaded, total) => {
  loaderEl.querySelector('i').style.width = `${(loaded / total) * 100}%`;
};
manager.onLoad = () => {
  loaderEl.classList.add('done');
  buildTimeline();
  const start = EVENTS.findIndex((e) => e.id === location.hash.slice(1));
  const first = EVENTS[Math.max(0, start)];
  const { pos, target } = cameraPose({ ...first.camera, alt: first.camera.alt + 2 });
  camera.position.copy(pos);
  controls.target.copy(target);
  go(Math.max(0, start));
  requestAnimationFrame(frame);
};
