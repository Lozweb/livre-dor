import { useEffect, useRef, useState } from 'react'
import { recordingsApi } from './recordings.api'
import type { Recording } from './recordings.type'

type LoadState = 'loading' | 'ready' | 'error'

const useRecordings = () => {
  const [recordings, setRecordings] = useState<Recording[]>([])
  const [state, setState] = useState<LoadState>('loading')

  useEffect(() => {
    recordingsApi.list()
      .then(data => { setRecordings(data); setState('ready') })
      .catch(() => setState('error'))
  }, [])

  return { recordings, state }
}

type PlayerState = {
  playingName: string | null
  paused: boolean
  progress: number
  currentTime: number
  totalDuration: number
  toggle: (name: string, url: string) => void
  seek: (ratio: number) => void
}

const usePlayer = (): PlayerState => {
  const [playingName, setPlayingName] = useState<string | null>(null)
  const [paused, setPaused] = useState(false)
  const [progress, setProgress] = useState(0)
  const [currentTime, setCurrentTime] = useState(0)
  const [totalDuration, setTotalDuration] = useState(0)
  const audioRef = useRef<HTMLAudioElement | null>(null)

  useEffect(() => () => { audioRef.current?.pause() }, [])

  const toggle = (name: string, url: string) => {
    if (playingName !== name) {
      audioRef.current?.pause()
      const a = new Audio(url)
      audioRef.current = a
      a.addEventListener('timeupdate', () => {
        setProgress(a.currentTime / (a.duration || 1))
        setCurrentTime(a.currentTime)
      })
      a.addEventListener('loadedmetadata', () => setTotalDuration(a.duration))
      a.addEventListener('ended', () => {
        setPlayingName(null)
        setProgress(0)
        setCurrentTime(0)
        setTotalDuration(0)
      })
      a.play().catch(() => {})
      setPlayingName(name)
      setPaused(false)
    } else if (paused) {
      audioRef.current?.play().catch(() => {})
      setPaused(false)
    } else {
      audioRef.current?.pause()
      setPaused(true)
    }
  }

  const seek = (ratio: number) => {
    if (audioRef.current) {
      audioRef.current.currentTime = ratio * (audioRef.current.duration || 0)
    }
  }

  return { playingName, paused, progress, currentTime, totalDuration, toggle, seek }
}

export { useRecordings, usePlayer }
export type { PlayerState }
