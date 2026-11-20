// Отметка посещения и heartbeat «читает сейчас». Токен приходит вместе
// с текстом страницы; для уже скачанных страниц добираем его отдельным запросом.
import { getJSON, postJSON, online } from './net.js'
import { queryOne, run, persist } from './db.js'
import { uiLang } from './i18n.js'
import { booksByCode } from './manifest.js'

const recentVisits = new Map()
const pendingTokens = new Map()
const VISIT_DEDUP_MS = 5 * 60 * 1000

export function getVisitToken(pageId) {
  if (!pendingTokens.has(pageId)) {
    pendingTokens.set(pageId, loadVisitToken(pageId).finally(() => pendingTokens.delete(pageId)))
  }
  return pendingTokens.get(pageId)
}

async function loadVisitToken(pageId) {
  const row = await queryOne('SELECT token FROM page_tokens WHERE page_id = ?', [pageId])
  if (row?.token) return row.token
  if (!online.value) return null
  try {
    const data = await getJSON('/api/offline/tokens', { ids: String(pageId) })
    const token = data?.tokens?.[String(pageId)] || null
    if (token) {
      await run('INSERT OR REPLACE INTO page_tokens (page_id, token) VALUES (?, ?)', [pageId, token])
      await persist()
    }
    return token
  } catch {
    return null
  }
}

// Отдельный запрос на показ страницы. Статистика не должна ломать чтение,
// поэтому все ошибки здесь проглатываем.
export async function markVisit(page) {
  if (!online.value || !page?.id) return
  const last = recentVisits.get(page.id)
  if (last && Date.now() - last < VISIT_DEDUP_MS) return
  recentVisits.set(page.id, Date.now())

  try {
    const token = await getVisitToken(page.id)
    if (!token) return
    await postJSON('/api/offline/visit', { page_id: page.id, lang: uiLang.value, t: token })
  } catch {}
}

export async function sendReading(page, { leave = false } = {}) {
  if (!online.value || !page?.id) return
  try {
    const token = await getVisitToken(page.id)
    if (!token) return
    const payload = { page_id: page.id, t: token }
    if (leave) payload.leave = 1
    await postJSON('/api/offline/reading', payload)
  } catch {}
}

// Глава Библии: в «Читают сейчас» показывается только книга, глава не нужна
export async function sendBibleReading(book, { leave = false } = {}) {
  if (!online.value || !book) return
  const token = booksByCode.value[book]?.reading_token
  if (!token) return
  const payload = { book, t: token }
  if (leave) payload.leave = 1
  try {
    await postJSON('/api/offline/reading', payload)
  } catch {}
}
