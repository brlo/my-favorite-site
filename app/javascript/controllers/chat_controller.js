import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"
import { Editor, StarterKit } from "tiptap/tiptap_bundle"
import axios from "lib/axios"

// Чат. HTML сообщений приходит с сервера (и по ActionCable) одинаковым для всех зрителей,
// а подписи, время и доступные кнопки (по правам зрителя) расставляются здесь, в hydrate().
// Права всё равно проверяются на сервере.
export default class extends Controller {
  static targets = ["feed", "list", "more", "message", "editor", "send", "wait", "error",
                    "context", "contextText", "picker", "composer", "postingSwitch"]
  static values = {
    roomId: Number,
    memberId: Number,
    staff: Boolean,
    postingClosed: Boolean,
    roomUrl: String,
    verified: Boolean,
    locale: String,
    messagesUrl: String,
    translateLangs: Object,
    waitSeconds: Number,
    editWindow: Number,
    maxEdits: Number,
    reactions: Array,
    myReactions: Object,
    hasMore: Boolean,
    i18n: Object
  }

  // targetConnected-колбэки могут сработать раньше connect(), поэтому состояние — здесь
  initialize() {
    this.myReactions = new Map()
    this.composeMode = null // { type: 'reply' | 'edit', id }
    this.loading = false
    this.waitLeft = 0
  }

  connect() {
    this.mergeMyReactions(this.myReactionsValue)
    this.messageTargets.forEach(el => this.hydrate(el))
    this.scrollToBottom()

    if (this.hasEditorTarget) this.createEditor()
    if (this.waitSecondsValue > 0) this.startWait(this.waitSecondsValue)

    this.subscribe()

    // кнопка "редактировать" должна исчезать по истечении суток
    this.clock = setInterval(() => this.messageTargets.forEach(el => this.updateActions(el)), 60_000)
    this.closePickerOnClick = (e) => {
      if (this.hasPickerTarget && !this.pickerTarget.contains(e.target) && !e.target.closest('[data-act="react"]')) {
        this.pickerTarget.hidden = true
      }
    }
    document.addEventListener("click", this.closePickerOnClick)
  }

  disconnect() {
    clearInterval(this.clock)
    clearInterval(this.waitTimer)
    document.removeEventListener("click", this.closePickerOnClick)
    this.editor?.destroy()
    this.subscription?.unsubscribe()
    this.consumer?.disconnect()
  }

  // ---------- редактор ----------

  createEditor() {
    const isTouch = window.matchMedia("(pointer: coarse)").matches
    this.editor = new Editor({
      element: this.editorTarget,
      extensions: [
        StarterKit.configure({
          heading: false, bulletList: false, orderedList: false, listItem: false, listKeymap: false,
          codeBlock: false, code: false, horizontalRule: false, italic: false,
          // ссылки разрешены только админам (сервер всё равно вырежет их у остальных)
          link: this.staffValue ? { openOnClick: false, autolink: true } : false
        })
      ],
      content: "",
      editorProps: {
        attributes: { class: "chat__editor-content" },
        // Enter — отправить, Shift+Enter — новая строка. На телефонах Enter — новая строка.
        handleKeyDown: (view, event) => {
          if (event.key === "Enter" && !event.shiftKey && !event.isComposing && !isTouch) {
            event.preventDefault()
            this.submit()
            return true
          }
          if (event.key === "Escape" && this.composeMode) {
            this.cancelContext()
            return true
          }
          return false
        }
      }
    })
  }

  format(event) {
    const command = event.currentTarget.dataset.command
    this.editor?.chain().focus()[command]().run()
  }

  setLink() {
    const previous = this.editor.getAttributes("link").href
    const url = window.prompt("URL", previous || "https://")
    if (url === null) return
    if (url === "") {
      this.editor.chain().focus().extendMarkRange("link").unsetLink().run()
    } else {
      this.editor.chain().focus().extendMarkRange("link").setLink({ href: url }).run()
    }
  }

  // ---------- отправка ----------

  async submit() {
    if (!this.editor || this.sending || this.editor.isEmpty || !this.canWrite) return
    const editing = this.composeMode?.type === "edit"
    if (!editing && this.waitLeft > 0) return

    this.sending = true
    this.showError(null)
    const body = this.editor.getJSON()

    try {
      let response
      if (editing) {
        response = await axios.patch(`${this.messagesUrlValue}/${this.composeMode.id}`, { body })
      } else {
        const replyToId = this.composeMode?.type === "reply" ? this.composeMode.id : null
        response = await axios.post(this.messagesUrlValue, { body, reply_to_id: replyToId })
      }
      const data = response.data
      this.upsert(data.html)
      this.editor.commands.clearContent()
      this.cancelContext(false)

      if (!editing) {
        this.scrollToBottom()
        this.element.querySelector(".chat-greeting")?.remove()
        if (data.retry_after > 0) this.startWait(data.retry_after)
      }
      this.adoptMember(data.member_id)
    } catch (error) {
      const data = error.response?.data || {}
      this.adoptMember(data.member_id)
      if (error.response?.status === 429 && data.retry_after) this.startWait(data.retry_after)
      this.showError(data.error || error.message)
    } finally {
      this.sending = false
    }
  }

