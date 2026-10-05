// Разбор ссылок сайта, чтобы открывать их внутри приложения.
import { SITE_HOSTS, bibForLocale, INTERLINEAR_FALLBACK } from './config.js'

const isNum = (s) => /^\d+$/.test(s || '')

// books — словарь кодов книг ({gen: {...}})
export function parseHref(href, books) {
  if (!href) return null
  if (href.startsWith('#')) return { type: 'anchor', id: decodeURIComponent(href.slice(1)) }

  let url
  try {
    url = new URL(href, 'https://bibleox.com/')
  } catch {
    return null
  }
  if (!/^https?:$/.test(url.protocol)) return { type: 'external', url: href }
  if (!SITE_HOSTS.includes(url.hostname)) return { type: 'external', url: url.href }

  const segs = url.pathname.split('/').filter(Boolean).map((s) => {
    try { return decodeURIComponent(s) } catch { return s }
  })
  const verse = /^#L(\d+)/.exec(url.hash)?.[1]
  const v = verse ? Number(verse) : null

  // /:locale/:content_lang/w/:path
  if (segs[2] === 'w' && segs[3]) return { type: 'page', lang: segs[1], path: segs[3], hash: url.hash.slice(1) || null }

  // /:locale/:bib_lang/:book/:chapter
  if (books[segs[2]] && isNum(segs[3])) {
    const tr = INTERLINEAR_FALLBACK[segs[1]] || segs[1]
    return { type: 'bible', tr, book: segs[2], chapter: Number(segs[3]), verse: v }
  }

  // старый формат: /:locale/:book/:chapter
  if (books[segs[1]] && isNum(segs[2])) {
    return { type: 'bible', tr: bibForLocale(segs[0]), book: segs[1], chapter: Number(segs[2]), verse: v }
  }

  // /:book/:chapter
  if (books[segs[0]] && isNum(segs[1])) {
    return { type: 'bible', tr: null, book: segs[0], chapter: Number(segs[1]), verse: v }
  }

  return { type: 'external', url: url.href }
}
