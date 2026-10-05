// Манифест сервера: список книг, переводов, аудио. Хранится локально, обновляется при синхронизации.
import { ref, computed } from 'vue'
import { kvGet, kvSet } from './db.js'
import { getJSON } from './net.js'
import { API_BASE } from './config.js'
import { uiLang } from './i18n.js'
import FALLBACK_BOOKS from './books.json'

export const manifest = ref(null)

export async function loadManifest() {
  manifest.value = await kvGet('manifest', null)
}

export async function fetchManifest() {
  const data = await getJSON('/api/offline/manifest', { locale: uiLang.value })
  manifest.value = data
  await kvSet('manifest', data)
  return data
}

export const books = computed(() => manifest.value?.books || FALLBACK_BOOKS)
export const booksByCode = computed(() => Object.fromEntries(books.value.map((b) => [b.code, b])))

let indexCache = null
let indexFor = null
export function bookIndex(code) {
  if (indexFor !== books.value) {
    indexCache = Object.fromEntries(books.value.map((b, i) => [b.code, i + 1]))
    indexFor = books.value
  }
  return indexCache[code] || 999
}

export const bibleList = computed(() => manifest.value?.bible || [])
export const bibleInfo = (tr) => bibleList.value.find((b) => b.tr_code === tr)

export function hasAudio(tr, book, chapter) {
  return !!bibleInfo(tr)?.audio?.[book]?.includes(Number(chapter))
}

// Абсолютный адрес файла на сервере ресурсов
export function resUrl(path) {
  if (!path) return null
  if (/^https?:\/\//.test(path)) return path
  const base = manifest.value?.res_base || API_BASE
  return `${base}${path.startsWith('/') ? '' : '/'}${path}`
}

export function bibleAudioUrl(tr, book, chapter) {
  return resUrl(`/s/audio/bib/${tr}/${book}/${book}${chapter}.mp3`)
}
