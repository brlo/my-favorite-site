<script setup>
// Статьи с тегом — из локального скелета, поэтому работают офлайн.
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { t } from '../lib/i18n.js'
import { ensureSkeleton, tagInfo, pagesForTag } from '../lib/materials.js'
import { pageRoute } from '../router.js'

const route = useRoute()
const lang = route.params.lang
const slug = route.params.slug
const tag = ref(null)
const pages = ref([])
const loading = ref(true)
const error = ref(null)

const rootLink = computed(() => ({ name: 'page', params: { lang } }))

async function load() {
  loading.value = true
  error.value = null
  try {
    await ensureSkeleton(lang)
    tag.value = await tagInfo(lang, slug)
    pages.value = await pagesForTag(lang, slug)
  } catch (e) {
    error.value = e
  } finally {
    loading.value = false
  }
}

onMounted(load)
</script>

<template>
  <div class="page-pad">
    <header class="top-bar">
      <router-link class="btn small" :to="rootLink">← {{ t('materials') }}</router-link>
    </header>

    <div v-if="loading" class="spinner"></div>
    <div v-else-if="error" class="note error">{{ t('error') }}: {{ error.message || error }}</div>

    <template v-else>
      <h1 class="page-title">{{ tag?.name || slug }}</h1>
      <p class="muted small">{{ t('articles_with_tag') }}: {{ pages.length }}</p>

      <div v-if="pages.length" class="tag-pages">
        <router-link
          v-for="p in pages"
          :key="p.id"
          class="tag-page-link"
          :to="pageRoute(lang, p.path)"
        >
          {{ p.title }}
        </router-link>
      </div>
      <div v-else class="note">{{ t('no_articles') }}</div>
    </template>
  </div>
</template>
