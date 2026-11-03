// Место прочтения материалов: запоминаем прокрутку каждой страницы и возвращаем её,
// когда текст догрузится (он приходит из базы уже после перехода).
const KEY = 'scrollPositions'
const LIMIT = 300

let positions = load()

function load() {
  try { return JSON.parse(localStorage.getItem(KEY) || '{}') } catch { return {} }
}

function store() {
  try { localStorage.setItem(KEY, JSON.stringify(positions)) } catch {}
}

export function rememberScroll(key, top) {
  delete positions[key]
  if (top > 0) positions[key] = Math.round(top)
  const keys = Object.keys(positions)
  if (keys.length > LIMIT) for (const k of keys.slice(0, keys.length - LIMIT)) delete positions[k]
  store()
}

export function rememberedScroll(key) {
  return positions[key] || 0
}

// Ждём, пока страница вырастет до нужной высоты (или выйдет время, или пользователь сам начнёт листать)
export function whenScrollable(top, timeout = 4000) {
  return new Promise((resolve) => {
    const start = Date.now()
    let stopped = false
    const stop = () => { stopped = true }
    window.addEventListener('touchstart', stop, { once: true, passive: true })
    window.addEventListener('wheel', stop, { once: true, passive: true })
    const check = () => {
      const max = document.documentElement.scrollHeight - window.innerHeight
      if (stopped || max >= top || Date.now() - start > timeout) {
        window.removeEventListener('touchstart', stop)
        window.removeEventListener('wheel', stop)
        return resolve(!stopped)
      }
      setTimeout(check, 50)
    }
    check()
  })
}

// Вернулись ли мы на эту запись истории «назад» (тогда у неё есть сохранённая прокрутка)
export function isHistoryRestore() {
  return !!window.history.state?.scroll
}