  // ---------- общий рубильник ----------

  async togglePosting() {
    try {
      const { data } = await axios.patch(this.roomUrlValue, { posting_closed: !this.postingClosedValue })
      this.postingClosedValue = data.posting_closed
    } catch (error) {
      this.showError(error.response?.data?.error || error.message)
    }
  }

  postingClosedValueChanged() {
    const closed = this.postingClosedValue
    this.element.classList.toggle("chat--closed", closed)
    if (this.hasPostingSwitchTarget) {
      this.postingSwitchTarget.textContent = this.t(closed ? "open_chat" : "close_chat")
    }
    if (closed && !this.staffValue) this.cancelContext()
    this.messageTargets.forEach(el => this.updateActions(el))
  }

  // может ли зритель сейчас писать
  get canWrite() {
    return this.hasEditorTarget && (!this.postingClosedValue || this.staffValue)
  }

  memberIdValueChanged() {
    this.messageTargets.forEach(el => this.updateActions(el))
  }

  // Только что созданный гость: переподключаемся, чтобы получать свои скрытые сообщения
  adoptMember(id) {
    if (!id || id === this.memberIdValue) return
    this.memberIdValue = id
    this.consumer?.connection.reopen()
  }

  // Обратный отсчёт до следующего сообщения
  startWait(seconds) {
    clearInterval(this.waitTimer)
    this.waitLeft = seconds
    const tick = () => {
      if (!this.hasWaitTarget) return
      if (this.waitLeft <= 0) {
        clearInterval(this.waitTimer)
        this.waitTarget.hidden = true
        this.updateSendButton()
        return
      }
      const m = Math.floor(this.waitLeft / 60)
      const s = String(this.waitLeft % 60).padStart(2, "0")
      this.waitTarget.textContent = `${this.t("wait")} ${m}:${s}`
      this.waitTarget.hidden = false
      this.updateSendButton()
      this.waitLeft -= 1
    }
    tick()
    this.waitTimer = setInterval(tick, 1000)
  }

  updateSendButton() {
    if (!this.hasSendTarget) return
    const editing = this.composeMode?.type === "edit"
    this.sendTarget.disabled = !editing && this.waitLeft > 0
    this.sendTarget.textContent = editing ? this.t("save") : this.t("send")
  }

  showError(text) {
    if (!this.hasErrorTarget) return
    this.errorTarget.hidden = !text
    this.errorTarget.textContent = text || ""
  }

  // ---------- ответ / редактирование ----------

  startReply(event) {
    const el = event.target.closest(".chat-msg")
    const nick = el.querySelector(".chat-msg__nick")?.textContent
    const text = el.querySelector(".chat-msg__body")?.textContent.trim().slice(0, 80)
    this.setContext({ type: "reply", id: el.dataset.id }, `${this.t("replying_to")} ${nick}: ${text}`)
    // ответ админа на скрытое сообщение увидят только автор и админы
    if (this.staffValue && el.dataset.status === "pending") {
      this.contextTextTarget.textContent += ` (${this.t("reply_private_hint")})`
    }
    this.editor?.commands.focus()
  }

  async startEdit(event) {
    const el = event.target.closest(".chat-msg")
    try {
      const { data } = await axios.get(`${this.messagesUrlValue}/${el.dataset.id}`)
      this.setContext({ type: "edit", id: el.dataset.id }, this.t("editing"))
      this.editor.commands.setContent(data.body)
      this.editor.commands.focus("end")
    } catch (error) {
      this.showError(error.response?.data?.error || error.message)
    }
  }

  setContext(context, text) {
    if (!this.hasContextTarget) return
    if (this.composeMode?.type === "edit" && context.type !== "edit") this.editor.commands.clearContent()
    this.composeMode = context
    this.contextTextTarget.textContent = text
    this.contextTarget.hidden = false
    this.updateSendButton()
  }

  cancelContext(clear = true) {
    if (clear && this.composeMode?.type === "edit") this.editor?.commands.clearContent()
    this.composeMode = null
    if (this.hasContextTarget) this.contextTarget.hidden = true
    this.updateSendButton()
  }

  // ---------- действия с сообщением ----------

