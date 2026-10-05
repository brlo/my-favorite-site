<script setup>
import { computed } from 'vue'
import { player, toggle, seek, stop } from '../lib/player.js'
import { downloads } from '../lib/files.js'
import { t } from '../lib/i18n.js'

const fmt = (s) => {
  if (!Number.isFinite(s)) return '0:00'
  const m = Math.floor(s / 60)
  return `${m}:${String(Math.floor(s % 60)).padStart(2, '0')}`
}
const dl = computed(() => (player.url ? downloads[player.url] : undefined))
</script>

<template>
  <div v-if="player.url" class="audio-bar">
    <button class="icon-btn" :disabled="player.loading" @click="toggle" :aria-label="player.playing ? 'pause' : 'play'">
      <svg v-if="player.playing" viewBox="0 0 24 24"><path d="M15.75 5.25v13.5m-7.5-13.5v13.5"/></svg>
      <svg v-else viewBox="0 0 24 24"><path d="M5.25 5.65c0-.86.92-1.4 1.67-.98l11.54 6.35a1.13 1.13 0 0 1 0 1.97L6.92 19.33c-.75.42-1.67-.13-1.67-.98V5.65Z"/></svg>
    </button>
    <div class="audio-info">
      <div class="audio-title">{{ player.title }}</div>
      <div v-if="player.error === 'offline'" class="audio-sub">{{ t('audio_unavailable') }}</div>
      <div v-else-if="player.error" class="audio-sub">{{ t('error') }}</div>
      <div v-else-if="player.loading" class="audio-sub">{{ t('downloading') }} {{ dl !== undefined ? dl + '%' : '' }}</div>
      <input
        v-else
        type="range"
        min="0"
        :max="player.duration || 0"
        step="1"
        :value="player.current"
        @input="seek(Number($event.target.value))"
      />
    </div>
    <div class="audio-time" v-if="!player.loading && !player.error">{{ fmt(player.current) }}</div>
    <button class="icon-btn" @click="stop" aria-label="close">
      <svg viewBox="0 0 24 24"><path d="M6 18 18 6M6 6l12 12"/></svg>
    </button>
  </div>
</template>
