// Геометрия на сфере и общие мелочи для всех модулей глобуса
import * as THREE from 'three';

export const DEG = Math.PI / 180;

// Широта/долгота → точка на сфере (совпадает с UV-развёрткой SphereGeometry)
export function ll(lat, lon, r = 1) {
  const phi = (90 - lat) * DEG;
  const l = lon * DEG;
  return new THREE.Vector3(Math.sin(phi) * Math.cos(l) * r, Math.cos(phi) * r, -Math.sin(phi) * Math.sin(l) * r);
}

export const clamp01 = (x) => Math.min(1, Math.max(0, x));
export const easeInOut = (t) => (t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2);
export const smooth = (a, b, x) => { const t = clamp01((x - a) / (b - a)); return t * t * (3 - 2 * t); };
export const now = () => performance.now() / 1000;

// Круглая область вокруг точки (радиус в градусах широты)
export function circle(lat, lon, r, n = 48) {
  const out = [];
  const k = 1 / Math.cos(lat * DEG);
  for (let i = 0; i < n; i++) {
    const a = (i / n) * Math.PI * 2;
    out.push([lat + Math.sin(a) * r, lon + Math.cos(a) * r * k]);
  }
  return out;
}

// Замкнутый контур с точками не реже stepDeg — чтобы рёбра не срезали сферу
export function densify(latlons, stepDeg = 0.25) {
  const out = [];
  for (let i = 0; i < latlons.length; i++) {
    const a = latlons[i], b = latlons[(i + 1) % latlons.length];
    const n = Math.max(1, Math.ceil(Math.hypot(b[0] - a[0], b[1] - a[1]) / stepDeg));
    for (let j = 0; j < n; j++) out.push([a[0] + (b[0] - a[0]) * j / n, a[1] + (b[1] - a[1]) * j / n]);
  }
  return out;
}

// Гладкая кривая по опорным точкам, прижатая к поверхности
export function curve(latlons, alt) {
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
