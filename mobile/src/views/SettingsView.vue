<script setup>
import { ref, computed, onMounted } from 'vue'
import { t, uiLang, setUiLang, UI_LANGS } from '../lib/i18n.js'
import { settings } from '../lib/settings.js'
import { online } from '../lib/net.js'
import { bibleList, fetchManifest } from '../lib/manifest.js'
import { installedBibles, installBible, deleteBible, installing } from '../lib/bible.js'
import { bodiesStats, clearBodies, usedLangs } from '../lib/materials.js'
import { filesStats, clearFiles } from '../lib/files.js'
import { syncAll, syncing, lastSync, syncError } from '../lib/sync.js'
import { formatBytes } from '../lib/text.js'
import { openExternal } from '../router.js'
import { API_BASE } from '../lib/config.js'

const installed = ref({})
const bodies = ref([])
const files = ref({})
const langs = ref([])
const version = __APP_VERSION__

async function refresh() {
  installed.value = await installedBibles()
  bodies.value = await bodiesStats()
  files.value = await filesStats()
  langs.value = await usedLangs()
}
onMounted(refresh)

const lastSyncText = computed(() => (lastSync.value ? new Date(lastSync.value).toLocaleString() : t('never')))

async function changeUiLang(e) {
  setUiLang(e.target.value)
  if (online.value) await fetchManifest().catch(() => {})
}

async function install(tr) {
  try { await installBible(tr) } catch (e) { alert(e.message) }
  await refresh()
}

async function removeBible(tr) {
  if (!confirm(t('confirm_delete'))) return
  await deleteBible(tr)
  await refresh()
}

async function removeBodies(lang) {
  if (!confirm(t('confirm_delete'))) return
  await clearBodies(lang)
  await refresh()
}

async function removeFiles(kind) {
  if (!confirm(t('confirm_delete'))) return
  await clearFiles(kind)
  await refresh()
}

async function syncNow() {
  await syncAll({ force: true })
  await refresh()
}
</script>

<template>
  <div class="page-pad settings">
    <header class="top-bar"><h1>{{ t('settings') }}</h1></header>

    <section>
      <label>{{ t('ui_lang') }}
        <select :value="uiLang" @change="changeUiLang">
          <option v-for="(name, code) in UI_LANGS" :key="code" :value="code">{{ name }}</option>
        </select>
      </label>
      <label>{{ t('font_size') }}: {{ settings.fontSize }}
        <input v-model.number="settings.fontSize" type="range" min="14" max="30" step="1" />
      </label>
      <label>{{ t('theme') }}
        <select v-model="settings.theme">
          <option value="auto">{{ t('theme_auto') }}</option>
          <option value="light">{{ t('theme_light') }}</option>
          <option value="dark">{{ t('theme_dark') }}</option>
        </select>
      </label>
    </section>

    <section>
      <h2>{{ t('status') }}</h2>
      <p>{{ online ? t('online') : t('offline') }}</p>
      <p class="muted">{{ t('last_sync') }}: {{ lastSyncText }}</p>
      <p v-if="syncError" class="muted">{{ t('error') }}: {{ syncError }}</p>
      <button class="btn" :disabled="!online || syncing" @click="syncNow">{{ syncing ? t('syncing') : t('sync_now') }}</button>
    </section>

    <section>
      <h2>{{ t('downloaded_bibles') }}</h2>
      <div v-for="b in bibleList" :key="b.tr_code" class="row">
        <div>
          <div>{{ b.title }}</div>
          <div class="muted small">{{ b.desc }}</div>
        </div>
        <span v-if="installing[b.tr_code]" class="muted">{{ installing[b.tr_code].stage === 'indexing' ? `${t('indexing')} ${installing[b.tr_code].progress}%` : t('downloading') }}</span>
        <button v-else-if="installed[b.tr_code]" class="btn small" @click="removeBible(b.tr_code)">{{ t('delete') }}</button>
        <button v-else class="btn small" :disabled="!online" @click="install(b.tr_code)">⬇</button>
      </div>
    </section>

    <section>
      <h2>{{ t('downloaded_pages') }}</h2>
      <div v-for="l in langs" :key="l" class="row">
        <span>{{ l }}</span>
        <template v-for="b in bodies.filter((x) => x.lang === l)" :key="b.lang">
          <span class="muted">{{ b.cnt }} {{ t('pages_count') }}, {{ formatBytes(b.size) }}</span>
          <button class="btn small" @click="removeBodies(l)">{{ t('clear') }}</button>
        </template>
      </div>
    </section>

    <section>
      <h2>{{ t('storage') }}</h2>
      <div class="row">
        <span>{{ t('audio_files') }}: {{ files.audio?.cnt || 0 }}, {{ formatBytes(files.audio?.size) }}</span>
        <button class="btn small" :disabled="!files.audio" @click="removeFiles('audio')">{{ t('clear') }}</button>
      </div>
      <div class="row">
        <span>{{ t('images') }}: {{ files.images?.cnt || 0 }}, {{ formatBytes(files.images?.size) }}</span>
        <button class="btn small" :disabled="!files.images" @click="removeFiles('images')">{{ t('clear') }}</button>
      </div>
    </section>

    <section>
      <button class="link-btn" @click="openExternal(API_BASE || 'https://bibleox.com')">{{ t('open_site') }}</button>
      <p class="muted small">Bibleox {{ version }}</p>
    </section>
  </div>
</template>
