import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  changeLanguage(event) {
    console.log('!!!!!!')
    const selectedLang = event.target.value
    const currentUrl = new URL(window.location.href)
    currentUrl.searchParams.set('lang_to', selectedLang)

    Turbo.visit(currentUrl.toString())
  }
}
