// Решает, нужно ли перечитать скелет языка целиком. Это бывает, когда
// сервер научился отдавать новые поля страниц, а в локальной дельте их ещё
// нет: старые страницы не попадают в выборку «изменённые с since».
export function needsFullSkeleton({ since = 0, localVersion = 0, serverVersion = 1, forceFull = false } = {}) {
  if (forceFull) return false
  if (!since) return false
  const local = Number(localVersion) || 0
  const server = Number(serverVersion) || 1
  // Версии 0 и 1 означают старый сервер: полный скелет всё равно не даст новых полей
  return server > Math.max(local, 1)
}
