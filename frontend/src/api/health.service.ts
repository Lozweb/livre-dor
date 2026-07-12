import { useEffect, useState } from 'react'
import { healthApi } from './health.api'

type ServerStatus = 'loading' | 'online' | 'offline'

const useServerStatus = (): ServerStatus => {
  const [status, setStatus] = useState<ServerStatus>('loading')

  useEffect(() => {
    const check = () =>
      healthApi.check()
        .then(() => setStatus('online'))
        .catch(() => setStatus('offline'))

    check()
    const interval = setInterval(check, 30_000)
    return () => clearInterval(interval)
  }, [])

  return status
}

export { useServerStatus }
export type { ServerStatus }
