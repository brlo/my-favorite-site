<script setup>
// Ряд реакций: на сайте одна реакция на IP, здесь просто повторяем запрос
// и показываем то, что вернул сервер. Офлайн кнопки неактивны.
import { ref, watch, onMounted } from 'vue'
import { online } from '../lib/net.js'
import { t } from '../lib/i18n.js'
import {
  REACTION_KINDS, loadCachedReactions, saveCachedReactions, fetchReactions, toggleReaction,
} from '../lib/reactions.js'

const props = defineProps({
  pageId: { type: Number, required: true },
  counts: { type: Object, default: null },
  active: { type: String, default: null },
  compact: { type: Boolean, default: false },
})
const emit = defineEmits(['change'])

const counts = ref({})
const active = ref(null)
const busy = ref(false)

function apply(data) {
  if (!data) return
  if (data.counts) counts.value = data.counts
  if ('active' in data) active.value = data.active
}

watch(() => props.counts, (v) => { if (v) counts.value = v }, { immediate: true, deep: true })
watch(() => props.active, (v) => { active.value = v }, { immediate: true })

onMounted(async () => {
  // В ленте счётчики уже пришли в карточке — лишний запрос на каждую не нужен
  const hasInitial = !!props.counts && Object.keys(props.counts).length > 0
  if (!hasInitial && !Object.keys(counts.value).length) {
    const cached = await loadCachedReactions(props.pageId)
    if (cached) apply(cached)
  }
  if (!online.value) return
  if (hasInitial) {
    saveCachedReactions(props.pageId, { counts: counts.value, active: active.value }).catch(() => {})
    return
  }
  try {
    const fresh = await fetchReactions(props.pageId)
    if (fresh) {
      apply(fresh)
      await saveCachedReactions(props.pageId, fresh)
      emit('change', { counts: counts.value, active: active.value })
    }
  } catch {}
})

async function pick(kind) {
  if (!online.value || busy.value) return
  busy.value = true
  try {
    const data = await toggleReaction(props.pageId, kind)
    if (data) {
      apply(data)
      await saveCachedReactions(props.pageId, data)
      emit('change', { counts: counts.value, active: active.value })
    }
  } catch {} finally {
    busy.value = false
  }
}
</script>

<template>
  <div class="reaction-bar" :class="{ 'is-compact': compact }">
    <button
      v-for="r in REACTION_KINDS"
      :key="r.kind"
      type="button"
      class="reaction-choice"
      :class="{ 'is-active': active === r.kind, 'is-empty': !(counts[r.kind] > 0) }"
      :disabled="!online || busy"
      :aria-pressed="active === r.kind"
      :aria-label="`${t(r.label)} (${counts[r.kind] || 0})`"
      :title="t(r.label)"
      @click="pick(r.kind)"
    >
      <span class="reaction-emoji" aria-hidden="true">{{ r.emoji }}</span>
      <span v-if="counts[r.kind] > 0" class="reaction-count">{{ counts[r.kind] }}</span>
    </button>
  </div>
</template>
