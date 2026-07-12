import type { Recording } from '../api/recordings.type'
import type { PlayerState } from '../api/recordings.service'
import { RecordingRow } from './RecordingRow'

const Skeleton = () => (
  <div className="flex items-center gap-3 px-3 py-3">
    <div className="w-9 h-9 rounded-full bg-stone-900 animate-pulse flex-shrink-0" />
    <div className="flex-1">
      <div className="h-3 w-40 bg-stone-900 rounded animate-pulse" />
      <div className="h-2 w-24 bg-stone-900/60 rounded animate-pulse mt-2" />
    </div>
  </div>
)

type Props = {
  recordings: Recording[]
  loading: boolean
  error: boolean
  player: PlayerState
}

const RecordingList = ({ recordings, loading, error, player }: Props) => {
  if (loading) {
    return (
      <div className="divide-y divide-stone-900">
        {Array.from({ length: 4 }).map((_, i) => <Skeleton key={i} />)}
      </div>
    )
  }

  if (error) {
    return (
      <p className="text-sm text-stone-600 text-center py-12">
        Impossible de charger les messages.
      </p>
    )
  }

  if (recordings.length === 0) {
    return (
      <p className="text-sm text-stone-600 text-center py-12">
        Aucun message pour l'instant.
      </p>
    )
  }

  return (
    <div className="space-y-0.5">
      {recordings.map(recording => (
        <RecordingRow
          key={recording.name}
          recording={recording}
          player={player}
        />
      ))}
    </div>
  )
}

export { RecordingList }
