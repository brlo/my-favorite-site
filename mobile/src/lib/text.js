// Работа с текстом: нормализация для поиска, разбор HTML, подсветка.
// Модуль без зависимостей от DOM, чтобы его можно было тестировать в node.

const KANA = '\\u3040-\\u30ff'
const CJK_CHAR = /[\p{Script=Han}\p{Script=Hiragana}\p{Script=Katakana}]/u
const CJK_ALL = /([\p{Script=Han}\p{Script=Hiragana}\p{Script=Katakana}])/gu
const MARKS_NOT_AFTER_KANA = new RegExp(`([^${KANA}])\\p{M}+`, 'gu')
const FURIGANA = /\[[\p{Script=Hiragana}\p{Script=Katakana}]+\]/gu

const ENTITIES = { amp: '&', lt: '<', gt: '>', quot: '"', apos: "'", nbsp: ' ', shy: '' }

export function decodeEntities(s) {
  return s.replace(/&(#x[0-9a-f]+|#\d+|[a-z]+);/gi, (m, e) => {
    if (e[0] === '#') {
      const code = e[1] === 'x' || e[1] === 'X' ? parseInt(e.slice(2), 16) : parseInt(e.slice(1), 10)
      return Number.isFinite(code) ? String.fromCodePoint(code) : m
    }
    return ENTITIES[e.toLowerCase()] ?? m
  })
}

// HTML → простой текст (ruby-подсказки выкидываем, фуригану в скобках тоже)
export function stripTags(html) {
  return decodeEntities(
    String(html ?? '')
      .replace(/<rt>.*?<\/rt>/gis, '')
      // блочные теги разделяют слова, строчные (<j>, <i>, <a>) — нет
      .replace(/<(br|\/?(p|h[1-6]|li|td|th|tr|div|blockquote|dd|dt|table|ul|ol))\b[^>]*>/gi, ' ')
      .replace(/<[^>]*>/g, '')
  ).replace(FURIGANA, '').replace(/­/g, '')
}

// Нормализация для поискового индекса и запроса — одна функция для обоих.
// Убираем диакритику (ударения, титла, огласовки), регистр и пунктуацию,
// а китайские/японские иероглифы разбиваем на отдельные «слова».
export function norm(text) {
  return String(text ?? '')
    .normalize('NFKD')
    .replace(MARKS_NOT_AFTER_KANA, '$1')
    .replace(/^\p{M}+/u, '')
    .normalize('NFC')
    .toLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, ' ')
    .replace(CJK_ALL, ' $1 ')
    .replace(/\s+/g, ' ')
    .trim()
}

const isCjkToken = (t) => t.length === 1 && CJK_CHAR.test(t)

// Строка запроса для FTS4. Слова — по префиксу (для окончаний), иероглифы — фразой.
export function ftsQuery(q, { exact = false } = {}) {
  const tokens = norm(q).split(' ').filter(Boolean)
  if (!tokens.length) return null
  if (exact) return `"${tokens.join(' ')}"`

  const parts = []
  let cjk = []
  const flush = () => {
    if (cjk.length) parts.push(cjk.length > 1 ? `"${cjk.join(' ')}"` : cjk[0])
    cjk = []
  }
  for (const t of tokens) {
    if (isCjkToken(t)) { cjk.push(t); continue }
    flush()
    parts.push(t.length >= 2 ? `${t}*` : t)
  }
  flush()
  return parts.join(' ')
}

// Термины для подсветки результатов
export function queryTerms(q) {
  const tokens = norm(q).split(' ').filter(Boolean)
  const words = tokens.filter((t) => !isCjkToken(t))
  const cjk = tokens.filter(isCjkToken).join('')
  return { words, cjk }
}

function escapeHtml(s) {
  return s.replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c])
}

// Подсветка в простом тексте. Возвращает безопасный HTML.
export function highlightText(text, terms) {
  const src = String(text ?? '')
  if (terms.cjk) {
    const i = src.indexOf(terms.cjk)
    if (i >= 0) {
      return escapeHtml(src.slice(0, i)) + '<mark>' + escapeHtml(terms.cjk) + '</mark>' + escapeHtml(src.slice(i + terms.cjk.length))
    }
  }
  if (!terms.words.length) return escapeHtml(src)
  let out = ''
  let last = 0
  for (const m of src.matchAll(/[\p{L}\p{N}\p{M}]+/gu)) {
    const w = norm(m[0])
    if (terms.words.some((t) => w.startsWith(t))) {
      out += escapeHtml(src.slice(last, m.index)) + '<mark>' + escapeHtml(m[0]) + '</mark>'
      last = m.index + m[0].length
    }
  }
  return out + escapeHtml(src.slice(last))
}

// Фрагмент длинного абзаца вокруг первого совпадения
export function snippet(text, terms, radius = 120) {
  const src = String(text ?? '')
  if (src.length <= radius * 2) return src
  let pos = -1
  if (terms.cjk) pos = src.indexOf(terms.cjk)
  if (pos < 0 && terms.words.length) {
    for (const m of src.matchAll(/[\p{L}\p{N}\p{M}]+/gu)) {
      const w = norm(m[0])
      if (terms.words.some((t) => w.startsWith(t))) { pos = m.index; break }
    }
  }
  if (pos < 0) pos = 0
  const start = Math.max(0, pos - radius)
  const end = Math.min(src.length, pos + radius)
  return (start > 0 ? '…' : '') + src.slice(start, end) + (end < src.length ? '…' : '')
}

const BLOCK_END = /<\/(p|h[1-6]|li|blockquote|td|th|tr|div|dd|dt|pre|table|ul|ol)>|<br\s*\/?>/gi

// Разбиваем HTML статьи на абзацы для поискового индекса
export function htmlToParagraphs(html) {
  return stripTags(String(html ?? '').replace(BLOCK_END, '\n'))
    .split('\n')
    .map((s) => s.replace(/\s+/g, ' ').trim())
    .filter((s) => s.length > 1)
}

// "私[わたし]" → <ruby><rb>私</rb><rt>わたし</rt></ruby> (как Rubyfy на сервере)
export function rubyfy(html) {
  return String(html ?? '').replace(
    /([\p{Script=Han}]+)\[([\p{Script=Hiragana}\p{Script=Katakana}]+)\]/gu,
    '<ruby><rb>$1</rb><rt>$2</rt></ruby>'
  )
}

export function formatBytes(n) {
  if (!n) return '0'
  if (n < 1024 * 1024) return `${Math.max(1, Math.round(n / 1024))} KB`
  return `${(n / 1024 / 1024).toFixed(n < 10 * 1024 * 1024 ? 1 : 0)} MB`
}
