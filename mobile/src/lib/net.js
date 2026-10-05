import { ref } from 'vue'
import { Capacitor, CapacitorHttp } from '@capacitor/core'
import { Network } from '@capacitor/network'
import { API_BASE } from './config.js'

export const online = ref(true)
const listeners = new Set()

export function onReconnect(fn) {
  listeners.add(fn)
  return () => listeners.delete(fn)
}

export async function initNetwork() {
  try {
    const st = await Network.getStatus()
    online.value = st.connected
  } catch {
    online.value = navigator.onLine
  }
  Network.addListener('networkStatusChange', (st) => {
    const was = online.value
    online.value = st.connected
    if (!was && st.connected) listeners.forEach((fn) => fn())
  })
}

export class OfflineError extends Error {
  constructor() { super('offline'); this.offline = true }
}

const isNative = Capacitor.isNativePlatform()

function buildUrl(path, params) {
  const qs = params ? '?' + new URLSearchParams(params).toString() : ''
  return `${API_BASE}${path}${qs}`
}

export async function getJSON(path, params) {
  if (!online.value) throw new OfflineError()
  if (isNative) {
    // Нативный запрос: не нужен CORS
    const r = await CapacitorHttp.get({
      url: `${API_BASE}${path}`,
      params: params ? Object.fromEntries(Object.entries(params).map(([k, v]) => [k, String(v)])) : undefined,
      connectTimeout: 15000,
      readTimeout: 120000,
    })
    if (r.status !== 200) throw new Error(`HTTP ${r.status}`)
    return typeof r.data === 'string' ? JSON.parse(r.data) : r.data
  }
  const r = await fetch(buildUrl(path, params))
  if (!r.ok) throw new Error(`HTTP ${r.status}`)
  return r.json()
}

function base64ToBytes(b64) {
  const bin = atob(b64)
  const out = new Uint8Array(bin.length)
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i)
  return out
}

// Скачать .json.gz и распаковать
export async function getGzipJSON(path) {
  if (!online.value) throw new OfflineError()
  let bytes
  if (isNative) {
    const r = await CapacitorHttp.get({
      url: `${API_BASE}${path}`,
      responseType: 'arraybuffer',
      connectTimeout: 15000,
      readTimeout: 300000,
    })
    if (r.status !== 200) throw new Error(`HTTP ${r.status}`)
    bytes = typeof r.data === 'string' ? base64ToBytes(r.data) : new Uint8Array(r.data)
  } else {
    const r = await fetch(buildUrl(path))
    if (!r.ok) throw new Error(`HTTP ${r.status}`)
    bytes = new Uint8Array(await r.arrayBuffer())
  }
  // если по дороге уже распаковали (Content-Encoding) — это сразу JSON
  if (bytes[0] !== 0x1f || bytes[1] !== 0x8b) return JSON.parse(new TextDecoder().decode(bytes))
  const stream = new Blob([bytes]).stream().pipeThrough(new DecompressionStream('gzip'))
  return new Response(stream).json()
}
