<script setup>
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { App as CapApp } from '@capacitor/app'
import { initDb } from './lib/db.js'
import { initNetwork, onReconnect, online } from './lib/net.js'
import { loadManifest } from './lib/manifest.js'
import { loadSyncState, syncAll } from './lib/sync.js'
import { applyTheme } from './lib/settings.js'
import { t } from './lib/i18n.js'
import AudioBar from './components/AudioBar.vue'
import BottomNav from './components/BottomNav.vue'

const ready = ref(false)
const fatal = ref(null)
const router = useRouter()
const route = useRoute()

onMounted(async () => {
  applyTheme()
  try {
    await initNetwork()
    await initDb()
    await loadManifest()
    await loadSyncState()
    ready.value = true
  } catch (e) {
    console.error(e)
    fatal.value = e.message || String(e)
    return
  }

  syncAll()
  onReconnect(() => syncAll({ force: true }))
  CapApp.addListener('resume', () => syncAll())
  CapApp.addListener('backButton', ({ canGoBack }) => {
    if (canGoBack && route.name !== 'bible') router.back()
    else CapApp.exitApp()
  })
})
</script>

<template>
  <div class="app">
    <div v-if="!online" class="offline-strip">{{ t('offline') }}</div>
    <main class="main">
      <div v-if="fatal" class="note error">{{ t('error') }}: {{ fatal }}</div>
      <div v-else-if="!ready" class="note">{{ t('loading') }}</div>
      <router-view v-else :key="$route.path" />
    </main>
    <AudioBar />
    <BottomNav />
  </div>
</template>
