import { recordingsApi } from '../api/recordings.api'
import type { Recording } from '../api/recordings.type'
import type { PlayerState } from '../api/recordings.service'
import { formatDuration, formatSize } from '../utils/format'

const PlayIcon = () => (
  <svg viewBox="0 0 24 24" fill="currentColor" className="w-4 h-4 translate-x-px">
    <path d="M8 5v14l11-7z" />
  </svg>
)

const PauseIcon = () => (
  <svg viewBox="0 0 24 24" fill="currentColor" className="w-4 h-4">
    <path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z" />
  </svg>
)

const DownloadIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.5} className="w-4 h-4">
    <path strokeLinecap="round" strokeLinejoin="round" d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5M16.5 12L12 16.5m0 0L7.5 12m4.5 4.5V3" />
  </svg>
)

type Props = {
  recording: Recording
  player: PlayerState
}

const RecordingRow = ({ recording, player }: Props) => {
  const isPlaying = player.playingName === recording.name
  const isActive = isPlaying && !player.paused

  const handleToggle = () =>
    player.toggle(recording.name, recordingsApi.streamUrl(recording.name))

  const handleSeek = (e: React.MouseEvent<HTMLDivElement>) => {
    const rect = e.currentTarget.getBoundingClientRect()
    player.seek(Math.max(0, Math.min(1, (e.clientX - rect.left) / rect.width)))
  }

  const displayDuration = isPlaying && player.totalDuration
    ? player.totalDuration
    : recording.duration_secs

  return (
    <div
      className={`group relative flex items-center gap-3 px-3 py-3 rounded-xl transition-colors ${
        isPlaying ? 'bg-stone-900' : 'hover:bg-stone-900/50'
      }`}
    >
      <button
        onClick={handleToggle}
        aria-label={isActive ? 'Pause' : 'Lire'}
        aria-pressed={isPlaying}
        className="flex-shrink-0 w-9 h-9 flex items-center justify-center rounded-full bg-stone-800 hover:bg-stone-700 text-stone-300 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-stone-500"
      >
        {isActive ? <PauseIcon /> : <PlayIcon />}
      </button>

      <div className="flex-1 min-w-0">
        <div className="flex items-baseline justify-between gap-4">
          <p className="text-sm text-stone-200 font-mono truncate">
            {recording.name.replace(/\.wav$/, '')}
          </p>
          <div className="flex items-center gap-3 flex-shrink-0">
            <span className="text-xs text-stone-500 tabular-nums">{formatDuration(recording.duration_secs)}</span>
            <span className="text-xs text-stone-700">·</span>
            <span className="text-xs text-stone-600">{formatSize(recording.size)}</span>
          </div>
        </div>

        {isPlaying && (
          <div className="flex items-center gap-2 mt-2">
            <div
              role="progressbar"
              aria-valuenow={Math.round(player.progress * 100)}
              aria-valuemin={0}
              aria-valuemax={100}
              onClick={handleSeek}
              className="flex-1 h-1 bg-stone-800 rounded-full cursor-pointer group/bar"
            >
              <div
                className="h-full bg-stone-400 rounded-full transition-all duration-100"
                style={{ width: `${player.progress * 100}%` }}
              />
            </div>
            <span className="text-xs text-stone-500 tabular-nums flex-shrink-0">
              {formatDuration(player.currentTime)} / {formatDuration(displayDuration)}
            </span>
          </div>
        )}
      </div>

      <a
        href={recordingsApi.downloadUrl(recording.name)}
        download={recording.name}
        aria-label="Télécharger"
        onClick={e => e.stopPropagation()}
        className="flex-shrink-0 w-8 h-8 flex items-center justify-center rounded-lg text-stone-600 hover:text-stone-300 hover:bg-stone-800 transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-stone-500 opacity-0 group-hover:opacity-100"
      >
        <DownloadIcon />
      </a>
    </div>
  )
}

export { RecordingRow }
