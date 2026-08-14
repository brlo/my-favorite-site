import { Controller } from "@hotwired/stimulus"
import notifications from "services/notifications_service"
import { copyText } from "lib/tools"
import { t, t_cont } from "lib/localization"

export default class extends Controller {
  static targets = ['content']

  copy(event) {
    const text = this.contentTarget.textContent.trim()
    copyText(text)
    notifications.add(`<t>${t('copyTitle')}:</t> ${text.slice(0,30)}...`)
  }
}
