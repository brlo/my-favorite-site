// Глобальный аудиоплеер: играет дальше при переходах между экранами.
import { reactive } from 'vue'
import { cacheFile, localSrc } from './files.js'
import { online } from './net.js'

export const player = reactive({
  url: null, // адрес на сервере (ключ кэша)
  title: '',
  playing: false,
  loading: false,
  error: null,
  current: 0,
  duration: 0,
  onEnded: null, // что делать по окончании (например, следующая глава)
  autoplay: null, // глава, которую включить сразу после перехода
})

const audio = new Audio()
audio.preload = 'auto'
audio.addEventListener('play', () => { player.playing = true })
audio.addEventListener('pause', () => { player.playing = false })
audio.addEventListener('timeupdate', () => { player.current = audio.currentTime })
audio.addEventListener('durationchange', () => { player.duration = audio.duration || 0 })
audio.addEventListener('ended', () => {
  player.playing = false
  player.onEnded?.()
})
audio.addEventListener('error', () => {
  if (player.url) player.error = 'error'
  player.loading = false
})

export async function playUrl(url, title, { onEnded = null } = {}) {
  player.error = null
  player.onEnded = onEnded
  if (player.url === url && audio.src) {
    audio.play()
    return
  }
  audio.pause()
  player.url = url
  player.title = title
  player.current = 0
  player.duration = 0
  player.loading = true
  try {
    // сначала скачиваем в память — тогда файл останется доступен оффлайн
    let src = await localSrc(url)
    if (!src && online.value) {
      try {
        src = await cacheFile(url, 'audio')
      } catch (e) {
        console.warn('audio cache failed, streaming', e)
      }
      if (!src) src = url // браузер / ошибка скачивания — играем потоком
    }
    if (player.url !== url) return // пока качали, включили другое
    if (!src) {
      player.error = 'offline'
      return
    }
    audio.src = src
    await audio.play()
  } catch (e) {
    console.error(e)
    player.error = 'error'
  } finally {
    player.loading = false
  }
}

export function toggle() {
  if (!audio.src) return
  if (audio.paused) audio.play()
  else audio.pause()
}

export function seek(sec) {
  if (Number.isFinite(sec)) audio.currentTime = sec
}

export function stop() {
  audio.pause()
  audio.removeAttribute('src')
  audio.load()
  Object.assign(player, { url: null, title: '', playing: false, loading: false, error: null, current: 0, duration: 0, onEnded: null })
}
