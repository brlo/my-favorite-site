// app/javascript/controllers/bbx_select_controller.js

// EXAMPLES:
// <div data-controller="bbx-select">
//   <select data-bbx-select-target="select" name="locale" multiple>
//     <optgroup label="🇪🇺 Европейские">
//       <option value="en" data-progress="100">English</option>
//       <option value="fr" data-progress="85">Français</option>
//       <option value="de" data-progress="70">Deutsch</option>
//     </optgroup>
//     <optgroup label="🌏 Азиатские">
//       <option value="ja" data-progress="30">日本語</option>
//       <option value="ko" data-progress="15" selected>한국어</option>
//     </optgroup>
//   </select>
//   <div data-bbx-select-target="custom"></div>
// </div>

// <div data-controller="bbx-select"
//      data-bbx-select-action-value="navigate"
//      data-bbx-select-navigate-path-value="<%= switch_locale_path %>">

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "custom"]
  static values = {
    action: String,
    navigatePath: String,
    placeholder: { type: String, default: '' },
    direction: { type: String, default: 'down' },
    pathPositionReplace: Number,
  }

  connect() {
    this.render()
    this.selectTarget.addEventListener('change', this.update.bind(this))

    document.addEventListener('click', this.handleOutsideClick.bind(this))
  }

  disconnect() {
    this.selectTarget.removeEventListener('change', this.update.bind(this))
    document.removeEventListener('click', this.handleOutsideClick.bind(this))
  }

  render() {
    const select = this.selectTarget
    const hasGroups = select.querySelector('optgroup')
    const isMultiple = select.hasAttribute('multiple')
    const selectedOptions = Array.from(select.selectedOptions)
    const directionClass = this.directionValue === 'up' ? 'bbx-dropup' : ''

    let optionsHTML = ''

    if (hasGroups) {
      select.querySelectorAll('optgroup').forEach(group => {
        const options = group.querySelectorAll('option')
        optionsHTML += `
          <div class="bbx-group">
            <div class="bbx-group-label">${group.label}</div>
            ${Array.from(options).map((opt) => this.optionHTML(opt, isMultiple)).join('')}
          </div>
        `
      })
    } else {
      optionsHTML = Array.from(select.options).map((opt) =>
        this.optionHTML(opt, isMultiple)
      ).join('')
    }

    this.customTarget.innerHTML = `
      <div class="bbx-select ${directionClass}" data-action="click->bbx-select#toggle">
        <div class="bbx-selected">
          ${this.selectedHTML(selectedOptions)}
          <span class="bbx-arrow">▾</span>
        </div>
        <div class="bbx-dropdown">
          ${optionsHTML}
        </div>
      </div>
    `
  }

  selectedHTML(options) {
    const select = this.selectTarget
    const selectedOptions = Array.from(select.selectedOptions)

    // Если ничего не выбрано и есть placeholder
    if (selectedOptions.length === 0 && this.placeholderValue) {
      return `
        <div class="bbx-selected-content">
          <span class="bbx-selected-label bbx-placeholder">${this.placeholderValue}</span>
        </div>
      `
    }

    const isMultiple = this.selectTarget.hasAttribute('multiple')
    if (isMultiple) {
      // For multiple: show all selected labels separated by comma
      // const labels = options.map(opt => opt.text).join(', ')
      let labels = options[0].text
      if (options[1]) labels = labels + ', ...'
      return `
        <div class="bbx-selected-content">
          <span class="bbx-selected-label">${labels || 'Select options'}</span>
        </div>
      `
    } else {
      // Original single select behavior
      const option = options[0]
      const progress = parseInt(option?.dataset.progress) || 0
      const hasProgress = option?.dataset.progress !== undefined
      const color = this.color(progress)
      const textColor = progress > 50 ? 'dark' : ''

      return `
        <div class="bbx-selected-content">
          <span class="bbx-selected-label">${option?.text || ''}</span>
          ${hasProgress ? `
            <div class="bbx-progress selected">
              <div class="bbx-bar" style="width: ${progress}%; background: ${color};"></div>
              <span class="bbx-percent ${textColor}">${progress}%</span>
            </div>
          ` : ''}
        </div>
      `
    }
  }

  optionHTML(option, isMultiple) {
    const progress = parseInt(option.dataset.progress) || 0
    const isSelected = option.selected
    const hasProgress = option.dataset.progress !== undefined
    const color = this.color(progress)
    const textColor = progress > 50 ? 'dark' : ''

    return `
      <div class="bbx-option ${isSelected ? 'selected' : ''}"
           data-value="${option.value}"
           data-action="click->bbx-select#select">
        <span>${option.text}</span>
        ${isMultiple ? `<span class="bbx-check">${isSelected ? '✓' : ''}</span>` : ''}
        ${hasProgress ? `
          <div class="bbx-progress">
            <div class="bbx-bar" style="width: ${progress}%; background: ${color};"></div>
            <span class="bbx-percent ${textColor}">${progress}%</span>
          </div>
        ` : ''}
      </div>
    `
  }

  color(progress) {
    if (progress >= 80) return '#22c55e'
    if (progress >= 50) return '#eab308'
    if (progress >= 20) return '#f97316'
    return '#ef4444'
  }

  toggle(event) {
    event.stopPropagation()
    const dropdown = this.customTarget.querySelector('.bbx-dropdown')
    const select = this.customTarget.querySelector('.bbx-select')

    dropdown.classList.toggle('open')
    select.classList.toggle('open')

    if (dropdown.classList.contains('open')) {
      this.calculatePosition()
    }
  }

  select(event) {
    event.stopPropagation()
    const value = event.currentTarget.dataset.value
    const isMultiple = this.selectTarget.hasAttribute('multiple')

    if (isMultiple) {
      // Toggle selection for multiple
      const option = this.selectTarget.querySelector(`option[value="${value}"]`)
      if (option) {
        option.selected = !option.selected
      }
    } else {
      // Single select behavior
      this.selectTarget.value = value
    }

    this.selectTarget.dispatchEvent(new Event('change', { bubbles: true }))

    this.update()
    this.handleAction()

    // Only close dropdown for single select
    if (!isMultiple) {
      this.close()
    }
  }

  update() {
    const select = this.selectTarget
    const isMultiple = select.hasAttribute('multiple')
    const selectedOptions = Array.from(select.selectedOptions)

    // Update selected display
    const selectedEl = this.customTarget.querySelector('.bbx-selected')
    if (selectedEl) {
      const arrow = selectedEl.querySelector('.bbx-arrow')
      selectedEl.innerHTML = `
        ${this.selectedHTML(selectedOptions)}
        ${arrow ? arrow.outerHTML : '<span class="bbx-arrow">▾</span>'}
      `
    }

    // Update option classes and checkmarks
    this.customTarget.querySelectorAll('.bbx-option').forEach((el) => {
      const isSelected = selectedOptions.some(opt => opt.value === el.dataset.value)
      el.classList.toggle('selected', isSelected)

      // Update checkmark for multiple
      if (isMultiple) {
        let check = el.querySelector('.bbx-check')
        if (isSelected && !check) {
          check = document.createElement('span')
          check.className = 'bbx-check'
          check.textContent = '✓'
          el.appendChild(check)
        } else if (!isSelected && check) {
          check.remove()
        }
      }
    })
  }

  close() {
    const dropdown = this.customTarget.querySelector('.bbx-dropdown')
    const select = this.customTarget.querySelector('.bbx-select')

    dropdown?.classList.remove('open')
    select?.classList.remove('open')
  }

  handleAction() {
    if (this.actionValue !== 'navigate') return;

    const isMultiple = this.selectTarget.hasAttribute('multiple')
    let path = this.navigatePathValue;

    // Собираем новое значение value из списка
    let newPathPart = ''
    if (isMultiple) {
      const values = Array.from(this.selectTarget.selectedOptions)
        .map(opt => opt.value)
        .join(',')
      newPathPart = values
    } else {
      newPathPart = this.selectTarget.value
    }

    // Если указано в каком месте path нужно поставить value, то делаем это,
    // а иначе подставляем value в конец целевого url (navigatePathValue).
    if (this.pathPositionReplaceValue) {
      let pathAsArr = window.location.pathname.replace(/^\/+/, '').split('/');
      pathAsArr[this.pathPositionReplaceValue] = newPathPart
      path = '/' + pathAsArr.join('/') + window.location.search;
    } else {
      path = `${path}${newPathPart}`
    }

    // докидываем параметры и якорь
    path = path + window.location.hash;

    // window.location.href = path
    Turbo.visit(path);
  }

  handleOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  calculatePosition() {
    const dropdown = this.customTarget.querySelector('.bbx-dropdown')
    const select = this.customTarget.querySelector('.bbx-select')

    if (!dropdown || !select) return

    const rect = select.getBoundingClientRect()
    const dropdownHeight = dropdown.scrollHeight || 200
    const spaceBelow = window.innerHeight - rect.bottom
    const spaceAbove = rect.top

    // Убираем предыдущие классы
    dropdown.classList.remove('dropup', 'dropdown')

    // Если снизу меньше места, чем высота дропдауна, и сверху больше - раскрываем вверх
    if (spaceBelow < dropdownHeight && spaceAbove > spaceBelow) {
      dropdown.classList.add('dropup')
      dropdown.style.top = 'auto'
      dropdown.style.bottom = 'calc(100% + 2px)'
    } else {
      dropdown.classList.add('dropdown')
      dropdown.style.top = 'calc(100% + 2px)'
      dropdown.style.bottom = 'auto'
    }

    // Проверяем, не вылазит ли справа
    const dropdownRect = dropdown.getBoundingClientRect()
    if (dropdownRect.right > window.innerWidth) {
      dropdown.style.left = 'auto'
      dropdown.style.right = '0'
    } else {
      dropdown.style.left = '0'
      dropdown.style.right = 'auto'
    }

    // Проверяем, не вылазит ли слева
    if (dropdownRect.left < 0) {
      dropdown.style.left = '0'
      dropdown.style.right = 'auto'
    }
  }
}
