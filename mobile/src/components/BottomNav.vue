<script setup>
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { t } from '../lib/i18n.js'
import { settings } from '../lib/settings.js'

const route = useRoute()
const section = computed(() => {
  const n = route.name
  if (n === 'bible' || n === 'chapter') return 'bible'
  if (n === 'page') return 'page'
  return n
})

const bibleLink = computed(() => {
  const r = settings.lastRead
  return r ? `/bible/${r.tr}/${r.book}/${r.chapter}` : '/bible'
})
const pagesLink = computed(() => {
  const p = settings.lastPage
  return section.value === 'page' || !p ? `/w/${settings.pagesLang}` : `/w/${p.lang}/${encodeURIComponent(p.path)}`
})
</script>

<template>
  <nav class="bottom-nav">
    <router-link :to="section === 'bible' ? '/bible' : bibleLink" :class="{ active: section === 'bible' }">
      <svg viewBox="0 0 24 24"><path d="M12 6.04A8.97 8.97 0 0 0 6 3.75c-1.05 0-2.06.18-3 .51v14.25A8.99 8.99 0 0 1 6 18c2.3 0 4.4.87 6 2.29m0-14.25a8.97 8.97 0 0 1 6-2.29c1.05 0 2.06.18 3 .51v14.25A8.99 8.99 0 0 0 18 18a8.97 8.97 0 0 0-6 2.29m0-14.25v14.25"/></svg>
      <span>{{ t('bible') }}</span>
    </router-link>
    <router-link :to="pagesLink" :class="{ active: section === 'page' }">
      <svg viewBox="0 0 24 24"><path d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5"/></svg>
      <span>{{ t('materials') }}</span>
    </router-link>
    <router-link to="/search" :class="{ active: section === 'search' }">
      <svg viewBox="0 0 24 24"><path d="m21 21-5.2-5.2m0 0A7.5 7.5 0 1 0 5.2 5.2a7.5 7.5 0 0 0 10.6 10.6Z"/></svg>
      <span>{{ t('search') }}</span>
    </router-link>
    <router-link to="/settings" :class="{ active: section === 'settings' }">
      <svg viewBox="0 0 24 24"><path d="M10.5 6h9.75M10.5 6a1.5 1.5 0 1 1-3 0m3 0a1.5 1.5 0 1 0-3 0M3.75 6H7.5m3 12h9.75m-9.75 0a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m-3.75 0H7.5m9-6h3.75m-3.75 0a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m-9.75 0h9.75"/></svg>
      <span>{{ t('settings') }}</span>
    </router-link>
  </nav>
</template>
