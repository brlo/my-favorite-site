<script setup>
// Новостная лента. Живые блоки (реакции, «Читают сейчас») работают только
// онлайн; при отсутствии сети показываем последний сохранённый ответ.
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { t, uiLang } from '../lib/i18n.js'
import { settings } from '../lib/settings.js'
import { online } from '../lib/net.js'
import { loadFeedCache, saveFeedCache, fetchFeed, fetchReadingNow } from '../lib/feed.js'
import { pageRoute } from '../router.js'
import NewsCard from '../components/NewsCard.vue'

const lang = computed(() => settings.pagesLang)
const cards = ref([])
const currentPage = ref(1)
const totalPages = ref(1)
const cachedAt = ref(null)
const reading = ref(null)
const loading = ref(false)
const loadingMore = ref(false)
const error = ref(null)
let readingTimer = null

const cachedText = computed(() => {
  if (!cachedAt.value) return ''
  try {
    return new Intl.DateTimeFormat(uiLang.value, {
      day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit',
    }).format(new Date(cachedAt.value))
  } catch {
    return ''
  }
})

function applyFeed(data) {
  cards.value = data.pages || []
  currentPage.value = data.page || 1
  totalPages.value = data.total_pages || 1
  reading.value = data.reading_now || null
  cachedAt.value = Date.now()
}

async function loadCache() {
  const cached = await loadFeedCache(lang.value)
  if (!cached) return
  cards.value = cached.pages || []
  currentPage.value = cached.page || 1
  totalPages.value = cached.total_pages || 1
  reading.value = cached.reading_now || null
  cachedAt.value = cached.cached_at || null
}

async function refresh() {
  if (!online.value) return
  loading.value = true
  error.value = null
  try {
    const data = await fetchFeed(lang.value, 1)
    applyFeed(data)
    await saveFeedCache(lang.value, data)
  } catch (e) {
    error.value = e
  } finally {
    loading.value = false
  }
}

async function loadMore() {
  if (!online.value || loadingMore.value || currentPage.value >= totalPages.value) return
  loadingMore.value = true
  try {
    const data = await fetchFeed(lang.value, currentPage.value + 1)
    const known = new Set(cards.value.map((c) => c.id))
    cards.value = cards.value.concat((data.pages || []).filter((c) => !known.has(c.id)))
    currentPage.value = data.page || currentPage.value + 1
    totalPages.value = data.total_pages || totalPages.value
  } catch (e) {
    error.value = e
  } finally {
    loadingMore.value = false
  }
}

async function refreshReading() {
  if (!online.value) return
  try {
    reading.value = await fetchReadingNow(lang.value)
  } catch {}
}

function onReaction(id, data) {
  const card = cards.value.find((c) => c.id === id)
  if (card) card.reactions = data
}

async function reload() {
  cards.value = []
  currentPage.value = 1
  totalPages.value = 1
  reading.value = null
  cachedAt.value = null
  await loadCache()
  await refresh()
}

onMounted(async () => {
  await reload()
  readingTimer = setInterval(refreshReading, 60_000)
})

onUnmounted(() => {
  clearInterval(readingTimer)
})

watch(() => settings.pagesLang, reload)
watch(online, (value) => { if (value) refresh() })
</script>

<template>
  <div class="page-pad">
    <header class="top-bar">
      <h1>{{ t('news') }}</h1>
      <button class="btn small" :disabled="loading || !online" @click="refresh">
        {{ loading ? t('loading') : t('refresh') }}
      </button>
    </header>

    <p v-if="!online" class="note offline-feed">{{ t('offline_feed') }}</p>
    <p v-else-if="cachedAt" class="muted small">{{ t('feed_updated') }}: {{ cachedText }}</p>

    <div v-if="error" class="note error">
      {{ t('error') }}: {{ error.message || error }}
      <button class="btn small" @click="refresh">{{ t('retry') }}</button>
    </div>

    <section v-if="online && reading && reading.total" class="reading-now">
      <h2 class="reading-now-title">
        <span class="reading-dot" aria-hidden="true"></span>{{ t('reading_now') }}
        <span class="reading-total">{{ reading.total }}</span>
      </h2>
      <ul v-if="(reading.pages && reading.pages.length) || (reading.bibles && reading.bibles.length)">
        <li v-for="p in reading.pages" :key="p.id">
          <router-link :to="pageRoute(lang, p.path)">{{ p.title }}</router-link>
          <span class="reading-count">{{ p.count }}</span>
        </li>
        <li v-for="b in reading.bibles" :key="'bible-' + b.book">
          <span class="reading-item reading-item--bible">{{ b.title }}</span>
          <span class="reading-count">{{ b.count }}</span>
        </li>
      </ul>
    </section>

    <div v-if="loading && !cards.length" class="spinner"></div>
    <div v-else-if="!cards.length" class="note">{{ t('feed_empty') }}</div>

    <NewsCard
      v-for="card in cards"
      :key="card.id"
      :card="card"
      :lang="lang"
      @reaction="onReaction(card.id, $event)"
    />

    <button
      v-if="online && currentPage < totalPages"
      class="btn load-more"
      :disabled="loadingMore"
      @click="loadMore"
    >
      {{ loadingMore ? t('loading') : t('load_more') }}
    </button>
  </div>
</template>
