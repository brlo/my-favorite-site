import { Controller } from "@hotwired/stimulus"
import engine from "lib/audio_engine"

// Панель плеера внизу экрана. Звуком управляет lib/audio_engine.js, здесь только интерфейс.
export default class extends Controller {
  static targets = ["play", "title", "credit", "rate", "current", "duration", "seek"]
  static values = { labelPlay: String, labelPause: String }

  connect() {
    this.isSeeking = false
    this.render = this.render.bind(this)
    engine.addEventListener("change", this.render)
    this.render()
  }

  disconnect() {
    engine.removeEventListener("change", this.render)
  }

  toggle() { engine.toggle() }
  back() { engine.skip(-15) }
  forward() { engine.skip(15) }
  cycleRate() { engine.cycleRate() }
  close() { engine.close() }

  // тянут ползунок: показываем время, звук перематываем, когда отпустили
  seeking() {
    this.isSeeking = true
    this.showTimes(Number(this.seekTarget.value), engine.state.duration)
    this.paintSeek()
  }

  seek() {
    this.isSeeking = false
    engine.seek(Number(this.seekTarget.value))
  }

  render() {
    const s = engine.state
    const has = !!s.track

    this.element.hidden = !has
    document.documentElement.classList.toggle("has-audio-player", has)
    if (!has) return

    this.element.classList.toggle("is-playing", s.isPlaying)
    this.element.classList.toggle("is-waiting", s.isWaiting)
    this.element.classList.toggle("has-error", s.hasError)
    this.playTarget.setAttribute("aria-label", s.isPlaying ? this.labelPauseValue : this.labelPlayValue)

    this.titleTarget.textContent = s.track.title
    this.creditTarget.hidden = !s.track.credit
    if (s.track.credit) {
      this.creditTarget.textContent = s.track.credit
      this.creditTarget.href = s.track.creditUrl || "#"
    }
    this.rateTarget.textContent = `${s.rate}×`

    this.seekTarget.max = Math.floor(s.duration)
    if (!this.isSeeking) {
      this.seekTarget.value = Math.floor(s.current)
      this.showTimes(s.current, s.duration)
    }
    this.paintSeek()
  }

  showTimes(current, duration) {
    this.currentTarget.textContent = this.format(current)
    this.durationTarget.textContent = this.format(duration)
  }

  // закрашенная часть полоски: через css-переменную
  paintSeek() {
    const max = Number(this.seekTarget.max) || 1
    this.seekTarget.style.setProperty("--ap-progress", `${(Number(this.seekTarget.value) / max) * 100}%`)
  }

  format(seconds) {
    const s = Math.max(0, Math.floor(seconds || 0))
    const h = Math.floor(s / 3600)
    const m = Math.floor((s % 3600) / 60)
    const sec = String(s % 60).padStart(2, "0")
    return h > 0 ? `${h}:${String(m).padStart(2, "0")}:${sec}` : `${m}:${sec}`
  }
}
