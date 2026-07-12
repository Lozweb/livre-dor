import { useServerStatus } from '../api/health.service'
import type { ServerStatus } from '../api/health.service'
import { useRecordings, usePlayer } from '../api/recordings.service'
import { RecordingList } from '../components/RecordingList'

const statusConfig: Record<ServerStatus, { dot: string; label: string }> = {
  loading: { dot: 'bg-stone-600 animate-pulse', label: '' },
  online:  { dot: 'bg-green-500',               label: 'En ligne' },
  offline: { dot: 'bg-red-500',                 label: 'Hors ligne' },
}

const Home = () => {
  const status = useServerStatus()
  const { recordings, state } = useRecordings()
  const player = usePlayer()

  const { dot, label } = statusConfig[status]

  return (
    <main className="min-h-screen bg-stone-950 text-stone-100">
      <div className="max-w-2xl mx-auto px-4 py-12">

        <header className="flex items-center justify-between mb-10">
          <h1 className="text-xl font-light tracking-[0.2em] uppercase text-stone-300">
            Livre d'or
          </h1>
          {label && (
            <div className="flex items-center gap-2">
              <span className={`w-1.5 h-1.5 rounded-full ${dot}`} />
              <span className="text-xs text-stone-500">{label}</span>
            </div>
          )}
        </header>

        {state === 'ready' && recordings.length > 0 && (
          <p className="text-xs text-stone-600 uppercase tracking-widest mb-4">
            {recordings.length} {recordings.length === 1 ? 'message' : 'messages'}
          </p>
        )}

        <RecordingList
          recordings={recordings}
          loading={state === 'loading'}
          error={state === 'error'}
          player={player}
        />

      </div>
    </main>
  )
}

export { Home }
