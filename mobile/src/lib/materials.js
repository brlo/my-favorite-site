// Материалы (страницы сайта): скелет языка, тексты страниц, меню, поиск.
import { reactive } from 'vue'
import { query, queryOne, run, insertMany, deleteIds, kvGet, kvSet, persist } from './db.js'
import { getJSON, online } from './net.js'
import { norm, htmlToParagraphs, stripTags, ftsQuery } from './text.js'
import { NotDownloadedError } from './bible.js'

// rowid абзаца в индексе = id страницы * PARA_MUL + номер абзаца
const PARA_MUL = 100000
const PAGE_TYPE_LIST = 4
const PAGE_TYPE_VERSES = 5

export const skeletonSyncing = reactive({})
const pendingSkeleton = {}

// ---------------------------------------------------------------------------
// СКЕЛЕТ

export async function usedLangs() {
  return kvGet('page_langs', [])
}

async function markLangUsed(lang) {
  const langs = await usedLangs()
  if (!langs.includes(lang)) await kvSet('page_langs', [...langs, lang])
}

export async function hasSkeleton(lang) {
  return (await kvGet(`skel_since:${lang}`, 0)) > 0
}

export function syncSkeleton(lang) {
  if (!pendingSkeleton[lang]) {
    skeletonSyncing[lang] = true
    pendingSkeleton[lang] = doSyncSkeleton(lang).finally(() => {
      delete pendingSkeleton[lang]
      delete skeletonSyncing[lang]
    })
  }
  return pendingSkeleton[lang]
}

async function doSyncSkeleton(lang) {
  const since = await kvGet(`skel_since:${lang}`, 0)
  const data = await getJSON('/api/offline/skeleton', { lang, since })

  await insertMany(
    'pages',
    ['id', 'lang', 'path', 'path_low', 'title', 'title_norm', 'title_sub', 'parent_id', 'page_type',
      'is_show_parent', 'is_search', 'is_bibleox', 'links', 'cover', 'icon', 'audio', 'body_size', 'updated_at'],
    data.pages.map((p) => [
      p.id, lang, p.path, p.path.toLowerCase(), p.title, norm(`${p.title} ${p.title_sub || ''}`), p.title_sub,
      p.parent_id, p.page_type, p.is_show_parent ? 1 : 0, p.is_search ? 1 : 0, p.is_bibleox ? 1 : 0,
      p.links ? JSON.stringify(p.links) : null, p.cover, p.icon, p.audio, p.body_size, p.updated_at,
    ])
  )
  await insertMany(
    'menus',
    ['id', 'lang', 'page_id', 'parent_id', 'title', 'path', 'priority', 'is_gold', 'is_empty'],
    data.menus.map(([id, pageId, parentId, title, path, priority, isGold, isEmpty]) => [
      id, lang, pageId, parentId, title, path, priority ?? 0, isGold ? 1 : 0, isEmpty ? 1 : 0,
    ])
  )

  // Удалённые/снятые с публикации: всё, чего нет в полных списках
  const serverPages = new Set(data.page_ids)
  const localPages = (await query('SELECT id FROM pages WHERE lang = ?', [lang])).map((r) => r.id)
  const gonePages = localPages.filter((id) => !serverPages.has(id))
  if (gonePages.length) {
    await deleteIds('pages', gonePages)
    for (const id of gonePages) await removeBody(id)
  }
  const serverMenus = new Set(data.menu_ids)
  const localMenus = (await query('SELECT id FROM menus WHERE lang = ?', [lang])).map((r) => r.id)
  const goneMenus = localMenus.filter((id) => !serverMenus.has(id))
  if (goneMenus.length) await deleteIds('menus', goneMenus)

  await kvSet(`skel_since:${lang}`, data.next_since)
  await markLangUsed(lang)
  await persist()
}

export async function ensureSkeleton(lang) {
  if (await hasSkeleton(lang)) return
  if (!online.value) throw new NotDownloadedError('skeleton')
  try {
    await syncSkeleton(lang)
  } catch (e) {
    console.warn('skeleton download failed', e)
    throw new NotDownloadedError('skeleton', e)
  }
}

// ---------------------------------------------------------------------------
// СТРАНИЦЫ

function parsePage(row) {
  if (!row) return null
  return { ...row, links: row.links ? JSON.parse(row.links) : null }
}

export async function getPageByPath(lang, path) {
  return parsePage(await queryOne('SELECT * FROM pages WHERE lang = ? AND path_low = ?', [lang, String(path).toLowerCase()]))
}

export async function getPage(id) {
  return parsePage(await queryOne('SELECT * FROM pages WHERE id = ?', [id]))
}

export async function rootPage(lang) {
  return (await getPageByPath(lang, `links_${lang}`))
}

export async function topPages(lang) {
  return query('SELECT id, path, title FROM pages WHERE lang = ? AND parent_id IS NULL ORDER BY title LIMIT 300', [lang])
}

function parseBody(row) {
  if (!row) return null
  return {
    ...row,
    body_menu: row.body_menu ? JSON.parse(row.body_menu) : null,
    verses: row.verses ? JSON.parse(row.verses) : null,
  }
}

