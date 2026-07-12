const formatDuration = (secs: number): string => {
  const m = Math.floor(secs / 60)
  const s = Math.floor(secs % 60)
  return `${m}:${s.toString().padStart(2, '0')}`
}

const formatSize = (bytes: number): string => {
  if (bytes < 1024 * 1024) return `${Math.round(bytes / 1024)} Ko`
  return `${(bytes / (1024 * 1024)).toFixed(1)} Mo`
}

const formatDate = (timestamp: number): string => {
  const date = new Date(timestamp * 1000)
  const now = new Date()
  const yesterday = new Date(now.getTime() - 86_400_000)

  const time = date.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' })

  if (date.toDateString() === now.toDateString())
    return `Aujourd'hui à ${time}`

  if (date.toDateString() === yesterday.toDateString())
    return `Hier à ${time}`

  const dateStr = date.toLocaleDateString('fr-FR', {
    day: 'numeric',
    month: 'short',
    ...(date.getFullYear() !== now.getFullYear() ? { year: 'numeric' } : {}),
  })
  return `${dateStr} à ${time}`
}

export { formatDate, formatDuration, formatSize }
