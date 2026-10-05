// Настройки пользователя (на устройстве, в localStorage — это удобства, а не данные)
import { reactive, watch } from 'vue'
import { uiLang } from './i18n.js'
import { bibForLocale } from './config.js'

const KEY = 'settings'

function load() {
  try { return JSON.parse(localStorage.getItem(KEY) || '{}') } catch { return {} }
}

export const settings = reactive({
  bible: bibForLocale(uiLang.value),
  pagesLang: uiLang.value,
  fontSize: 18,
  theme: 'auto',
  lastRead: null, // {tr, book, chapter}
  lastPage: null, // {lang, path}
  ...load(),
})

watch(settings, () => {
  try { localStorage.setItem(KEY, JSON.stringify(settings)) } catch {}
}, { deep: true })

export function applyTheme() {
  const root = document.documentElement
  if (settings.theme === 'auto') root.removeAttribute('data-theme')
  else root.setAttribute('data-theme', settings.theme)
  root.style.setProperty('--text-size', `${settings.fontSize}px`)
}

watch(() => [settings.theme, settings.fontSize], applyTheme)
