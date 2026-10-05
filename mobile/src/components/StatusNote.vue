<script setup>
import { t } from '../lib/i18n.js'

// error — исключение из загрузки; показываем понятный текст для «не скачано»
const props = defineProps({ error: Object, loading: Boolean, progress: Object })
const emit = defineEmits(['retry'])

function message(e) {
  if (e?.notDownloaded === 'bible') return t('not_downloaded_bible')
  if (e?.notDownloaded === 'page') return t('not_downloaded_page')
  if (e?.notDownloaded === 'skeleton') return t('not_downloaded_skeleton')
  if (e?.offline) return t('offline')
  return `${t('error')}: ${e?.message || e}`
}
</script>

<template>
  <div v-if="props.error" class="note" :class="{ error: !props.error.notDownloaded }">
    <p>{{ message(props.error) }}</p>
    <button class="btn" @click="emit('retry')">{{ t('retry') }}</button>
  </div>
  <div v-else-if="props.loading || props.progress" class="note">
    <template v-if="props.progress?.stage === 'indexing'">{{ t('indexing') }} {{ props.progress.progress }}%</template>
    <template v-else-if="props.progress?.stage === 'downloading'">{{ t('downloading') }}</template>
    <template v-else>{{ t('loading') }}</template>
    <div class="spinner"></div>
  </div>
</template>
