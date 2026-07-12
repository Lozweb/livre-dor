import type { HealthResponse } from './health.type'

const createHealthApi = (baseUrl: string) => ({
  check: (): Promise<HealthResponse> =>
    fetch(`${baseUrl}/api/health`).then(res => {
      if (!res.ok) throw new Error('unreachable')
      return res.json() as Promise<HealthResponse>
    }),
})

const healthApi = createHealthApi('')

export { healthApi }
