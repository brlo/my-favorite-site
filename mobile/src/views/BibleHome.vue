<script setup>
// Выбор перевода, книги и главы
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { t } from '../lib/i18n.js'
import { settings } from '../lib/settings.js'
import { books, bibleList, booksByCode } from '../lib/manifest.js'
import { installedBibles } from '../lib/bible.js'
import { chapterRoute } from '../router.js'

const route = useRoute()
const router = useRouter()
const tr = computed(() => route.params.tr || settings.bible)
const openBook = ref(route.query.book || null)
const installed = ref({})

onMounted(async () => {
  installed.value = await installedBibles()
  if (openBook.value) {
    setTimeout(() => document.getElementById(`book-${openBook.value}`)?.scrollIntoView({ block: 'center' }), 50)
  }
})

const ot = computed(() => books.value.filter((b) => b.zavet === 1))
const nt = computed(() => books.value.filter((b) => b.zavet === 2))
const last = computed(() => settings.lastRead)

function changeTr(e) {
  settings.bible = e.target.value
  router.replace({ name: 'bible', params: { tr: e.target.value }, query: route.query })
}

function toggleBook(code) {
  if (booksByCode.value[code]?.chapters === 1) {
    router.push(chapterRoute(tr.value, code, 1))
    return
  }
  openBook.value = openBook.value === code ? null : code
}
</script>

<template>
  <div class="page-pad">
    <header class="top-bar">
      <h1>{{ t('bible') }}</h1>
      <select class="tr-select" :value="tr" @change="changeTr">
        <option v-for="b in bibleList" :key="b.tr_code" :value="b.tr_code">
          {{ b.title }}{{ b.desc ? ` — ${b.desc}` : '' }}{{ installed[b.tr_code] ? ' ✓' : '' }}
        </option>
        <option v-if="!bibleList.length" :value="tr">{{ tr }}</option>
      </select>
    </header>

    <router-link v-if="last" class="continue-btn" :to="chapterRoute(last.tr, last.book, last.chapter)">
      {{ t('continue_reading') }}: {{ booksByCode[last.book]?.name || last.book }} {{ last.chapter }}
    </router-link>

    <section v-for="[title, list] in [[t('ot'), ot], [t('nt'), nt]]" :key="title" class="books">
      <h2>{{ title }}</h2>
      <div v-for="b in list" :key="b.code" :id="`book-${b.code}`" class="book">
        <button class="book-name" :class="{ open: openBook === b.code }" @click="toggleBook(b.code)">
          {{ b.name }}
        </button>
        <div v-if="openBook === b.code" class="chapters-grid">
          <router-link v-for="n in b.chapters" :key="n" :to="chapterRoute(tr, b.code, n)">{{ n }}</router-link>
        </div>
      </div>
    </section>
  </div>
</template>
