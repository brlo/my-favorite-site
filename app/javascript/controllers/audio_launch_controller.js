import { Controller } from "@hotwired/stimulus"
import engine from "lib/audio_engine"

// Кнопка «Озвучить» на странице Библии или статьи. Сам плеер - audio_player_controller.js
export default class extends Controller {
  static values = { track: Object }

  connect() {
    // если эту страницу открыли по ходу воспроизведения (следующая глава), плеер узнает, что за ней идёт
    engine.sync(this.trackValue)
  }

  toggle() {
    engine.playTrack(this.trackValue)
  }
}
