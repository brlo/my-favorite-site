import { Controller } from "@hotwired/stimulus"

// Сворачивает содержимое секций статьи: у каждого h2 есть стрелка,
// а клик по заголовку скрывает/показывает всё до следующего h2.
// В отличие от содержания и похожих материалов, секции h2 не имеют
// автосворачивания: все раскрыты по умолчанию, свернуть можно только вручную.
export default class extends Controller {
  connect() {
    this.sections = new Map()
    this.headings = Array.from(this.element.children).filter((el) => el.tagName === "H2")

    this.headings.forEach((heading) => this.prepare(heading))

    this.handleSectionClick = this.handleSectionClick.bind(this)
    this.handleLinkClick = this.handleLinkClick.bind(this)
    this.handleHashChange = this.handleHashChange.bind(this)
    this.element.addEventListener("click", this.handleSectionClick)
    document.addEventListener("click", this.handleLinkClick, true)
    window.addEventListener("hashchange", this.handleHashChange)

    this.openHash()
  }

  disconnect() {
    this.element.removeEventListener("click", this.handleSectionClick)
    document.removeEventListener("click", this.handleLinkClick, true)
    window.removeEventListener("hashchange", this.handleHashChange)
  }

  prepare(heading) {
    const nodes = []
    let next = heading.nextElementSibling
    while (next && next.tagName !== "H2") {
      nodes.push(next)
      next = next.nextElementSibling
    }
    if (nodes.length === 0) return

    this.sections.set(heading, nodes)
    heading.classList.add("section-collapsible")

    if (heading.querySelector(":scope > .section-toggle")) return

    const toggle = document.createElement("button")
    toggle.type = "button"
    toggle.className = "section-toggle"
    toggle.setAttribute("aria-expanded", heading.classList.contains("section-collapsed") ? "false" : "true")
    toggle.setAttribute("aria-label", heading.textContent.trim())
    toggle.innerHTML =
      '<svg class="section-toggle-chevron" width="14" height="14" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 6l5 5 5-5"/></svg>'
    heading.append(toggle)
  }

  handleSectionClick(event) {
    const heading = event.target.closest("h2.section-collapsible")
    if (!heading || !this.element.contains(heading)) return
    if (event.target.closest("a")) return
    this.toggleSection(heading)
  }

  toggleSection(heading) {
    this.setExpanded(heading, heading.classList.contains("section-collapsed"))
  }

  setExpanded(heading, expanded) {
    const toggle = heading.querySelector(".section-toggle")
    if (!toggle) return

    heading.classList.toggle("section-collapsed", !expanded)
    toggle.setAttribute("aria-expanded", String(expanded))
    this.sections.get(heading)?.forEach((node) => node.classList.toggle("section-hidden", !expanded))
  }

  handleLinkClick(event) {
    const link = event.target.closest('a[href*="#"]')
    if (!link || link.classList.contains("copy-anchor")) return

    const target = this.targetFromHash(link.hash)
    if (target && this.element.contains(target)) this.openSectionFor(target)
  }

  handleHashChange() {
    this.openHash()
  }

  openHash() {
    const target = this.targetFromHash(window.location.hash)
    if (target && this.element.contains(target)) this.openSectionFor(target)
  }

  openSectionFor(target) {
    const heading = this.headingFor(target)
    if (heading) this.setExpanded(heading, true)
  }

  headingFor(node) {
    let section = null
    for (const heading of this.headings) {
      const isSame = heading === node
      const isBefore = heading.compareDocumentPosition(node) & Node.DOCUMENT_POSITION_FOLLOWING
      if (isSame || isBefore) section = heading
      else break
    }
    return section
  }

  targetFromHash(hash) {
    if (!hash || hash === "#") return null
    try {
      return document.getElementById(decodeURIComponent(hash.slice(1)))
    } catch {
      return null
    }
  }
}
