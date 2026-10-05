// Локальная база SQLite. На Android — нативный плагин, в браузере (для разработки) — sql.js.
import { Capacitor } from '@capacitor/core'
import { CapacitorSQLite, SQLiteConnection } from '@capacitor-community/sqlite'

const DB_NAME = 'bibleox'
const SCHEMA_VERSION = 1
const isWeb = Capacitor.getPlatform() === 'web'
const sqlite = new SQLiteConnection(CapacitorSQLite)

let conn = null

// Поисковые индексы — FTS4: он есть и в SQLCipher (Android), и в sql.js.
const SCHEMA = `
CREATE TABLE IF NOT EXISTS kv (key TEXT PRIMARY KEY NOT NULL, value TEXT);

CREATE TABLE IF NOT EXISTS bibles (
  tr TEXT PRIMARY KEY NOT NULL,
  version TEXT,
  installed_at INTEGER
);

CREATE TABLE IF NOT EXISTS verses (
  tr TEXT NOT NULL,
  id INTEGER NOT NULL,
  book TEXT NOT NULL,
  chapter INTEGER NOT NULL,
  line INTEGER NOT NULL,
  text TEXT,
  PRIMARY KEY (tr, id)
);
CREATE INDEX IF NOT EXISTS verses_chapter ON verses (tr, book, chapter);

CREATE TABLE IF NOT EXISTS pages (
  id INTEGER PRIMARY KEY NOT NULL,
  lang TEXT NOT NULL,
  path TEXT NOT NULL,
  path_low TEXT NOT NULL,
  title TEXT,
  title_norm TEXT,
  title_sub TEXT,
  parent_id INTEGER,
  page_type INTEGER,
  is_show_parent INTEGER,
  is_search INTEGER,
  is_bibleox INTEGER,
  links TEXT,
  cover TEXT,
  icon TEXT,
  audio TEXT,
  body_size INTEGER,
  updated_at INTEGER
);
CREATE INDEX IF NOT EXISTS pages_path ON pages (lang, path_low);
CREATE INDEX IF NOT EXISTS pages_parent ON pages (parent_id);

CREATE TABLE IF NOT EXISTS page_bodies (
  id INTEGER PRIMARY KEY NOT NULL,
  updated_at INTEGER,
  body TEXT,
  refs TEXT,
  body_menu TEXT,
  verses TEXT,
  saved_at INTEGER
);

CREATE TABLE IF NOT EXISTS menus (
  id INTEGER PRIMARY KEY NOT NULL,
  lang TEXT NOT NULL,
  page_id INTEGER NOT NULL,
  parent_id INTEGER,
  title TEXT,
  path TEXT,
  priority INTEGER,
  is_gold INTEGER,
  is_empty INTEGER
);
CREATE INDEX IF NOT EXISTS menus_page ON menus (page_id);

CREATE TABLE IF NOT EXISTS files (
  url TEXT PRIMARY KEY NOT NULL,
  path TEXT NOT NULL,
  kind TEXT NOT NULL,
  size INTEGER,
  created_at INTEGER
);

CREATE VIRTUAL TABLE IF NOT EXISTS pages_fts USING fts4(norm, orig, notindexed=orig);
`

async function initWeb() {
  const { defineCustomElements } = await import('jeep-sqlite/loader')
  defineCustomElements(window)
  const el = document.createElement('jeep-sqlite')
  el.setAttribute('wasmpath', 'assets')
  el.setAttribute('autosave', 'true')
  document.body.appendChild(el)
  await customElements.whenDefined('jeep-sqlite')
  await sqlite.initWebStore()
}

export async function initDb() {
  if (conn) return conn
  if (isWeb) await initWeb()
  const consistent = (await sqlite.checkConnectionsConsistency()).result
  const exists = (await sqlite.isConnection(DB_NAME, false)).result
  conn = consistent && exists
    ? await sqlite.retrieveConnection(DB_NAME, false)
    : await sqlite.createConnection(DB_NAME, false, 'no-encryption', SCHEMA_VERSION, false)
  await conn.open()
  await conn.execute(SCHEMA, true)
  await persist()
  return conn
}

// В браузере база живёт в памяти — сохраняем в IndexedDB после записи
export async function persist() {
  if (isWeb && conn) await sqlite.saveToStore(DB_NAME)
}

export async function query(sql, values = []) {
  const res = await conn.query(sql, values)
  return res.values || []
}

export async function queryOne(sql, values = []) {
  return (await query(sql, values))[0] || null
}

export async function run(sql, values = []) {
  return conn.run(sql, values, false)
}

export async function exec(sql) {
  return conn.execute(sql, false)
}

// Пакет команд одной транзакцией: [{statement, values}]
export async function runSet(set) {
  if (!set.length) return
  await conn.executeSet(set, true)
}

// Массовая вставка многострочными INSERT (лимит переменных SQLite — 999)
export async function insertMany(table, columns, rows, { replace = true, chunkVars = 900 } = {}) {
  if (!rows.length) return
  const perRow = columns.length
  const rowsPerStmt = Math.max(1, Math.floor(chunkVars / perRow))
  const verb = replace ? 'INSERT OR REPLACE' : 'INSERT'
  const set = []
  for (let i = 0; i < rows.length; i += rowsPerStmt) {
    const chunk = rows.slice(i, i + rowsPerStmt)
    const ph = chunk.map(() => `(${columns.map(() => '?').join(',')})`).join(',')
    set.push({ statement: `${verb} INTO ${table} (${columns.join(',')}) VALUES ${ph}`, values: chunk.flat() })
  }
  // большими транзакциями, но не одной гигантской
  for (let i = 0; i < set.length; i += 50) await runSet(set.slice(i, i + 50))
}

export async function deleteIds(table, ids, column = 'id') {
  for (let i = 0; i < ids.length; i += 500) {
    const chunk = ids.slice(i, i + 500)
    await run(`DELETE FROM ${table} WHERE ${column} IN (${chunk.map(() => '?').join(',')})`, chunk)
  }
}

export async function kvGet(key, def = null) {
  const row = await queryOne('SELECT value FROM kv WHERE key = ?', [key])
  if (!row) return def
  try { return JSON.parse(row.value) } catch { return def }
}

export async function kvSet(key, value) {
  await run('INSERT OR REPLACE INTO kv (key, value) VALUES (?, ?)', [key, JSON.stringify(value)])
}
