// Адрес сайта. В разработке пусто — запросы идут через прокси vite.
export const API_BASE = import.meta.env?.VITE_API_BASE ?? 'https://bibleox.com'

// Хосты, ссылки на которые открываем внутри приложения
export const SITE_HOSTS = ['bibleox.com', 'www.bibleox.com', 'localhost']
try {
  if (API_BASE) SITE_HOSTS.push(new URL(API_BASE).hostname)
} catch {}

// Как часто синхронизироваться в фоне (мс)
export const SYNC_INTERVAL = 10 * 60 * 1000

// Какой перевод Библии открывать для языка интерфейса/материалов (как LOCALE_TO_BIB_LANG на сервере)
const LOCALE_TO_BIB = {
  ru: 'ru', sr: 'ru', tk: 'ru', uz: 'ru', uk: 'ru', be: 'ru', kk: 'ru',
  en: 'eng-nkjv', he: 'heb-osm', el: 'gr-lxx-byz', grc: 'gr-lxx-byz',
  ja: 'jp-ni', 'zh-Hans': 'cn-ccbs', 'zh-Hant': 'cn-ccbs', de: 'ge-sch', ar: 'arab-avd',
}
export const bibForLocale = (loc) => LOCALE_TO_BIB[loc] || 'eng-nkjv'

// Язык статей-комментариев к стихам для перевода (как BIB_LANG_TO_LOCALE на сервере)
const BIB_TO_LOCALE = {
  ru: 'ru', 'csl-ru': 'ru', 'csl-pnm': 'ru', 'en-nrsv': 'en', 'eng-nkjv': 'en',
  'heb-osm': 'he', 'gr-lxx-byz': 'el', 'jp-ni': 'ja', 'cn-ccbs': 'zh-Hans',
  'ge-sch': 'de', 'arab-avd': 'ar',
}
export const localeForBib = (tr) => BIB_TO_LOCALE[tr] || 'en'

// Подстрочники оффлайн недоступны — открываем основной перевод
export const INTERLINEAR_FALLBACK = { 'gr-ru': 'ru', 'gr-en': 'eng-nkjv', 'gr-jp': 'jp-ni' }

export const RTL_BIBS = ['heb-osm', 'arab-avd']
export const RTL_LANGS = ['he', 'ar', 'fa']

// CSS-класс шрифта для перевода (как font_classes на сервере)
export function bibFontClass(tr) {
  if (tr === 'csl-pnm') return 'csl'
  if (['jp-ni', 'arab-avd', 'cn-ccbs', 'heb-osm'].includes(tr)) return 'text-detailed'
  return ''
}
