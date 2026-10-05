<script setup>
// HTML статьи: ссылки открываем внутри приложения, картинки берём из кэша.
import { ref, computed, watch, onMounted, nextTick } from 'vue'
import { openHref } from '../router.js'
import { resUrl } from '../lib/manifest.js'
import { localSrc, cacheFile } from '../lib/files.js'
import { online } from '../lib/net.js'
import { t } from '../lib/i18n.js'

const props = defineProps({ html: String, lang: String, tag: { type: String, default: 'article' } })
const el = ref(null)

// картинки не грузим сразу: сначала смотрим, нет ли их в кэше
const safeHtml = computed(() => String(props.html || '').replace(/<img\b([^>]*?)\ssrc=/gi, '<img$1 data-src='))

function scrollToAnchor(id) {
  const target = el.value?.ownerDocument.getElementById(id) || el.value?.querySelector(`[name="${CSS.escape(id)}"]`)
  target?.scrollIntoView({ behavior: 'smooth', block: 'start' })
}

function onClick(e) {
  const a = e.target.closest('a[href]')
  if (!a || !el.value.contains(a)) return
  e.preventDefault()
  openHref(a.getAttribute('href'), { lang: props.lang, onAnchor: scrollToAnchor })
}

async function processImages() {
  await nextTick()
  const imgs = el.value?.querySelectorAll('img[data-src]') || []
  for (const img of imgs) {
    const raw = img.getAttribute('data-src')
    img.removeAttribute('data-src')
    if (!raw) continue
    if (raw.startsWith('data:')) { img.src = raw; continue }
    const url = resUrl(raw)
    img.loading = 'lazy'
    const local = await localSrc(url)
    if (local) {
      img.src = local
    } else if (online.value) {
      img.src = url
      cacheFile(url, 'images').catch(() => {})
    } else {
      const ph = document.createElement('span')
      ph.className = 'img-offline'
      ph.textContent = t('image_offline')
      img.replaceWith(ph)
    }
  }
}

onMounted(processImages)
watch(() => props.html, processImages)

defineExpose({ scrollToAnchor })
</script>

<template>
  <component :is="props.tag" ref="el" class="html-content" v-html="safeHtml" @click="onClick" />
</template>