  async destroy(event) {
    const el = event.target.closest(".chat-msg")
    if (!window.confirm(this.t("confirm_delete"))) return
    try {
      await axios.delete(`${this.messagesUrlValue}/${el.dataset.id}`)
      el.remove()
    } catch (error) {
      this.showError(error.response?.data?.error || error.message)
    }
  }

  async approve(event) {
    const el = event.target.closest(".chat-msg")
    try {
      const { data } = await axios.post(`${this.messagesUrlValue}/${el.dataset.id}/approve`)
      this.upsert(data.html)
    } catch (error) {
      this.showError(error.response?.data?.error || error.message)
    }
  }

  async translate(event) {
    const button = event.currentTarget
    const el = button.closest(".chat-msg")
    const box = el.querySelector(".chat-msg__translation")

    if (!box.hidden) {
      box.hidden = true
      button.textContent = this.t("translate")
      return
    }
    if (box.innerHTML.trim()) {
      box.hidden = false
      button.textContent = this.t("show_original")
      return
    }

    button.disabled = true
    button.textContent = this.t("translating")
    try {
      const { data } = await axios.post(`${this.messagesUrlValue}/${el.dataset.id}/translate`, { to: this.localeValue })
      box.innerHTML = data.html // HTML очищен на сервере
      box.lang = this.localeValue
      box.hidden = false
      button.textContent = this.t("show_original")
    } catch (error) {
      button.textContent = this.t("translate")
      this.showError(error.response?.data?.error || error.message)
    } finally {
      button.disabled = false
    }
  }

  toggleReactionPicker(event) {
    const el = event.target.closest(".chat-msg")
    const picker = this.pickerTarget
    if (!picker.hidden && this.pickerFor === el.dataset.id) {
      picker.hidden = true
      return
    }
    this.pickerFor = el.dataset.id
    const rect = event.currentTarget.getBoundingClientRect()
    const hostRect = this.element.getBoundingClientRect()
    picker.style.top = `${rect.bottom - hostRect.top + 4}px`
    picker.style.left = `${Math.max(0, rect.left - hostRect.left - 60)}px`
    picker.hidden = false
  }

  pickReaction(event) {
    this.pickerTarget.hidden = true
    this.sendReaction(this.pickerFor, event.currentTarget.dataset.emoji)
  }

  react(event) {
    const el = event.target.closest(".chat-msg")
    this.sendReaction(el.dataset.id, event.currentTarget.dataset.emoji)
  }

  async sendReaction(id, emoji) {
    try {
      const { data } = await axios.post(`${this.messagesUrlValue}/${id}/react`, { emoji })
      const mine = this.myReactions.get(String(id)) || new Set()
      data.active ? mine.add(emoji) : mine.delete(emoji)
      this.myReactions.set(String(id), mine)
      this.renderReactions(id, data.reactions)
    } catch (error) {
      this.showError(error.response?.data?.error || error.message)
    }
  }

  jumpTo(event) {
    const target = document.getElementById(`chat-msg-${event.currentTarget.dataset.targetId}`)
    if (!target) return
    event.preventDefault()
    target.scrollIntoView({ behavior: "smooth", block: "center" })
    target.classList.add("chat-msg--flash")
    setTimeout(() => target.classList.remove("chat-msg--flash"), 1500)
  }

  // ---------- лента ----------

  onScroll() {
    if (this.feedTarget.scrollTop < 80 && this.hasMoreValue && !this.loading) this.loadMore()
  }

  async loadMore() {
    const first = this.messageTargets[0]
    if (!first || this.loading) return
    this.loading = true
    try {
      const { data } = await axios.get(this.messagesUrlValue, { params: { before: first.dataset.id } })
      this.mergeMyReactions(data.my_reactions)
      const feed = this.feedTarget
      const prevHeight = feed.scrollHeight
      this.listTarget.insertAdjacentHTML("afterbegin", data.html)
      // новые элементы гидрирует messageTargetConnected
      feed.scrollTop += feed.scrollHeight - prevHeight
      this.hasMoreValue = data.has_more
      this.moreTarget.hidden = !data.has_more
    } finally {
      this.loading = false
    }
  }

  // после переподключения подтягиваем пропущенное
  async refreshLatest() {
    try {
      const { data } = await axios.get(this.messagesUrlValue)
      this.mergeMyReactions(data.my_reactions)
      const tmp = document.createElement("div")
      tmp.innerHTML = data.html
      tmp.querySelectorAll(".chat-msg").forEach(el => this.upsert(el.outerHTML))
    } catch (_) { /* не критично */ }
  }

  messageTargetConnected(el) {
    this.hydrate(el)
  }

