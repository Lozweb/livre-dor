import { useEffect, useState } from 'react'
import { stateApi } from './state.api'
import type { PhoneState } from './state.type'

const usePhoneState = (): PhoneState | null => {
  const [phoneState, setPhoneState] = useState<PhoneState | null>(null)

  useEffect(() => {
    const poll = () =>
      stateApi.get()
        .then(r => setPhoneState(r.state))
        .catch(() => setPhoneState(null))

    poll()
    const interval = setInterval(poll, 1_000)
    return () => clearInterval(interval)
  }, [])

  return phoneState
}

export { usePhoneState }
