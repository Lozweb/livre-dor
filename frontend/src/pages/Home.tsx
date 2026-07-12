import { useServerStatus } from '../api/health.service'
import { useRecordings, usePlayer } from '../api/recordings.service'
import { usePhoneState } from '../api/state.service'
import type { PhoneState } from '../api/state.type'
import { RecordingList } from '../components/RecordingList'

const phoneStateConfig: Record<PhoneState, { dot: string; label: string }> = {
  idle:          { dot: 'bg-green-500',               label: 'Prêt à enregistrer' },
  playing_intro: { dot: 'bg-blue-400 animate-pulse', label: 'Message d\'accueil' },
  recording:     { dot: 'bg-red-500 animate-pulse',  label: 'Enregistrement' },
}

const Home = () => {
  const serverStatus = useServerStatus()
  const { recordings, state } = useRecordings()
  const player = usePlayer()
  const phoneState = usePhoneState()

  return (
    <main className="min-h-screen bg-stone-950 text-stone-100">
      <div className="max-w-2xl mx-auto px-4 py-12">

        <header className="flex items-center justify-between mb-10">
          <h1 className="text-xl font-light tracking-[0.2em] uppercase text-stone-300">
            Livre d'or
          </h1>
          <div className="flex items-center gap-2">
            {phoneState ? (
              <>
                <span className={`w-1.5 h-1.5 rounded-full ${phoneStateConfig[phoneState].dot}`} />
                <span className="text-xs text-stone-500">{phoneStateConfig[phoneState].label}</span>
              </>
            ) : (
              <>
                <span className={`w-1.5 h-1.5 rounded-full ${serverStatus === 'offline' ? 'bg-red-500' : 'bg-stone-600 animate-pulse'}`} />
                <span className="text-xs text-stone-500">{serverStatus === 'offline' ? 'Hors ligne' : ''}</span>
              </>
            )}
          </div>
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