  upsert(html) {
    const tmp = document.createElement("div")
    tmp.innerHTML = html.trim()
    const fresh = tmp.firstElementChild
    if (!fresh) return
    const existing = document.getElementById(fresh.id)
    if (existing) {
      existing.replaceWith(fresh)
      return
    }
    const nearBottom = this.isNearBottom()
    const id = Number(fresh.dataset.id)
    const next = this.messageTargets.find(m => Number(m.dataset.id) > id)
    next ? next.before(fresh) : this.listTarget.append(fresh)
    if (nearBottom) this.scrollToBottom()
  }

  remove(id) {
    document.getElementById(`chat-msg-${id}`)?.remove()
  }

  isNearBottom() {
    const f = this.feedTarget
    return f.scrollHeight - f.scrollTop - f.clientHeight < 120
  }

  scrollToBottom() {
    if (this.hasFeedTarget) this.feedTarget.scrollTop = this.feedTarget.scrollHeight
  }

  // ---------- ActionCable ----------

  subscribe() {
    this.consumer = createConsumer()
    let connectedOnce = false
    this.subscription = this.consumer.subscriptions.create(
      { channel: "ChatChannel", room_id: this.roomIdValue },
      {
        connected: () => {
          if (connectedOnce) this.refreshLatest()
          connectedOnce = true
        },
        received: (data) => this.received(data)
      }
    )
  }

  received(data) {
    switch (data.type) {
      case "upsert": this.upsert(data.html); break
      case "remove": this.remove(data.id); break
      case "reactions": this.renderReactions(data.id, data.reactions); break
      case "room": this.postingClosedValue = data.posting_closed; break
    }
  }

  // ---------- отрисовка ----------

  hydrate(el) {
    el.querySelectorAll("[data-i18n]").forEach(n => { n.textContent = this.t(n.dataset.i18n) })
    el.querySelectorAll("[data-i18n-title]").forEach(n => { n.title = this.t(n.dataset.i18nTitle) })

    // ссылки на профиль — в текущей локали интерфейса
    el.querySelectorAll("a[href*='/chat/members/']").forEach(a => {
      a.setAttribute("href", a.getAttribute("href").replace(/^\/[^/]+\/chat\//, `/${this.localeValue}/chat/`))
    })

    const time = el.querySelector("time")
    if (time) {
      const date = new Date(time.getAttribute("datetime"))
      const sameDay = date.toDateString() === new Date().toDateString()
      const opts = sameDay ? { hour: "2-digit", minute: "2-digit" }
                           : { day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" }
      time.textContent = new Intl.DateTimeFormat(this.localeValue, opts).format(date)
      time.title = date.toLocaleString(this.localeValue)
    }

    this.markMyReactions(el)
    this.updateActions(el)
  }

  updateActions(el) {
    const d = el.dataset
    const isText = d.kind === "text"
    const mine = this.memberIdValue > 0 && Number(d.authorId) === this.memberIdValue
    const age = Date.now() / 1000 - Number(d.createdAt)
    const canWrite = this.canWrite
    const langs = this.translateLangsValue
    const from = langs[d.lang], to = langs[this.localeValue]

    const allowed = {
      reply: canWrite && isText,
      react: this.verifiedValue && isText,
      translate: Boolean(from && to && from !== to),
      edit: canWrite && mine && isText && age < this.editWindowValue && Number(d.edits) < this.maxEditsValue,
      delete: mine || this.staffValue,
      approve: this.staffValue && d.status === "pending"
    }
    el.querySelectorAll("[data-act]").forEach(b => { b.hidden = !allowed[b.dataset.act] })
    el.querySelectorAll(".chat-reaction").forEach(b => { b.disabled = !this.verifiedValue })
  }

  renderReactions(id, summary) {
    const el = document.getElementById(`chat-msg-${id}`)
    if (!el) return
    const box = el.querySelector(".chat-msg__reactions")
    box.replaceChildren()
    Object.entries(summary || {}).forEach(([emoji, count]) => {
      const b = document.createElement("button")
      b.type = "button"
      b.className = "chat-reaction"
      b.dataset.emoji = emoji
      b.dataset.action = "chat#react"
      b.disabled = !this.verifiedValue
      b.append(`${emoji} `)
      const span = document.createElement("span")
      span.textContent = count
      b.append(span)
      box.append(b)
    })
    this.markMyReactions(el)
  }

  markMyReactions(el) {
    const mine = this.myReactions.get(el.dataset.id) || new Set()
    el.querySelectorAll(".chat-reaction").forEach(b => b.classList.toggle("chat-reaction--mine", mine.has(b.dataset.emoji)))
  }

  mergeMyReactions(obj) {
    Object.entries(obj || {}).forEach(([id, list]) => this.myReactions.set(String(id), new Set(list)))
  }

  t(key) {
    return this.i18nValue[key] || key
  }
}
