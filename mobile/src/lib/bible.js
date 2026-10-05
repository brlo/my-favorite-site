// Переводы Библии: скачивание пакета, чтение глав, поиск.
import { reactive } from 'vue'
import { query, queryOne, run, exec, insertMany, persist } from './db.js'
import { getGzipJSON, online } from './net.js'
import { norm, stripTags, ftsQuery } from './text.js'
import { manifest, bookIndex } from './manifest.js'

// Состояние установки переводов: { [tr]: {stage, progress} }
export const installing = reactive({})
const pending = {}

const ftsTable = (tr) => `bfts_${tr.replace(/[^a-z0-9]/gi, '_')}`

// id стиха: порядок книги, глава, стих — для сортировки и связи с поисковым индексом
const verseId = (book, chapter, line) => bookIndex(book) * 1_000_000 + chapter * 1000 + line

export async function installedBibles() {
  const rows = await query('SELECT tr, version, installed_at FROM bibles')
  return Object.fromEntries(rows.map((r) => [r.tr, r]))
}

export async function isInstalled(tr) {
  return !!(await queryOne('SELECT tr FROM bibles WHERE tr = ?', [tr]))
}

export class NotDownloadedError extends Error {
  constructor(kind) { super(`not downloaded: ${kind}`); this.notDownloaded = kind }
}

// Скачать (или обновить) перевод целиком. Повторные вызовы ждут уже идущую загрузку.
export function installBible(tr) {
  if (!pending[tr]) {
    pending[tr] = doInstall(tr).finally(() => {
      delete pending[tr]
      delete installing[tr]
    })
  }
  return pending[tr]
}

async function doInstall(tr) {
  installing[tr] = { stage: 'downloading', progress: 0 }
  const data = await getGzipJSON(`/api/offline/bible/${encodeURIComponent(tr)}`)

  installing[tr] = { stage: 'indexing', progress: 0 }
  const table = ftsTable(tr)
  await run('DELETE FROM verses WHERE tr = ?', [tr])
  await exec(`DROP TABLE IF EXISTS ${table}; CREATE VIRTUAL TABLE ${table} USING fts4(norm);`)

  const verses = data.verses
  const step = 5000
  for (let i = 0; i < verses.length; i += step) {
    const chunk = verses.slice(i, i + step)
    const rows = []
    const ftsRows = []
    for (const [book, chapter, line, text] of chunk) {
      const id = verseId(book, chapter, line)
      rows.push([tr, id, book, chapter, line, text])
      ftsRows.push([id, norm(stripTags(text))])
    }
    await insertMany('verses', ['tr', 'id', 'book', 'chapter', 'line', 'text'], rows)
    await insertMany(table, ['docid', 'norm'], ftsRows, { replace: false })
    installing[tr] = { stage: 'indexing', progress: Math.round(((i + chunk.length) / verses.length) * 100) }
  }

  await run('INSERT OR REPLACE INTO bibles (tr, version, installed_at) VALUES (?, ?, ?)', [tr, data.version, Date.now()])
  await persist()
}

export async function deleteBible(tr) {
  await run('DELETE FROM verses WHERE tr = ?', [tr])
  await exec(`DROP TABLE IF EXISTS ${ftsTable(tr)};`)
  await run('DELETE FROM bibles WHERE tr = ?', [tr])
  await persist()
}

// Перевод нужен прямо сейчас: если не скачан — качаем (при наличии сети)
export async function ensureBible(tr) {
  if (await isInstalled(tr)) return
  if (!online.value) throw new NotDownloadedError('bible')
  try {
    await installBible(tr)
  } catch (e) {
    console.warn('bible download failed', e)
    throw new NotDownloadedError('bible')
  }
}

export async function getChapter(tr, book, chapter) {
  await ensureBible(tr)
  return query('SELECT line, text FROM verses WHERE tr = ? AND book = ? AND chapter = ? ORDER BY line', [tr, book, chapter])
}

// Переводы, у которых на сервере новая версия
export async function outdatedBibles() {
  const installed = await installedBibles()
  return (manifest.value?.bible || [])
    .filter((b) => installed[b.tr_code] && b.version && installed[b.tr_code].version !== b.version)
    .map((b) => b.tr_code)
}

export async function searchBible(tr, q, { exact = false, books = null, limit = 500 } = {}) {
  if (!(await isInstalled(tr))) throw new NotDownloadedError('bible')
  const match = ftsQuery(q, { exact })
  if (!match) return { total: 0, verses: [] }
  const table = ftsTable(tr)
  let where = ''
  const values = [match, tr]
  if (books?.length) {
    where = ` AND v.book IN (${books.map(() => '?').join(',')})`
    values.push(...books)
  }
  const rows = await query(
    `SELECT v.book, v.chapter, v.line, v.text FROM ${table} f
       JOIN verses v ON v.id = f.docid
      WHERE f.norm MATCH ? AND v.tr = ?${where}
      ORDER BY v.id LIMIT ${limit + 1}`,
    values
  )
  return { total: rows.length, more: rows.length > limit, verses: rows.slice(0, limit) }
}
