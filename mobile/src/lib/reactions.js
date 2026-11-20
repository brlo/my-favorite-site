// Реакции на статью: сервер разрешает одну реакцию на IP, поэтому клиент
// только повторяет действие и показывает то, что вернул сервер.
import { getJSON, postJSON, online } from './net.js'
import { kvGet, kvSet } from './db.js'

export const REACTION_KINDS = [
  { kind: 'like', emoji: '❤️', label: 'reaction_like' },
  { kind: 'useful', emoji: '👍', label: 'reaction_useful' },
  { kind: 'thanks', emoji: '🙏', label: 'reaction_thanks' },
  { kind: 'interesting', emoji: '⚡️', label: 'reaction_interesting' },
  { kind: 'hundred', emoji: '💯', label: 'reaction_hundred' },
]

export async function loadCachedReactions(pageId) {
  return kvGet(`reactions:${pageId}`, null)
}

export async function saveCachedReactions(pageId, data) {
  await kvSet(`reactions:${pageId}`, { ...data, at: Date.now() })
}

export async function fetchReactions(pageId) {
  if (!online.value) return null
  return getJSON('/api/offline/reactions', { page_id: pageId })
}

export async function toggleReaction(pageId, kind) {
  if (!online.value) return null
  return postJSON('/api/offline/reactions', { page_id: pageId, kind })
}