export async function getLocalBody(id) {
  return parseBody(await queryOne('SELECT * FROM page_bodies WHERE id = ?', [id]))
}

// Текст страницы: локальный; если его нет или он устарел — с сервера (если есть сеть)
export async function getBody(page) {
  const local = await getLocalBody(page.id)
  const stale = !local || local.updated_at < page.updated_at
  if (stale && online.value) {
    try {
      await downloadBodies(page.lang, [page.id])
      return await getLocalBody(page.id)
    } catch (e) {
      console.warn('page download failed', e)
      if (!local) throw new NotDownloadedError('page', e)
    }
  }
  if (!local) throw new NotDownloadedError('page')
  return local
}

export async function downloadBodies(lang, ids) {
  if (!ids.length) return
  const data = await getJSON('/api/offline/pages', { lang, ids: ids.join(',') })
  for (const b of data.pages) await saveBody(b)
  await persist()
}

async function saveBody(b) {
  await run(
    'INSERT OR REPLACE INTO page_bodies (id, updated_at, body, refs, body_menu, verses, saved_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
    [b.id, b.updated_at, b.body, b.references, b.body_menu ? JSON.stringify(b.body_menu) : null,
      b.verses ? JSON.stringify(b.verses) : null, Date.now()]
  )
  await indexBody(b)
}

async function indexBody(b) {
  await run('DELETE FROM pages_fts WHERE docid >= ? AND docid < ?', [b.id * PARA_MUL, (b.id + 1) * PARA_MUL])
  let paras = htmlToParagraphs(b.body)
  if (b.verses) {
    for (const ch of b.verses) {
      if (ch.title) paras.push(stripTags(ch.title).trim())
      for (const l of ch.lines || []) paras.push(stripTags(l).replace(/\s+/g, ' ').trim())
    }
  }
  if (b.references) paras = paras.concat(htmlToParagraphs(b.references))
  paras = paras.filter((p) => p.length > 1).slice(0, PARA_MUL - 1)
  await insertMany(
    'pages_fts',
    ['docid', 'norm', 'orig'],
    paras.map((p, i) => [b.id * PARA_MUL + i + 1, norm(p), p]),
    { replace: false }
  )
}

export async function removeBody(id) {
  await run('DELETE FROM page_bodies WHERE id = ?', [id])
  await run('DELETE FROM pages_fts WHERE docid >= ? AND docid < ?', [id * PARA_MUL, (id + 1) * PARA_MUL])
}

export async function clearBodies(lang = null) {
  const ids = lang
    ? (await query('SELECT b.id FROM page_bodies b JOIN pages p ON p.id = b.id WHERE p.lang = ?', [lang])).map((r) => r.id)
    : (await query('SELECT id FROM page_bodies')).map((r) => r.id)
  for (const id of ids) await removeBody(id)
  await persist()
}

// Скачанные страницы, которые изменились на сервере
export async function staleBodyIds(lang) {
  const rows = await query(
    'SELECT b.id FROM page_bodies b JOIN pages p ON p.id = b.id WHERE p.lang = ? AND p.updated_at > b.updated_at',
    [lang]
  )
  return rows.map((r) => r.id)
}

export async function bodiesStats() {
  return query(
    `SELECT p.lang AS lang, COUNT(*) AS cnt, SUM(LENGTH(b.body)) AS size
       FROM page_bodies b JOIN pages p ON p.id = b.id GROUP BY p.lang`
  )
}

// Скачивание пачками примерно по 2 МБ
export async function downloadBodiesBatched(lang, pages, onProgress, signal) {
  let batch = []
  let batchSize = 0
  let done = 0
  const flush = async () => {
    if (!batch.length) return
    await downloadBodies(lang, batch.map((p) => p.id))
    done += batch.length
    onProgress?.(done, pages.length)
    batch = []
    batchSize = 0
  }
  for (const p of pages) {
    if (signal?.aborted) return
    batch.push(p)
    batchSize += p.body_size || 0
    if (batch.length >= 50 || batchSize > 2_000_000) await flush()
  }
  if (!signal?.aborted) await flush()
}

// ---------------------------------------------------------------------------
// МЕНЮ

// Дерево меню страницы-списка (сортировка как в TreeBuilder на сервере)
export async function menuTree(pageId) {
  const items = await query('SELECT * FROM menus WHERE page_id = ?', [pageId])
  const byId = new Map(items.map((m) => [m.id, { ...m, childs: [] }]))
  const roots = []
  for (const m of byId.values()) {
    if (m.parent_id) {
      byId.get(m.parent_id)?.childs.push(m)
    } else {
      roots.push(m)
    }
  }
  const sort = (arr) => {
    arr.sort((a, b) => (a.childs.length ? 1 : 0) - (b.childs.length ? 1 : 0) || a.priority - b.priority || a.id - b.id)
    arr.forEach((m) => sort(m.childs))
    return arr
  }
  return sort(roots)
}

