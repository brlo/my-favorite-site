// Кэш файлов (аудио, картинки) в памяти приложения.
// Файл сохраняется, когда его послушали/посмотрели с интернетом, и дальше доступен оффлайн.
import { reactive } from 'vue'
import { Capacitor } from '@capacitor/core'
import { Filesystem, Directory } from '@capacitor/filesystem'
import { FileTransfer } from '@capacitor/file-transfer'
import { query, queryOne, run, persist } from './db.js'
import { online } from './net.js'

const isNative = Capacitor.isNativePlatform()

// Прогресс скачивания: { [url]: 0..100 }
export const downloads = reactive({})
const pending = {}
let progressListener = null

function hash(s) {
  let h1 = 0xdeadbeef ^ s.length
  let h2 = 0x41c6ce57 ^ s.length
  for (let i = 0; i < s.length; i++) {
    const c = s.charCodeAt(i)
    h1 = Math.imul(h1 ^ c, 2654435761)
    h2 = Math.imul(h2 ^ c, 1597334677)
  }
  h1 = Math.imul(h1 ^ (h1 >>> 16), 2246822507) ^ Math.imul(h2 ^ (h2 >>> 13), 3266489909)
  h2 = Math.imul(h2 ^ (h2 >>> 16), 2246822507) ^ Math.imul(h1 ^ (h1 >>> 13), 3266489909)
  return (h2 >>> 0).toString(16).padStart(8, '0') + (h1 >>> 0).toString(16).padStart(8, '0')
}

function extOf(url) {
  const m = /\.([a-z0-9]{2,5})(?:$|[?#])/i.exec(url)
  return m ? m[1].toLowerCase() : 'bin'
}

let baseUri = null
async function dataUri(path) {
  if (!baseUri) baseUri = (await Filesystem.getUri({ directory: Directory.Data, path: '' })).uri.replace(/\/$/, '')
  return `${baseUri}/${path}`
}

// URL для <audio>/<img>: локальный, если файл скачан
export async function localSrc(url) {
  if (!isNative || !url) return null
  const row = await queryOne('SELECT path FROM files WHERE url = ?', [url])
  if (!row) return null
  return Capacitor.convertFileSrc(await dataUri(row.path))
}

export async function isCached(url) {
  return !!(await queryOne('SELECT url FROM files WHERE url = ?', [url]))
}

async function ensureProgressListener() {
  if (progressListener) return
  progressListener = await FileTransfer.addListener('progress', (p) => {
    if (p.type === 'download' && downloads[p.url] !== undefined && p.lengthComputable && p.contentLength) {
      downloads[p.url] = Math.round((p.bytes / p.contentLength) * 100)
    }
  })
}

// Скачать файл в кэш. Возвращает локальный src или null (если нельзя).
export function cacheFile(url, kind) {
  if (!isNative || !url) return Promise.resolve(null)
  if (!pending[url]) {
    pending[url] = doCache(url, kind).finally(() => {
      delete pending[url]
      delete downloads[url]
    })
  }
  return pending[url]
}

async function doCache(url, kind) {
  const existing = await localSrc(url)
  if (existing) return existing
  if (!online.value) return null
  const path = `${kind}/${hash(url)}.${extOf(url)}`
  const uri = await dataUri(path)
  try {
    await Filesystem.mkdir({ directory: Directory.Data, path: kind, recursive: true })
  } catch {}
  await ensureProgressListener()
  downloads[url] = 0
  const tmpUri = `${uri}.part`
  await FileTransfer.downloadFile({ url, path: tmpUri, progress: true, connectTimeout: 15000, readTimeout: 120000 })
  await Filesystem.rename({ from: tmpUri, to: uri })
  let size = 0
  try { size = (await Filesystem.stat({ path: uri })).size } catch {}
  await run('INSERT OR REPLACE INTO files (url, path, kind, size, created_at) VALUES (?, ?, ?, ?, ?)', [url, path, kind, size, Date.now()])
  await persist()
  return Capacitor.convertFileSrc(uri)
}

export async function filesStats() {
  const rows = await query('SELECT kind, COUNT(*) AS cnt, SUM(size) AS size FROM files GROUP BY kind')
  return Object.fromEntries(rows.map((r) => [r.kind, r]))
}

export async function clearFiles(kind) {
  const rows = await query('SELECT url, path FROM files WHERE kind = ?', [kind])
  for (const r of rows) {
    try { await Filesystem.deleteFile({ directory: Directory.Data, path: r.path }) } catch {}
  }
  await run('DELETE FROM files WHERE kind = ?', [kind])
  await persist()
}
