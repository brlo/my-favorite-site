// Новостная лента: сервер собирает карточки, приложение кэширует последний
// ответ, чтобы при отсутствии сети показать хотя бы его.
import { getJSON } from './net.js'
import { kvGet, kvSet } from './db.js'

const key = (lang) => `feed:${lang}`

export async function loadFeedCache(lang) {
  return kvGet(key(lang), null)
}

export async function saveFeedCache(lang, data) {
  await kvSet(key(lang), { ...data, cached_at: Date.now() })
}

export async function fetchFeed(lang, page = 1) {
  return getJSON('/api/offline/feed', { lang, page })
}

export async function fetchReadingNow(lang) {
  return getJSON('/api/offline/reading_now', { lang })
}
