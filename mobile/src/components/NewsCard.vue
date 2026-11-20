<script setup>
// Карточка новостной ленты. Если у статьи задан цвет подложки, заголовок
// и родительский раздел ложатся на обложку — как на сайте.
import { ref, computed, onMounted, watch } from 'vue'
import { t, uiLang } from '../lib/i18n.js'
import { online } from '../lib/net.js'
import { localSrc, cacheFile } from '../lib/files.js'
import { pageRoute } from '../router.js'
import { overlayStyle, overlayTextColor, overlayTitleClass } from '../lib/cover.js'
import HtmlContent from './HtmlContent.vue'
import ReactionBar from './ReactionBar.vue'

const props = defineProps({
  card: { type: Object, required: true },
  lang: { type: String, required: true },
})
const emit = defineEmits(['reaction'])

const coverSrc = ref(null)
const pageLink = computed(() => pageRoute(props.lang, props.card.path))
const parentLink = computed(() => (props.card.parent ? pageRoute(props.lang, props.card.parent.path) : null))
const hasOverlay = computed(() => !!coverSrc.value && !!props.card.cover_overlay_bg)

const dateText = computed(() => {
  if (!props.card.created_at) return ''
  try {
    return new Intl.DateTimeFormat(uiLang.value, { day: 'numeric', month: 'long', year: 'numeric' })
      .format(new Date(props.card.created_at * 1000))
  } catch {
    return ''
  }
})

function tagLink(tag) {
  return { name: 'tag', params: { lang: props.lang, slug: tag.slug } }
}

async function loadCover() {
  coverSrc.value = null
  if (!props.card.cover) return
  const local = await localSrc(props.card.cover)
  if (local) {
    coverSrc.value = local
    return
  }
  if (online.value) {
    coverSrc.value = props.card.cover
    cacheFile(props.card.cover, 'images').catch(() => {})
  }
}

onMounted(loadCover)
watch(() => props.card.cover, loadCover)
</script>

<template>
  <article class="news-card">
    <div v-if="hasOverlay" class="news-cover is-overlay">
      <router-link :to="pageLink" class="news-cover-link" tabindex="-1" aria-hidden="true">
        <img :src="coverSrc" alt="" loading="lazy" decoding="async" />
      </router-link>
      <div class="cover-overlay" :style="overlayStyle(card.cover_overlay_bg)">
        <div class="cover-overlay-caption" :class="overlayTitleClass(card.title)"
             :style="{ color: overlayTextColor(card.cover_overlay_text) }">
          <div v-if="card.is_show_parent && card.parent" class="cover-overlay-parent">
            <router-link :to="parentLink">{{ card.parent.title }}</router-link>
          </div>
          <h2 class="news-card-title cover-title">
            <router-link :to="pageLink">{{ card.title }}</router-link>
          </h2>
        </div>
      </div>
    </div>
    <router-link v-else-if="coverSrc" :to="pageLink" class="news-cover">
      <img :src="coverSrc" alt="" loading="lazy" decoding="async" />
    </router-link>

    <header class="news-card-header">
      <div class="news-meta">
        <span class="news-author">{{ card.author || t('editorial') }}</span>
        <time v-if="dateText">{{ dateText }}</time>
      </div>

      <h2 v-if="!hasOverlay" class="news-card-title">
        <router-link :to="pageLink">{{ card.title }}</router-link>
      </h2>

      <div v-if="card.title_sub" class="title-sub">{{ card.title_sub }}</div>

      <div v-if="card.tags && card.tags.length" class="news-tags">
        <router-link v-for="tag in card.tags" :key="tag.id" class="tag-chip" :to="tagLink(tag)">
          {{ tag.name }}
        </router-link>
      </div>
    </header>

    <HtmlContent :html="card.preview" :lang="lang" tag="div" class="news-preview" />

    <footer class="news-card-footer">
      <router-link class="btn small" :to="pageLink">{{ t('read_more') }} →</router-link>
      <ReactionBar
        :page-id="card.id"
        :counts="card.reactions?.counts"
        :active="card.reactions?.active"
        compact
        @change="emit('reaction', $event)"
      />
    </footer>
  </article>
</template>
