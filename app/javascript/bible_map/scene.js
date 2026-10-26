// Сцена: Земля с водой и сушей по карте высот, облака, атмосфера, звёзды, солнце, луна, птицы, вспышки
import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { ll, clamp01 } from 'bible_map/geo';

export const SUN_DIR = ll(4, 168).normalize();

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

// Восьмилучевая звезда: длинные лучи по кресту, короткие по диагоналям
function starTexture() {
  const c = document.createElement('canvas');
  c.width = c.height = 256;
  const g = c.getContext('2d');
  g.translate(128, 128);
  g.globalCompositeOperation = 'lighter';
  for (let i = 0; i < 8; i++) {
    const len = i % 2 ? 70 : 124;
    const w = i % 2 ? 4 : 6;
    const grad = g.createLinearGradient(0, 0, 0, -len);
    grad.addColorStop(0, 'rgba(255,255,255,0.95)');
    grad.addColorStop(1, 'rgba(255,255,255,0)');
    g.fillStyle = grad;
    g.beginPath();
    g.moveTo(-w, 0); g.lineTo(0, -len); g.lineTo(w, 0); g.closePath();
    g.fill();
    g.rotate(Math.PI / 4);
  }
  const core = g.createRadialGradient(0, 0, 0, 0, 0, 36);
  core.addColorStop(0, 'rgba(255,255,255,1)');
  core.addColorStop(0.35, 'rgba(255,255,255,0.6)');
  core.addColorStop(1, 'rgba(255,255,255,0)');
  g.fillStyle = core;
  g.beginPath(); g.arc(0, 0, 36, 0, Math.PI * 2); g.fill();
  const t = new THREE.CanvasTexture(c);
  t.colorSpace = THREE.SRGBColorSpace;
  return t;
}

