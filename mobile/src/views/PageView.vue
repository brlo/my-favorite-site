<script setup>
// Страница материалов: хлебные крошки, меню-дерево, текст, похожие материалы
import { ref, computed, onMounted, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { t } from '../lib/i18n.js'
import { settings } from '../lib/settings.js'
import { online } from '../lib/net.js'
import { query } from '../lib/db.js'
import { manifest, resUrl } from '../lib/manifest.js'
import {
  ensureSkeleton, syncSkeleton, getPageByPath, rootPage, topPages, getBody, menuTree, siblings, ancestors,
  sectionPages, missingBodies, downloadBodiesBatched, PAGE_TYPE_LIST,
} from '../lib/materials.js'
import { localSrc, cacheFile } from '../lib/files.js'
import { norm, formatBytes } from '../lib/text.js'
import { RTL_LANGS } from '../lib/config.js'
import { player, playUrl, toggle } from '../lib/player.js'
import { pageRoute, openHref } from '../router.js'
import StatusNote from '../components/StatusNote.vue'
import MenuTree from '../components/MenuTree.vue'
import HtmlContent from '../components/HtmlContent.vue'

const route = useRoute()
const router = useRouter()
const lang = route.params.lang
const path = route.params.path || null

const page = ref(null)
const body = ref(null)
const bodyError = ref(null)
const crumbs = ref([])
const tree = ref([])
const sibs = ref(null)
const tops = ref([])
const icons = ref({})
const downloaded = ref(new Set())
const cover = ref(null)
const loading = ref(true)
const error = ref(null)
const notFound = ref(false)
const filter = ref('')
const showSiblings = ref(false)
const content = ref(null)

// скачивание раздела
const section = ref(null) // {pages, missing, size}
const sectionProgress = ref(null)
let abort = null

const isList = computed(() => page.value?.page_type === PAGE_TYPE_LIST)
const rtl = RTL_LANGS.includes(lang)
const audioUrl = computed(() => (page.value?.audio ? resUrl(page.value.audio) : null))
const isThisPlaying = computed(() => player.url && player.url === audioUrl.value)
const langsList = computed(() => Object.entries(manifest.value?.page_langs || {}).sort((a, b) => b[1] - a[1]))

async function findPage() {
  if (!path) return rootPage(lang)
  let p = await getPageByPath(lang, path)
  // страницы может не быть в скелете, если её только что добавили — досинхронизируемся
  if (!p && online.value) {
    await syncSkeleton(lang)
    p = await getPageByPath(lang, path)
  }
  return p
}

async function load() {
  loading.value = true
  error.value = null
  notFound.value = false
  try {
    await ensureSkeleton(lang)
    settings.pagesLang = lang
    page.value = await findPage()
    if (!page.value) {
      if (!path) tops.value = await topPages(lang)
      else notFound.value = true
      return
    }
    settings.lastPage = { lang, path: page.value.path }
    crumbs.value = await ancestors(page.value)
    if (isList.value) {
      tree.value = await menuTree(page.value.id)
      icons.value = Object.fromEntries(
        (await query('SELECT path_low, icon FROM pages WHERE lang = ? AND icon IS NOT NULL', [lang])).map((r) => [r.path_low, resUrl(r.icon)])
      )
      await refreshDownloaded()
      prepareSection()
    } else {
      sibs.value = await siblings(page.value)
    }
    loadCover()
    loading.value = false
    await loadBody()
  } catch (e) {
    error.value = e
  } finally {
    loading.value = false
  }
}

async function loadBody() {
  bodyError.value = null
  try {
    body.value = await getBody(page.value)
    if (route.hash) {
      await nextTick()
      content.value?.scrollToAnchor(decodeURIComponent(route.hash.slice(1)))
    }
  } catch (e) {
    bodyError.value = e
  }
}

async function loadCover() {
  const url = resUrl(page.value.cover)
  if (!url) return
  cover.value = (await localSrc(url)) || (online.value ? url : null)
  if (online.value) cacheFile(url, 'images').catch(() => {})
}

async function refreshDownloaded() {
  const rows = await query('SELECT p.path_low FROM page_bodies b JOIN pages p ON p.id = b.id WHERE p.lang = ?', [lang])
  downloaded.value = new Set(rows.map((r) => r.path_low))
}

async function prepareSection() {
  const pages = await sectionPages(page.value)
  const missing = await missingBodies(pages)
  section.value = { pages: pages.length, missing, size: missing.reduce((s, p) => s + (p.body_size || 0), 0) }
}

async function downloadSection() {
  if (!section.value?.missing.length) return
  abort = new AbortController()
  sectionProgress.value = { done: 0, total: section.value.missing.length }
  try {
    await downloadBodiesBatched(lang, section.value.missing, (done, total) => {
      sectionProgress.value = { done, total }
    }, abort.signal)
  } catch (e) {
    error.value = e
  } finally {
    sectionProgress.value = null
    abort = null
    await refreshDownloaded()
    await prepareSection()
  }
}

function cancelSection() {
  abort?.abort()
}

// фильтр меню по названию
const filteredTree = computed(() => {
  const q = norm(filter.value)
  if (!q) return tree.value
  const walk = (items) => items
    .map((m) => {
      if (m.childs.length) {
        const childs = walk(m.childs)
        return childs.length || norm(m.title).includes(q) ? { ...m, childs: childs.length ? childs : m.childs } : null
      }
      return norm(m.title).includes(q) ? m : null
    })
    .filter(Boolean)
  return walk(tree.value)
})

// кнопки-переключатели под заголовком (page.links: [[название, path], ...])
function openLink(v) {
  if (/^https?:\/\//.test(v)) return openHref(v, { lang })
  router.push(pageRoute(lang, v.replace(/^\/+/, '')))
}

function listen() {
  if (isThisPlaying.value) return toggle()
  playUrl(audioUrl.value, page.value.title)
}

function changeLang(e) {
  router.push({ name: 'page', params: { lang: e.target.value } })
}

onMounted(load)
</script>

<template>
  <div class="page-pad" :class="{ 't-rtl': rtl }">
    <header class="top-bar">
      <h1 v-if="!path">{{ t('materials') }}</h1>
      <select v-if="!path && langsList.length" class="tr-select small" :value="lang" @change="changeLang">
        <option v-for="[l, cnt] in langsList" :key="l" :value="l">{{ l }} ({{ cnt }})</option>
      </select>
    </header>

    <StatusNote :error="error" :loading="loading" @retry="load" />
    <div v-if="notFound" class="note">{{ t('page_not_found') }}</div>

    <!-- нет корневой страницы-списка: показываем страницы верхнего уровня -->
    <div v-if="!loading && !page && tops.length" class="menu-tree">
      <div class="items">
        <div v-for="p in tops" :key="p.id" class="menu-unit">
          <router-link :to="pageRoute(lang, p.path)"><span>{{ p.title }}</span></router-link>
        </div>
      </div>
    </div>

    <template v-if="page && !loading">
      <nav v-if="crumbs.length && page.is_show_parent" class="crumbs">
        <template v-for="(c, i) in crumbs" :key="c.id">
          <router-link :to="pageRoute(lang, c.path)">{{ c.title }}</router-link>
          <span v-if="i < crumbs.length - 1"> › </span>
        </template>
      </nav>

      <img v-if="cover" :src="cover" class="cover" alt="" />

      <h1 v-if="path" class="page-title">{{ page.title }}</h1>
      <div v-if="page.title_sub" class="title-sub">{{ page.title_sub }}</div>

      <div v-if="page.links" class="btn-group">
        <template v-for="([k, v], i) in page.links" :key="i">
          <button v-if="v" class="btn" @click="openLink(v)">{{ k }}</button>
          <span v-else class="btn pressed">{{ k }}</span>
        </template>
      </div>

      <button v-if="audioUrl" class="btn listen-btn" @click="listen">
        {{ isThisPlaying && player.playing ? '❚❚' : '▶' }} {{ t('listen') }}
      </button>

      <!-- страница-список: меню -->
      <template v-if="isList">
        <div v-if="section && section.pages > 1" class="section-dl">
          <template v-if="sectionProgress">
            {{ t('downloading') }} {{ sectionProgress.done }} / {{ sectionProgress.total }}
            <button class="btn small" @click="cancelSection">{{ t('cancel') }}</button>
          </template>
          <button v-else-if="section.missing.length" class="btn" :disabled="!online" @click="downloadSection">
            ⬇ {{ t('download_section') }} ({{ section.missing.length }} {{ t('section_pages') }}, ~{{ formatBytes(section.size) }})
          </button>
          <span v-else class="muted">✓ {{ t('section_downloaded') }}</span>
        </div>

        <input v-model="filter" class="filter-input" type="search" :placeholder="t('filter_menu')" />
        <div class="menu-tree">
          <MenuTree :items="filteredTree" :lang="lang" :icons="icons" :downloaded="downloaded" />
        </div>
      </template>

      <!-- похожие материалы (соседи по меню родителя) -->
      <div v-else-if="sibs && sibs.list.length > 1" class="siblings">
        <button class="btn small" @click="showSiblings = !showSiblings">
          {{ t('same_subject') }} ({{ sibs.idx + 1 }} / {{ sibs.list.length }}) {{ showSiblings ? '▴' : '▾' }}
        </button>
        <div v-if="showSiblings" class="menu-tree">
          <div class="items">
            <div v-for="(m, i) in sibs.list" :key="m.id" class="menu-unit" :class="{ selected: i === sibs.idx, gold: m.is_gold }">
              <router-link :to="pageRoute(lang, m.path)"><span>{{ m.title }}</span></router-link>
            </div>
          </div>
        </div>
      </div>

      <StatusNote v-if="bodyError" :error="bodyError" @retry="loadBody" />

      <template v-if="body">
        <nav v-if="body.body_menu?.length" class="article-menu">
          <div class="menu-name">{{ t('contents') }}</div>
          <div v-for="([tag, anchor, text], i) in body.body_menu" :key="i" :class="`nav-${tag}`">
            <a href="#" @click.prevent="content?.scrollToAnchor(anchor)">{{ text }}</a>
          </div>
        </nav>

        <article v-if="body.verses" class="verses" :style="{ fontSize: 'var(--text-size)' }">
          <template v-for="(ch, ci) in body.verses" :key="ci">
            <h3 v-if="ch.title" v-html="ch.title"></h3>
            <p v-for="(l, li) in ch.lines" :key="li" class="verse"><span class="verse-text" v-html="l"></span></p>
          </template>
        </article>
        <HtmlContent v-else ref="content" :html="body.body" :lang="lang" class="article" :style="{ fontSize: 'var(--text-size)' }" />

        <section v-if="body.refs" class="references">
          <h2>{{ t('references') }}</h2>
          <HtmlContent :html="body.refs" :lang="lang" tag="div" />
        </section>
      </template>

      <div v-if="sibs && sibs.list.length > 1" class="prev-next">
        <router-link v-if="sibs.idx > 0" class="btn" :to="pageRoute(lang, sibs.list[sibs.idx - 1].path)">← {{ sibs.list[sibs.idx - 1].title }}</router-link>
        <span v-else></span>
        <router-link v-if="sibs.idx < sibs.list.length - 1" class="btn" :to="pageRoute(lang, sibs.list[sibs.idx + 1].path)">{{ sibs.list[sibs.idx + 1].title }} →</router-link>
      </div>
    </template>
  </div>
</template>
