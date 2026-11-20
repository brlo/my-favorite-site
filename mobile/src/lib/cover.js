// Заголовок поверх обложки: цвета подложки приходят из админки (hex),
// градиент и размер шрифта повторяют серверные PagesHelper.

export function hexToRgb(value) {
  let hex = String(value || '').trim().replace(/^#/, '')
  if (hex.length === 3) hex = hex.split('').map((c) => c + c).join('')
  if (!/^[0-9a-f]{6}$/i.test(hex)) return null
  return [0, 2, 4].map((i) => parseInt(hex.slice(i, i + 2), 16))
}

export function overlayStyle(bg) {
  const rgb = hexToRgb(bg)
  if (!rgb) return null
  const [r, g, b] = rgb
  return {
    background: `linear-gradient(to top, rgba(${r}, ${g}, ${b}, 0.85) 0%, rgba(${r}, ${g}, ${b}, 0) 60%)`,
  }
}

export function overlayTextColor(color) {
  return hexToRgb(color) ? color : '#ffffff'
}

// Пороги как в PagesHelper#cover_overlay_title_size_class
export function overlayTitleClass(title) {
  const length = String(title || '').length
  if (length > 50) return 'title-lg'
  if (length > 25) return 'title-md'
  return ''
}
