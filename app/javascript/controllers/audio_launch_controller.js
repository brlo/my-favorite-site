import { Controller } from "@hotwired/stimulus"
import engine from "lib/audio_engine"

// Кнопка «Озвучить» на странице Библии или статьи. Сам плеер - audio_player_controller.js
export default class extends Controller {
  static values = { track: Object }

  connect() {
    // страницу открыли по ходу воспроизведения: плеер узнает, что за ней идёт (следующая глава),
    // а если звучала другая глава Библии, переключится на эту
    engine.sync(this.trackValue)
  }

  toggle() {
    engine.playTrack(this.trackValue)
  }
}
