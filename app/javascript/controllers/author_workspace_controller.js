import { Controller } from "@hotwired/stimulus"

// Перетаскивание пунктов меню в кабинете автора.
// Пока тащим — показываем пункт уже на новом месте (с пунктирной рамкой),
// а «призрак» под курсором делаем почти прозрачным. Сохраняем перемещение
// только при отпускании; при отмене возвращаем пункт на место.
export default class extends Controller {
  static targets = ["row", "moveForm"]
  static values = { moveUrl: String }

  connect() {
    this.dragged = null
    this.draggedNode = null
    this.lastDrop = null
    this.dropped = false
    this.originalParent = null
    this.originalNextSibling = null
    this.firstPositions = null
    this.flipGeneration = 0
  }

  dragStart(event) {
    const row = event.target.closest("[data-author-workspace-target='row']")
    if (!row) return

    this.dragged = row
    this.draggedNode = row.closest(".aw-node")
    if (!this.draggedNode) return

    this.originalParent = this.draggedNode.parentNode
    this.originalNextSibling = this.draggedNode.nextSibling
    this.lastDrop = null
    this.dropped = false
    this.clearFlip()

    this.draggedNode.classList.add("is-dragging")
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", row.dataset.itemId)

    // Тянем за ручку, но «призрак» показываем целой плашкой и делаем его
    // почти прозрачным, чтобы пункт на новом месте (с пунктирной рамкой)
    // читался как основной.
    this.setDragGhost(row, event)
    this.clearMarkers()
  }

  dragEnd() {
    if (this.draggedNode) this.draggedNode.classList.remove("is-dragging")

    // Если отпустили не над меню (или нажали Esc), возвращаем пункт на место
    if (!this.dropped && this.draggedNode && this.originalParent) {
      this.originalParent.insertBefore(this.draggedNode, this.originalNextSibling)
    }

    this.clearMarkers()
    this.clearFlip()
    this.dragged = null
    this.draggedNode = null
    this.lastDrop = null
    this.dropped = false
    this.originalParent = null
    this.originalNextSibling = null
  }

  dragOver(event) {
    if (!this.dragged) return

    const row = event.target.closest("[data-author-workspace-target='row']")

    // Над пустым местом меню или над самим переносимым пунктом разрешаем
    // отпустить в последнюю подсчитанную позицию.
    if (!row || !this.canDropOn(row)) {
      if (this.lastDrop) {
        event.preventDefault()
        event.dataTransfer.dropEffect = "move"
      }
      return
    }

    event.preventDefault()
    event.dataTransfer.dropEffect = "move"

    const position = this.positionForRow(row, event)
    this.lastDrop = {targetId: row.dataset.itemId, position}
    this.previewMove(row, position)
    this.clearMarkers()
  }

  drop(event) {
    if (!this.dragged) return

    let targetId
    let position
    const row = event.target.closest("[data-author-workspace-target='row']")

    if (row && this.canDropOn(row)) {
      targetId = row.dataset.itemId
      position = this.positionForRow(row, event)
      this.lastDrop = {targetId, position}
      this.previewMove(row, position)
    } else if (this.lastDrop) {
      targetId = this.lastDrop.targetId
      position = this.lastDrop.position
    } else {
      return
    }

    event.preventDefault()
    this.dropped = true
    if (this.draggedNode) this.draggedNode.classList.remove("is-dragging")

    const itemId = this.dragged.dataset.itemId
    this.clearMarkers()
    this.submitMove(itemId, targetId, position)
  }

  setDragGhost(row, event) {
    const rect = row.getBoundingClientRect()
    const ghost = row.cloneNode(true)
    ghost.style.position = "fixed"
    ghost.style.top = "-1000px"
    ghost.style.left = "-1000px"
    ghost.style.width = `${rect.width}px`
    ghost.style.opacity = "0.15"
    ghost.style.pointerEvents = "none"
    document.body.appendChild(ghost)

    try {
      event.dataTransfer.setDragImage(ghost, event.clientX - rect.left, event.clientY - rect.top)
    } catch (_) {
      // в старых браузерах останется системный «призрак»
    }

    setTimeout(() => ghost.remove(), 0)
  }

  canDropOn(row) {
    if (!this.dragged || !this.draggedNode || row === this.dragged) return false

    return !this.draggedNode.contains(row)
  }

  positionForRow(row, event) {
    const rect = row.getBoundingClientRect()
    return event.clientY < rect.top + rect.height / 2 ? "before" : "after"
  }

  // Переставляем DOM-узел сразу, чтобы во время перетаскивания было видно,
  // где пункт окажется после отпускания.
  previewMove(row, position) {
    const targetNode = row.closest(".aw-node")
    if (!targetNode || targetNode === this.draggedNode) return

    const targetList = targetNode.parentNode
    if (!targetList) return

    if (position === "before" && this.draggedNode.nextSibling === targetNode) return
    if (position === "after" && this.draggedNode.previousSibling === targetNode) return

    this.captureFirstPositions()
    const reference = position === "after" ? targetNode.nextSibling : targetNode
    targetList.insertBefore(this.draggedNode, reference)
    this.playFlip()
  }

  // FLIP: запоминаем, где строки были до перемещения...
  captureFirstPositions() {
    this.flipGeneration += 1
    this.firstPositions = new Map()

    this.rowTargets.forEach((row) => {
      if (!row.isConnected || this.isDraggedRow(row)) return

      clearTimeout(row._flipTimeout)
      row.style.transition = "none"
      row.style.transform = ""
      this.firstPositions.set(row, row.getBoundingClientRect())
    })
  }

  // ...и плавно возвращаем их из старой позиции в новую
  playFlip() {
    if (!this.firstPositions) return
    const reduceMotion = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches
    if (reduceMotion) {
      this.firstPositions = null
      return
    }

    const generation = this.flipGeneration
    this.firstPositions.forEach((first, row) => {
      if (!row.isConnected || this.isDraggedRow(row)) return

      const last = row.getBoundingClientRect()
      const dx = first.left - last.left
      const dy = first.top - last.top

      if (Math.abs(dx) < 0.5 && Math.abs(dy) < 0.5) {
        row.style.transition = ""
        return
      }

      row.style.transition = "none"
      row.style.transform = `translate(${dx}px, ${dy}px)`

      requestAnimationFrame(() => {
        if (generation !== this.flipGeneration) return
        row.style.transition = "transform 150ms cubic-bezier(0.2, 0.7, 0.3, 1)"
        row.style.transform = ""
      })

      row._flipTimeout = setTimeout(() => {
        row.style.transition = ""
      }, 200)
    })

    this.firstPositions = null
  }

  clearFlip() {
    this.flipGeneration += 1

    this.rowTargets.forEach((row) => {
      clearTimeout(row._flipTimeout)
      if (!row.isConnected) return
      row.style.transition = ""
      row.style.transform = ""
    })

    this.firstPositions = null
  }

  isDraggedRow(row) {
    return row === this.dragged || (this.draggedNode && this.draggedNode.contains(row))
  }

  clearMarkers() {
    this.rowTargets.forEach((row) => row.classList.remove("drop-before", "drop-after"))
  }

  submitMove(itemId, targetId, position) {
    const form = this.moveFormTarget
    form.action = this.moveUrlValue.replace("__ID__", itemId)
    form.querySelector("[name='target_id']").value = targetId
    form.querySelector("[name='position']").value = position
    form.requestSubmit()
  }
}
