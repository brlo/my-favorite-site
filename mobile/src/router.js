import { createRouter, createWebHashHistory } from 'vue-router'
import { Browser } from '@capacitor/browser'
import { settings } from './lib/settings.js'
import { parseHref } from './lib/links.js'
import { booksByCode } from './lib/manifest.js'
import { API_BASE } from './lib/config.js'

import BibleHome from './views/BibleHome.vue'
import BibleChapter from './views/BibleChapter.vue'
import PageView from './views/PageView.vue'
import SearchView from './views/SearchView.vue'
import SettingsView from './views/SettingsView.vue'

const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    { path: '/', redirect: () => '/bible' },
    { path: '/bible/:tr?', name: 'bible', component: BibleHome },
    { path: '/bible/:tr/:book/:chapter', name: 'chapter', component: BibleChapter },
    { path: '/w', redirect: () => `/w/${settings.pagesLang}` },
    { path: '/w/:lang/:path?', name: 'page', component: PageView },
    { path: '/search', name: 'search', component: SearchView },
    { path: '/settings', name: 'settings', component: SettingsView },
  ],
  scrollBehavior(to, from, saved) {
    if (saved) return saved
    return { top: 0 }
  },
})

export default router

export function chapterRoute(tr, book, chapter, verse = null) {
  return { name: 'chapter', params: { tr, book, chapter: String(chapter) }, query: verse ? { v: String(verse) } : {} }
}

export function pageRoute(lang, path, hash = null) {
  return { name: 'page', params: { lang, path }, hash: hash ? `#${hash}` : '' }
}

export async function openExternal(url) {
  try {
    await Browser.open({ url })
  } catch {
    window.open(url, '_blank')
  }
}

// Клик по ссылке внутри текста. Возвращает true, если обработали сами.
export function openHref(href, { lang = settings.pagesLang, onAnchor } = {}) {
  const link = parseHref(href, booksByCode.value)
  if (!link) return false
  switch (link.type) {
    case 'anchor':
      onAnchor?.(link.id)
      return true
    case 'page':
      router.push(pageRoute(link.lang || lang, link.path, link.hash))
      return true
    case 'bible':
      router.push(chapterRoute(link.tr || settings.bible, link.book, link.chapter, link.verse))
      return true
    case 'external': {
      let url = link.url
      if (url.startsWith('/')) url = `${API_BASE || 'https://bibleox.com'}${url}`
      openExternal(url)
      return true
    }
  }
  return false
}
