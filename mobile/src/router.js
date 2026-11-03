import { createRouter, createWebHashHistory } from 'vue-router'
import { Browser } from '@capacitor/browser'
import { settings } from './lib/settings.js'
import { parseHref } from './lib/links.js'
import { booksByCode } from './lib/manifest.js'
import { API_BASE } from './lib/config.js'
import { rememberScroll, rememberedScroll, whenScrollable } from './lib/scroll.js'

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
  // «назад» — туда, где были; на ранее открытый материал — туда, где остановились
  async scrollBehavior(to, from, saved) {
    let top = saved?.top
    if (top == null && to.name === 'page' && !to.hash) top = rememberedScroll(to.path)
    if (!top) return { top: 0 }
    restoring = to.fullPath
    const ok = await whenScrollable(top)
    // пока ждали, могли уйти на другую страницу
    const current = restoring === to.fullPath
    if (current) restoring = null
    return ok && current ? { top } : false
  },
})

let restoring = null // страница, на которую ещё не вернули прокрутку

router.beforeEach((to, from) => {
  if (from.name === 'page' && restoring !== from.fullPath) rememberScroll(from.path, window.scrollY)
  restoring = null
})

export function rememberCurrentScroll() {
  const r = router.currentRoute.value
  if (r.name === 'page') rememberScroll(r.path, window.scrollY)
}

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
