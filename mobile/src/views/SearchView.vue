<script setup>
// Поиск по Библии (скачанные переводы) и по материалам (заголовки + скачанные тексты)
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { t } from '../lib/i18n.js'
import { settings } from '../lib/settings.js'
import { bibleList, booksByCode } from '../lib/manifest.js'
import { searchBible, installedBibles, ensureBible, installing } from '../lib/bible.js'
import { searchTitles, searchTexts, usedLangs, ensureSkeleton } from '../lib/materials.js'
import { queryTerms, highlightText, snippet, stripTags } from '../lib/text.js'
import { chapterRoute, pageRoute } from '../router.js'
import StatusNote from '../components/StatusNote.vue'

const route = useRoute()
const router = useRouter()

const q = ref(route.query.q || '')
const scope = ref(route.query.scope || 'bible')
const exact = ref(route.query.exact === '1')
const tr = ref(route.query.tr || settings.bible)
const lang = ref(route.query.lang || settings.pagesLang)

const installed = ref({})
const langs = ref([])
const loading = ref(false)
const error = ref(null)
const bibleRes = ref(null)
const titleRes = ref([])
const textRes = ref(null)
const terms = ref({ words: [], cjk: '' })
const expanded = ref(new Set())

const trOptions = computed(() => bibleList.value.length ? bibleList.value : [{ tr_code: tr.value, title: tr.value }])

onMounted(async () => {
  installed.value = await installedBibles()
  langs.value = await usedLangs()
  if (!langs.value.includes(lang.value)) langs.value.push(lang.value)
  if (q.value) run()
})

async function run() {
  const text = q.value.trim()
  if (!text) return
  router.replace({ query: { q: text, scope: scope.value, exact: exact.value ? '1' : undefined, tr: tr.value, lang: lang.value } })
  loading.value = true
  error.value = null
  terms.value = queryTerms(text)
  expanded.value = new Set()
  try {
    if (scope.value === 'bible') {
      bibleRes.value = null
      await ensureBible(tr.value)
      installed.value = await installedBibles()
      bibleRes.value = await searchBible(tr.value, text, { exact: exact.value })
    } else {
      textRes.value = null
      await ensureSkeleton(lang.value)
      titleRes.value = await searchTitles(lang.value, text)
      textRes.value = await searchTexts(lang.value, text, { exact: exact.value })
    }
  } catch (e) {
    error.value = e
  } finally {
    loading.value = false
  }
}

function hl(html) {
  return highlightText(stripTags(html), terms.value)
}

function toggleExpand(id) {
  const s = new Set(expanded.value)
  s.has(id) ? s.delete(id) : s.add(id)
  expanded.value = s
}
</script>

<template>
  <div class="page-pad">
    <form class="search-form" @submit.prevent="run">
      <input v-model="q" type="search" :placeholder="t('search_placeholder')" enterkeyhint="search" autofocus />
      <button class="btn" type="submit">{{ t('search') }}</button>
    </form>

    <div class="search-opts">
      <div class="tabs">
        <button :class="{ active: scope === 'bible' }" @click="scope = 'bible'; run()">{{ t('search_bible') }}</button>
        <button :class="{ active: scope === 'pages' }" @click="scope = 'pages'; run()">{{ t('search_pages') }}</button>
      </div>
      <select v-if="scope === 'bible'" v-model="tr" class="tr-select small" @change="run">
        <option v-for="b in trOptions" :key="b.tr_code" :value="b.tr_code">{{ b.title }}{{ b.desc ? ` — ${b.desc}` : '' }}{{ installed[b.tr_code] ? ' ✓' : '' }}</option>
      </select>
      <select v-else v-model="lang" class="tr-select small" @change="run">
        <option v-for="l in langs" :key="l" :value="l">{{ l }}</option>
      </select>
      <label class="check"><input v-model="exact" type="checkbox" @change="run" /> {{ t('exact_phrase') }}</label>
    </div>

    <StatusNote :error="error" :loading="loading" :progress="scope === 'bible' ? installing[tr] : null" @retry="run" />

    <template v-if="!loading && !error && scope === 'bible' && bibleRes">
      <div class="muted">{{ t('found') }}: {{ bibleRes.verses.length }}{{ bibleRes.more ? '+' : '' }}</div>
      <div v-if="!bibleRes.verses.length" class="note">{{ t('nothing_found') }}</div>
      <router-link
        v-for="v in bibleRes.verses"
        :key="`${v.book}${v.chapter}:${v.line}`"
        class="result"
        :to="chapterRoute(tr, v.book, v.chapter, v.line)"
      >
        <div class="result-ref">{{ booksByCode[v.book]?.short || v.book }} {{ v.chapter }}:{{ v.line }}</div>
        <div class="result-text" v-html="hl(v.text)"></div>
      </router-link>
    </template>

    <template v-if="!loading && !error && scope === 'pages' && textRes">
      <p class="muted small">{{ t('search_hint_pages') }}</p>
      <template v-if="titleRes.length">
        <h3>{{ t('in_titles') }} ({{ titleRes.length }})</h3>
        <router-link v-for="p in titleRes" :key="p.id" class="result" :to="pageRoute(lang, p.path)">
          <div class="result-title" v-html="highlightText(p.title, terms)"></div>
          <div v-if="p.title_sub" class="muted small">{{ p.title_sub }}</div>
        </router-link>
      </template>
      <h3>{{ t('in_texts') }} ({{ textRes.length }})</h3>
      <div v-if="!textRes.length && !titleRes.length" class="note">{{ t('nothing_found') }}</div>
      <div v-for="p in textRes" :key="p.id" class="result">
        <router-link class="result-title" :to="pageRoute(lang, p.path)">{{ p.title }}</router-link>
        <div
          v-for="(para, i) in (expanded.has(p.id) ? p.paras : p.paras.slice(0, 3))"
          :key="i"
          class="result-text"
          v-html="highlightText(snippet(para, terms), terms)"
        ></div>
        <button v-if="p.paras.length > 3 && !expanded.has(p.id)" class="link-btn" @click="toggleExpand(p.id)">
          {{ t('more') }} {{ p.paras.length - 3 }}
        </button>
      </div>
    </template>
  </div>
</template>