// Соседние страницы из меню родителя (блок «Похожие материалы» и стрелки вперёд/назад)
export async function siblings(page) {
  if (!page.parent_id) return null
  const parent = await getPage(page.parent_id)
  if (!parent || parent.page_type !== PAGE_TYPE_LIST) return null
  const menus = await query('SELECT * FROM menus WHERE page_id = ?', [parent.id])
  const me = menus.find((m) => m.path === page.path)
  if (!me || !me.parent_id) return null
  const list = menus
    .filter((m) => m.parent_id === me.parent_id && m.path && !m.is_empty)
    .sort((a, b) => a.priority - b.priority || a.id - b.id)
  const idx = list.findIndex((m) => m.id === me.id)
  return { list, idx }
}

// Цепочка родителей (для хлебных крошек)
export async function ancestors(page) {
  const chain = []
  let cur = page
  const seen = new Set([page.id])
  while (cur?.parent_id && !seen.has(cur.parent_id) && chain.length < 6) {
    seen.add(cur.parent_id)
    cur = await getPage(cur.parent_id)
    if (cur) chain.unshift(cur)
  }
  return chain
}

// Все страницы раздела: идём по меню страницы-списка вглубь (через вложенные списки)
export async function sectionPages(page, maxDepth = 5) {
  const result = new Map()
  const visitedLists = new Set()
  let level = [page]
  for (let depth = 0; depth < maxDepth && level.length; depth++) {
    const next = []
    for (const p of level) {
      if (p.page_type !== PAGE_TYPE_LIST || visitedLists.has(p.id)) continue
      visitedLists.add(p.id)
      const paths = (await query("SELECT DISTINCT path FROM menus WHERE page_id = ? AND path IS NOT NULL AND path <> ''", [p.id]))
        .map((r) => r.path.toLowerCase())
      for (let i = 0; i < paths.length; i += 500) {
        const chunk = paths.slice(i, i + 500)
        const rows = await query(
          `SELECT id, path, page_type, body_size, updated_at FROM pages WHERE lang = ? AND path_low IN (${chunk.map(() => '?').join(',')})`,
          [page.lang, ...chunk]
        )
        for (const r of rows) {
          if (!result.has(r.id)) {
            result.set(r.id, r)
            if (r.page_type === PAGE_TYPE_LIST) next.push(r)
          }
        }
      }
    }
    level = next
  }
  if (!result.has(page.id)) result.set(page.id, page)
  return [...result.values()]
}

export async function missingBodies(pages) {
  if (!pages.length) return []
  const have = new Map()
  for (let i = 0; i < pages.length; i += 500) {
    const chunk = pages.slice(i, i + 500)
    const rows = await query(`SELECT id, updated_at FROM page_bodies WHERE id IN (${chunk.map(() => '?').join(',')})`, chunk.map((p) => p.id))
    rows.forEach((r) => have.set(r.id, r.updated_at))
  }
  return pages.filter((p) => !have.has(p.id) || have.get(p.id) < p.updated_at)
}

// Комментарии к стихам главы: { line: path }
export async function verseComments(lang, book, chapter) {
  const prefix = `${lang}-${book}:${chapter}:`.toLowerCase()
  const rows = await query('SELECT path, path_low FROM pages WHERE lang = ? AND path_low >= ? AND path_low < ?', [lang, prefix, prefix + '￿'])
  const res = {}
  for (const r of rows) {
    const line = parseInt(r.path_low.slice(prefix.length), 10)
    if (line) res[line] = r.path
  }
  return res
}

// ---------------------------------------------------------------------------
// ПОИСК

export async function searchTitles(lang, q, limit = 50) {
  const terms = norm(q).split(' ').filter(Boolean)
  if (!terms.length) return []
  const where = terms.map(() => 'title_norm LIKE ?').join(' AND ')
  return query(
    `SELECT id, path, title, title_sub, parent_id FROM pages WHERE lang = ? AND ${where} ORDER BY LENGTH(title) LIMIT ${limit}`,
    [lang, ...terms.map((t) => `%${t}%`)]
  )
}

// Полнотекстовый поиск по скачанным страницам. Группируем абзацы по страницам.
export async function searchTexts(lang, q, { exact = false, limit = 400 } = {}) {
  const match = ftsQuery(q, { exact })
  if (!match) return []
  const rows = await query(`SELECT docid, orig FROM pages_fts WHERE norm MATCH ? ORDER BY docid LIMIT ${limit}`, [match])
  const byPage = new Map()
  for (const r of rows) {
    const pageId = Math.floor(r.docid / PARA_MUL)
    if (!byPage.has(pageId)) byPage.set(pageId, [])
    byPage.get(pageId).push(r.orig)
  }
  if (!byPage.size) return []
  const ids = [...byPage.keys()]
  const pages = await query(
    `SELECT id, path, title, parent_id FROM pages WHERE lang = ? AND id IN (${ids.map(() => '?').join(',')})`,
    [lang, ...ids]
  )
  return pages.map((p) => ({ ...p, paras: byPage.get(p.id) })).sort((a, b) => b.paras.length - a.paras.length)
}

export { PAGE_TYPE_LIST, PAGE_TYPE_VERSES }
