import { Controller } from "@hotwired/stimulus"
import Cookies from "lib/cookies"

export default class extends Controller {
  static values = {
    audioLink: String,
  }

  connect() {
    this.audioContainer = document.getElementById('audio-player');
    this.isShown = false;
    this.isPlaing = false;

    if (Cookies.get('autoplay') == '1') {
      this.showAndPlay()
    }
  }

  play() {
    // ничего не делаем, если нет плеера
    if (!this.audioEl) return;
    this.isPlaing = true;
    Cookies.set('autoplay', '1')
  };

  stop() {
    // ничего не делаем, если нет плеера
    if (!this.audioEl) return;
    this.isPlaing = false;
    Cookies.set('autoplay', '0')
  };

  // toggle: Play/Stop
  toggle() {
    if (this.isPlaing == true) {
      this.stop();
    } else {
      this.play();
    };
  };

  showAndPlay() {
    // если элемент уже показан, то ничего не делаем
    if (this.audioEl) return;

    // создали элемент
    if (this.audioLinkValue) {
      this.audioContainer.innerHTML = "<audio controls>test</audio><a class='copy' href='https://jesus-portal.ru/life/video/audiobibliya/'>© материал православного портала \"Иисус\"</a>";
    } else {
      this.audioContainer.innerHTML = "<audio controls>test</audio>";
    }
    // запомнили html-элемент плеера
    this.audioEl = this.audioContainer.querySelector('audio');
    this.audioEl.src = this.audioLinkValue;

    // КОГДА АУДИО КОНЧИЛОСЬ - ЧТО ДЕЛАТЬ:
    this.audioEl.onplay = this.play.bind(this);
    this.audioEl.onpause = this.stop.bind(this);
    this.audioEl.onended = this.playNext.bind(this);

    // показали
    this.isShown = true;

    // воспроизвели
    this.audioEl.play();
  };

  hide() {
    // остановили воспроизведение
    this.stop();
    // скрыли элемент
    this.audioEl = undefined;
    this.audioContainer.innerHTML = '';
    this.isShown = false;
  };

  // Переключить видимость audio-тэга
  playNext() {
    if (this.isShown == true) {
      const nextPage = document.getElementById('next-page-link');
      if (nextPage && nextPage.href) {
        Cookies.set('autoplay', '1');
        Turbo.visit(nextPage.href);
      } else {
        this.hide();
      }
    }
  }

  // Переключить видимость audio-тэга
  toggleVision() {
    if (this.isShown == true) {
      this.hide();
    } else {
      this.showAndPlay();
    };
  };
}
