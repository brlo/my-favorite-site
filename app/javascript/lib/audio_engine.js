// Единственный аудио-плеер сайта (движок без интерфейса).
//
// Живёт в модуле, а модуль переживает переходы Turbo, поэтому звук не прерывается при смене страницы.
// <audio> не вставлен в DOM (new Audio()): браузеры не ставят такой элемент на паузу при смене body,
// и он продолжает играть при заблокированном экране.
//
// Трек: { src, title, href, kind?, credit?, creditUrl?, next?: { src, title, href, kind? } }
//   href - страница, к которой относится трек (на неё переходим, когда читатель слушает «свою» страницу)
//   kind - 'bible' для глав Библии: между главами звук идёт за текстом
//   next - трек, на который переключаемся по окончании (следующая глава)
const RATES = [1, 1.25, 1.5, 2, 0.75]
const SEEK_STEP = 15
const RATE_KEY = 'audio-rate'

function readRate() {
  try {
    const rate = parseFloat(localStorage.getItem(RATE_KEY))
    return RATES.includes(rate) ? rate : 1
  } catch (e) {
    return 1
  }
}

function samePath(a, b) {
  const clean = (p) => decodeURI(String(p || '').split(/[?#]/)[0]).replace(/\/+$/, '')
  return clean(a) === clean(b)
}

class AudioEngine extends EventTarget {
  constructor() {
    super()
    this.track = null
    this.hasError = false
    this.tabId = Math.random().toString(36).slice(2)
    this.lastPositionState = 0

    this.audio = new Audio()
    this.audio.preload = 'metadata'
    this.setRate(readRate())

    for (const name of ['play', 'pause', 'timeupdate', 'durationchange', 'loadedmetadata', 'waiting', 'playing', 'ratechange']) {
      this.audio.addEventListener(name, () => this.changed(name))
    }
    this.audio.addEventListener('play', () => this.announcePlaying())
    this.audio.addEventListener('ended', () => this.onEnded())
    this.audio.addEventListener('error', () => {
      if (!this.track) return
      this.hasError = true
      this.changed('error')
    })

    // Включили звук в другой вкладке сайта - здесь ставим на паузу
    this.channel = 'BroadcastChannel' in window ? new BroadcastChannel('bibleox-audio') : null
    if (this.channel) {
      this.channel.onmessage = (e) => {
        if (e.data?.type === 'playing' && e.data.tabId !== this.tabId) this.audio.pause()
      }
    }

    this.setupMediaSession()
  }

  // --- состояние для интерфейса ---

  get state() {
    const duration = Number.isFinite(this.audio.duration) ? this.audio.duration : 0
    return {
      track: this.track,
      isPlaying: !this.audio.paused && !this.audio.ended,
      isWaiting: !!this.track && !this.audio.paused && this.audio.readyState < 3 && !this.hasError,
      hasError: this.hasError,
      current: this.audio.currentTime || 0,
      duration,
      rate: this.audio.playbackRate,
    }
  }

  changed(name) {
    this.dispatchEvent(new Event('change'))
    if (name === 'timeupdate') {
      this.updatePositionState()
    } else {
      this.updatePlaybackState()
    }
  }

  // --- управление ---

  // Нажали «Озвучить» на странице: тот же трек - пауза/продолжить, другой - загрузить и играть
  playTrack(track) {
    if (this.track?.src === track.src) {
      this.toggle()
    } else {
      this.load(track)
    }
  }

  load(track) {
    this.track = { ...track }
    this.hasError = false
    this.audio.src = track.src
    // при смене src браузер сбрасывает скорость на defaultPlaybackRate
    this.setRate(this.audio.defaultPlaybackRate)
    this.updateMetadata()
    this.changed('load')
    this.play()
  }

  play() {
    if (!this.track) return
    this.hasError = false
    this.audio.play().catch((e) => {
      // NotAllowedError: браузер запретил автозапуск, ждём нажатия; остальное - ошибка файла
      if (e.name !== 'NotAllowedError' && e.name !== 'AbortError') {
        this.hasError = true
        this.changed('error')
      }
    })
  }

  pause() {
    this.audio.pause()
  }

  toggle() {
    if (this.audio.paused) {
      this.play()
    } else {
      this.pause()
    }
  }

  seek(seconds) {
    if (!this.track) return
    const max = Number.isFinite(this.audio.duration) ? this.audio.duration : seconds
    this.audio.currentTime = Math.min(Math.max(seconds, 0), max)
    this.changed('seek')
  }

  skip(delta) {
    this.seek(this.audio.currentTime + delta)
  }

  setRate(rate) {
    this.audio.defaultPlaybackRate = rate
    this.audio.playbackRate = rate
    try {
      localStorage.setItem(RATE_KEY, String(rate))
    } catch (e) { /* без хранилища просто не запоминаем */ }
  }

  cycleRate() {
    const i = RATES.indexOf(this.audio.playbackRate)
    this.setRate(RATES[(i + 1) % RATES.length])
  }

  close() {
    this.track = null
    this.hasError = false
    this.audio.pause()
    this.audio.removeAttribute('src')
    this.audio.load()
    if ('mediaSession' in navigator) navigator.mediaSession.metadata = null
    this.changed('close')
  }

  // Страница загрузилась и описывает свой трек
  sync(pageTrack) {
    if (!this.track) return

    if (this.track.src === pageTrack.src) {
      // это та самая глава, что звучит: обновляем сведения о следующей
      this.track = { ...pageTrack }
      this.setupMediaSession()
      this.changed('sync')
    } else if (this.state.isPlaying && this.track.kind === 'bible' && pageTrack.kind === 'bible') {
      // читатель открыл другую главу, пока звучит глава Библии: звук идёт за текстом
      this.load(pageTrack)
    }
  }

  // --- переключение на следующий трек ---

  onEnded() {
    this.changed('ended')
    this.playNext()
  }

  playNext() {
    const current = this.track
    const next = current?.next
    if (!next) return

    // Звук переключаем сразу, не дожидаясь загрузки страницы: в фоне и при заблокированном экране
    // браузеры могут задержать или запретить запуск звука уже после перехода.
    const isOnTrackPage = samePath(location.pathname, current.href)
    this.load(next)
    // Если читатель всё ещё на странице этого трека, текст идёт следом за звуком
    if (isOnTrackPage && next.href) window.Turbo?.visit(next.href)
  }

  // --- другие вкладки ---

  announcePlaying() {
    this.channel?.postMessage({ type: 'playing', tabId: this.tabId })
  }

  // --- экран блокировки и кнопки гарнитуры ---

  setupMediaSession() {
    if (!('mediaSession' in navigator)) return
    const ms = navigator.mediaSession
    const set = (action, handler) => {
      try { ms.setActionHandler(action, handler) } catch (e) { /* действие не поддерживается */ }
    }

    set('play', () => this.play())
    set('pause', () => this.pause())
    set('seekbackward', () => this.skip(-SEEK_STEP))
    set('seekforward', () => this.skip(SEEK_STEP))
    set('seekto', (d) => this.seek(d.seekTime))
    set('stop', () => this.close())
    set('nexttrack', this.track?.next ? () => this.playNext() : null)
  }

  updateMetadata() {
    if (!('mediaSession' in navigator) || !this.track) return
    const icon = document.querySelector('link[rel="apple-touch-icon"]')?.href
    navigator.mediaSession.metadata = new MediaMetadata({
      title: this.track.title,
      artist: 'Bibleox',
      artwork: icon ? [{ src: icon, sizes: '180x180', type: 'image/png' }] : [],
    })
    this.setupMediaSession()
  }

  updatePlaybackState() {
    if ('mediaSession' in navigator) {
      navigator.mediaSession.playbackState = !this.track ? 'none' : (this.audio.paused ? 'paused' : 'playing')
    }
  }

  // Ползунок на экране блокировки: обновляем не чаще раза в секунду
  updatePositionState() {
    if (!('mediaSession' in navigator) || !navigator.mediaSession.setPositionState) return
    const now = Date.now()
    if (now - this.lastPositionState < 1000) return
    this.lastPositionState = now

    const { duration, current, rate } = this.state
    if (!duration) return
    try {
      navigator.mediaSession.setPositionState({ duration, playbackRate: rate, position: Math.min(current, duration) })
    } catch (e) { /* значения вне допустимых - пропускаем */ }
  }
}

const engine = new AudioEngine()
export default engine