export function createScene(host, urls, onProgress, onLoad) {
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

  const manager = new THREE.LoadingManager(onLoad, (_u, loaded, total) => onProgress(loaded / total));
  const loader = new THREE.TextureLoader(manager);
  const maxAniso = renderer.capabilities.getMaxAnisotropy();
  const texture = (url, color = true) => {
    const t = loader.load(url);
    if (color) t.colorSpace = THREE.SRGBColorSpace;
    t.anisotropy = maxAniso;
    return t;
  };

  const lightDir = new THREE.Vector3(1, 0.3, 0.5).normalize();

  // ---------------------------------------------------------------- Земля
  const globeUniforms = {
    dayMap: { value: texture(urls.earthDay) },
    reliefMap: { value: texture(urls.earthRelief, false) },
    water: { value: 0 }, veg: { value: 1 }, light: { value: 1 }, ambient: { value: 0.15 },
    warm: { value: 0 }, time: { value: 0 }, lightDir: { value: lightDir },
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

  // ---------------------------------------------------------------- облака
  const cloudUniforms = {
    map: { value: texture(urls.clouds, false) }, amount: { value: 0 }, dark: { value: 0 },
    light: { value: 1 }, ambient: { value: 0.1 }, lightDir: { value: lightDir },
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

  // ---------------------------------------------------------------- атмосфера
  const atmoUniforms = { amount: { value: 1 }, lightDir: { value: lightDir }, light: { value: 1 }, warm: { value: 0 } };
  scene.add(new THREE.Mesh(
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
          float rim = pow(clamp(1.0 + dot(vView, vN), 0.0, 1.0), 2.5);
          float sun = smoothstep(-0.35, 0.6, dot(vN, lightDir));
          vec3 col = mix(vec3(0.35, 0.6, 1.0), vec3(1.0, 0.8, 0.5), warm * 0.6);
          gl_FragColor = vec4(col * rim * (0.25 + sun * light) * amount * 1.4, 1.0);
        }`,
    }),
  ));

  // ---------------------------------------------------------------- звёзды
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

  // ---------------------------------------------------------------- солнце и луна
  const sunMat = new THREE.SpriteMaterial({
    map: glowTexture([[0, 'rgba(255,255,250,1)'], [0.12, 'rgba(255,245,215,1)'], [0.22, 'rgba(255,210,140,0.55)'], [0.5, 'rgba(255,170,80,0.12)'], [1, 'rgba(255,150,60,0)']]),
    transparent: true, depthWrite: false, blending: THREE.AdditiveBlending,
  });
  const sun = new THREE.Sprite(sunMat);
  sun.position.copy(SUN_DIR).multiplyScalar(120);
  sun.scale.setScalar(40);
  scene.add(sun);

  const moon = new THREE.Mesh(
    new THREE.SphereGeometry(0.27, 64, 32),
    new THREE.MeshLambertMaterial({ map: texture(urls.moon), transparent: true }),
  );
  scene.add(moon);
  const moonLight = new THREE.DirectionalLight(0xffffff, 2.2);
  scene.add(moonLight);
  scene.add(new THREE.AmbientLight(0xffffff, 0.08));

  // ---------------------------------------------------------------- птицы
  const BIRDS = 900;
  const rnd = (s) => { const x = Math.sin(s * 999.1) * 43758.5; return x - Math.floor(x); };
  const birdData = Array.from({ length: BIRDS }, () => {
    const flock = Math.floor(Math.random() * 14);
    const axis = new THREE.Vector3(rnd(flock + 1) - 0.5, rnd(flock + 2) - 0.5, rnd(flock + 3) - 0.5).normalize()
      .add(new THREE.Vector3().randomDirection().multiplyScalar(0.06)).normalize();
    const base = new THREE.Vector3(Math.abs(axis.x) > 0.9 ? 0 : 1, Math.abs(axis.x) > 0.9 ? 1 : 0, 0).cross(axis).normalize();
    return { axis, base, phase: rnd(flock + 4) * Math.PI * 2 + (Math.random() - 0.5) * 0.12, r: 1.012 + Math.random() * 0.02, speed: 0.06 + rnd(flock + 5) * 0.05 };
  });
  const birdGeo = new THREE.BufferGeometry();
  birdGeo.setAttribute('position', new THREE.BufferAttribute(new Float32Array(BIRDS * 3), 3));
  const birdMat = new THREE.PointsMaterial({ size: 2.2, sizeAttenuation: false, color: 0xfff6e0, transparent: true, depthWrite: false });
  const birds = new THREE.Points(birdGeo, birdMat);
  scene.add(birds);
  const _q = new THREE.Quaternion();
  const _b = new THREE.Vector3();
  function updateBirds(t) {
    const pos = birdGeo.attributes.position.array;
    for (let i = 0; i < BIRDS; i++) {
      const b = birdData[i];
      _q.setFromAxisAngle(b.axis, b.phase + t * b.speed);
      _b.copy(b.base).applyQuaternion(_q).multiplyScalar(b.r);
      pos[i * 3] = _b.x; pos[i * 3 + 1] = _b.y; pos[i * 3 + 2] = _b.z;
    }
    birdGeo.attributes.position.needsUpdate = true;
  }

  // ---------------------------------------------------------------- вспышки
  // soft — тихое долгое сияние, sharp — короткая яркая вспышка (Распятие, Воскресение),
  // nativity — Вифлеемская звезда: медленно опускается и долго стоит над местом, вокруг — тихий свет
  const flashSprite = new THREE.Sprite(new THREE.SpriteMaterial({
    map: glowTexture([[0, 'rgba(255,255,255,1)'], [0.25, 'rgba(255,255,255,0.45)'], [0.6, 'rgba(255,255,255,0.08)'], [1, 'rgba(255,255,255,0)']]),
    transparent: true, depthWrite: false, depthTest: false, blending: THREE.AdditiveBlending, opacity: 0,
  }));
  flashSprite.visible = false;
  scene.add(flashSprite);
  const starSprite = new THREE.Sprite(new THREE.SpriteMaterial({
    map: starTexture(), transparent: true, depthWrite: false, depthTest: false, blending: THREE.AdditiveBlending, opacity: 0,
  }));
  starSprite.visible = false;
  scene.add(starSprite);
  const flashEl = document.getElementById('flash');
  let flashState = null;

  const TIMING = { sharp: [0.18, 0.3, 2.2], soft: [2.2, 3.5, 4.5], nativity: [4, 12, 6] };

  function flash({ lat, lon, color = '#fff6d8', kind = 'soft', delay = 1.6 }) {
    flashState = { pos: ll(lat, lon, 1.004), color, kind, t0: performance.now() / 1000 + delay };
    flashSprite.material.color.set(color);
    starSprite.material.color.set(color);
    flashEl.style.setProperty('--c', color);
  }

  const _p = new THREE.Vector3();
  function updateFlash(t) {
    if (!flashState) return;
    const { kind, t0 } = flashState;
    const age = t - t0;
    const [rise, hold, fall] = TIMING[kind];
    let k = 0;
    if (age > 0) k = age < rise ? age / rise : age < rise + hold ? 1 : 1 - (age - rise - hold) / fall;
    k = clamp01(k);
    // тихое сияние ещё и «дышит»
    if (kind !== 'sharp') k *= 0.85 + 0.15 * Math.sin(age * 1.6);
    const dist = camera.position.distanceTo(flashState.pos);

    flashSprite.visible = k > 0.001;
    flashSprite.position.copy(flashState.pos);
    flashSprite.scale.setScalar(dist * (kind === 'sharp' ? 0.9 + (1 - k) * 0.6 : kind === 'nativity' ? 0.4 : 0.55));
    flashSprite.material.opacity = k * (kind === 'sharp' ? 1 : kind === 'nativity' ? 0.55 : 0.8);

    if (kind === 'nativity') {
      // звезда спускается с высоты и останавливается над местом
      const descent = clamp01(age / (rise + 2));
      const h = 0.06 * (1 - descent * descent * (3 - 2 * descent)) + 0.008;
      starSprite.visible = k > 0.001;
      starSprite.position.copy(flashState.pos).normalize().multiplyScalar(1.004 + h);
      starSprite.scale.setScalar(dist * 0.17 * (0.9 + 0.1 * Math.sin(age * 2.3)));
      starSprite.material.rotation = age * 0.05;
      starSprite.material.opacity = Math.min(1, k * 1.2);
    } else {
      starSprite.visible = false;
    }

    _p.copy(flashState.pos).project(camera);
    flashEl.style.setProperty('--x', `${((_p.x + 1) / 2) * 100}%`);
    flashEl.style.setProperty('--y', `${((1 - _p.y) / 2) * 100}%`);
    flashEl.style.opacity = k * (kind === 'sharp' ? 0.85 : kind === 'nativity' ? 0.35 : 0.45);
    if (age > rise + hold + fall) { flashState = null; flashEl.style.opacity = 0; flashSprite.visible = false; starSprite.visible = false; }
  }

  // ---------------------------------------------------------------- кадр
  const _r = new THREE.Vector3(), _u = new THREE.Vector3(), _l = new THREE.Vector3();

  function update(t, E) {
    // свет: «из-за плеча зрителя» (сверху слева) либо от солнца
    _r.setFromMatrixColumn(camera.matrixWorld, 0);
    _u.setFromMatrixColumn(camera.matrixWorld, 1);
    _l.copy(camera.position).normalize().addScaledVector(_u, 0.55).addScaledVector(_r, -0.45).normalize();
    lightDir.copy(_l).lerp(SUN_DIR, E('sunLight')).normalize();

    // первозданный свет «то разливался, то сжимался» (свт. Василий Великий)
    const pulse = E('pulse');
    const light = E('light') * (1 - pulse * (0.5 - 0.5 * Math.cos(t * 0.9)) * 0.75);

    globeUniforms.water.value = E('water');
    globeUniforms.veg.value = E('veg');
    globeUniforms.light.value = light;
    globeUniforms.ambient.value = E('ambient');
    globeUniforms.warm.value = E('warm');
    globeUniforms.time.value = t;
    cloudUniforms.amount.value = E('clouds');
    cloudUniforms.dark.value = E('cloudDark');
    cloudUniforms.light.value = light;
    cloudUniforms.ambient.value = E('ambient') + 0.05;
    atmoUniforms.amount.value = E('atmo');
    atmoUniforms.light.value = light;
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
    updateFlash(t);
  }

  function resize() {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
  }

  return { renderer, scene, camera, controls, update, flash, resize, globe };
}
