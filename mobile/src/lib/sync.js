// Фоновая синхронизация: при старте, при появлении сети и при возврате в приложение.
import { ref } from 'vue'
import { online } from './net.js'
import { kvGet, kvSet } from './db.js'
import { fetchManifest } from './manifest.js'
import { outdatedBibles, installBible } from './bible.js'
import { usedLangs, syncSkeleton, staleBodyIds, downloadBodies } from './materials.js'
import { SYNC_INTERVAL } from './config.js'

export const syncing = ref(false)
export const lastSync = ref(null)
export const syncError = ref(null)

export async function loadSyncState() {
  lastSync.value = await kvGet('last_sync', null)
}

export async function syncAll({ force = false } = {}) {
  if (syncing.value || !online.value) return
  if (!force && lastSync.value && Date.now() - lastSync.value < SYNC_INTERVAL) return
  syncing.value = true
  syncError.value = null
  try {
    await fetchManifest()

    for (const tr of await outdatedBibles()) await installBible(tr)

    for (const lang of await usedLangs()) {
      await syncSkeleton(lang)
      const stale = await staleBodyIds(lang)
      for (let i = 0; i < stale.length; i += 50) await downloadBodies(lang, stale.slice(i, i + 50))
    }

    lastSync.value = Date.now()
    await kvSet('last_sync', lastSync.value)
  } catch (e) {
    console.error('sync failed', e)
    syncError.value = e.message || String(e)
  } finally {
    syncing.value = false
  }
}
