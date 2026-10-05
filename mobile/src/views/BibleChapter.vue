<script setup>
// Чтение главы
import { ref, computed, onMounted, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { t } from '../lib/i18n.js'
import { settings } from '../lib/settings.js'
import { books, booksByCode, bibleList, hasAudio, bibleAudioUrl } from '../lib/manifest.js'
import { getChapter, installing } from '../lib/bible.js'
import { hasSkeleton, verseComments } from '../lib/materials.js'
import { localeForBib, bibFontClass, RTL_BIBS } from '../lib/config.js'
import { rubyfy } from '../lib/text.js'
import { player, playUrl, toggle } from '../lib/player.js'
import { chapterRoute, pageRoute } from '../router.js'
import StatusNote from '../components/StatusNote.vue'

const route = useRoute()
const router = useRouter()
const tr = route.params.tr
const book = route.params.book
const chapter = Number(route.params.chapter)
const verse = route.query.v ? Number(route.query.v) : null

const verses = ref([])
const comments = ref({})
const loading = ref(true)
const error = ref(null)

const info = computed(() => booksByCode.value[book])
const isPsalm = book === 'ps'
const title = computed(() => `${info.value?.name || book}, ${isPsalm ? t('psalm') : t('chapter')} ${chapter}`)
const commentsLang = localeForBib(tr)
const audioUrl = computed(() => (hasAudio(tr, book, chapter) ? bibleAudioUrl(tr, book, chapter) : null))
const isThisPlaying = computed(() => player.url && player.url === audioUrl.value)

// соседние главы с переходом между книгами
function neighbour(dir) {
  const list = books.value
  const i = list.findIndex((b) => b.code === book)
  if (i < 0) return null
  if (dir < 0) {
    if (chapter > 1) return { book, chapter: chapter - 1 }
    const prev = list[i - 1]
    return prev ? { book: prev.code, chapter: prev.chapters } : null
  }
  if (chapter < list[i].chapters) return { book, chapter: chapter + 1 }
  const next = list[i + 1]
  return next ? { book: next.code, chapter: 1 } : null
}
const prev = computed(() => neighbour(-1))
const next = computed(() => neighbour(1))

async function load() {
  loading.value = true
  error.value = null
  try {
    const rows = await getChapter(tr, book, chapter)
    verses.value = tr === 'jp-ni' ? rows.map((v) => ({ ...v, text: rubyfy(v.text) })) : rows
    if (await hasSkeleton(commentsLang)) comments.value = await verseComments(commentsLang, book, chapter)
    settings.bible = tr
    settings.lastRead = { tr, book, chapter }
    if (verse) {
      await nextTick()
      document.getElementById(`v${verse}`)?.scrollIntoView({ block: 'center' })
    }
  } catch (e) {
    error.value = e
  } finally {
    loading.value = false
  }
}

onMounted(load)

function changeTr(e) {
  router.replace(chapterRoute(e.target.value, book, chapter, verse))
}

function go(target, autoplay = false) {
  if (!target) return
  if (autoplay) player.autoplay = `${tr}/${target.book}/${target.chapter}`
  router.push(chapterRoute(tr, target.book, target.chapter))
}

function listen() {
  if (isThisPlaying.value) return toggle()
  playUrl(audioUrl.value, title.value, {
    // по окончании — следующая глава, если у неё есть аудио
    onEnded: () => {
      const n = next.value
      if (n && hasAudio(tr, n.book, n.chapter)) go(n, true)
    },
  })
}

onMounted(() => {
  if (player.autoplay === `${tr}/${book}/${chapter}`) {
    player.autoplay = null
    if (audioUrl.value) listen()
  }
})

// перелистывание свайпом
let touch = null
function onTouchStart(e) {
  const p = e.changedTouches[0]
  touch = { x: p.clientX, y: p.clientY, t: Date.now() }
}
function onTouchEnd(e) {
  if (!touch) return
  const p = e.changedTouches[0]
  const dx = p.clientX - touch.x
  const dy = p.clientY - touch.y
  if (Date.now() - touch.t < 600 && Math.abs(dx) > 90 && Math.abs(dy) < 50) go(dx < 0 ? next.value : prev.value)
  touch = null
}
</script>

<template>
  <div class="page-pad" @touchstart.passive="onTouchStart" @touchend.passive="onTouchEnd">
    <header class="top-bar">
      <router-link class="chapter-title" :to="{ name: 'bible', params: { tr }, query: { book } }">
        {{ title }} ▾
      </router-link>
      <select class="tr-select small" :value="tr" @change="changeTr">
        <option v-for="b in bibleList" :key="b.tr_code" :value="b.tr_code">{{ b.title }}{{ b.desc ? ` — ${b.desc}` : '' }}</option>
        <option v-if="!bibleList.some((b) => b.tr_code === tr)" :value="tr">{{ tr }}</option>
      </select>
    </header>

    <button v-if="audioUrl" class="btn listen-btn" @click="listen">
      {{ isThisPlaying && player.playing ? '❚❚' : '▶' }} {{ t('listen') }}
    </button>

    <StatusNote :error="error" :loading="loading" :progress="installing[tr]" @retry="load" />

    <article
      v-if="!loading && !error"
      class="verses"
      :class="[bibFontClass(tr), { 't-rtl': RTL_BIBS.includes(tr) }]"
      :style="{ fontSize: 'var(--text-size)' }"
    >
      <template v-for="v in verses" :key="v.line">
        <p v-if="v.line === 0" class="zero-verse" v-html="v.text"></p>
        <p v-else :id="`v${v.line}`" class="verse" :class="{ selected: v.line === verse }">
          <span class="verse-num">{{ v.line }}</span>
          <span class="verse-text" v-html="v.text"></span>
          <router-link v-if="comments[v.line]" class="bib-comment" :to="pageRoute(commentsLang, comments[v.line])">{{ t('comment') }}</router-link>
        </p>
      </template>
    </article>

    <div v-if="!loading" class="prev-next">
      <button class="btn" :disabled="!prev" @click="go(prev)">← {{ prev ? `${booksByCode[prev.book]?.short || prev.book} ${prev.chapter}` : '' }}</button>
      <button class="btn" :disabled="!next" @click="go(next)">{{ next ? `${booksByCode[next.book]?.short || next.book} ${next.chapter}` : '' }} →</button>
    </div>
  </div>
</template>
