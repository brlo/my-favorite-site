import { Controller } from '@hotwired/stimulus'
import { shareLink } from '../lib/tools'

export default class extends Controller {
  share(event) {
    event.preventDefault()
    shareLink()
  }
}
