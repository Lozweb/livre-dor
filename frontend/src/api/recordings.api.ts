import type { Recording } from './recordings.type'

const createRecordingsApi = (baseUrl: string) => ({
  list: (): Promise<Recording[]> =>
    fetch(`${baseUrl}/api/recordings`).then(res => {
      if (!res.ok) throw new Error('fetch failed')
      return res.json() as Promise<Recording[]>
    }),

  streamUrl: (name: string): string =>
    `${baseUrl}/api/recordings/${encodeURIComponent(name)}`,

  downloadUrl: (name: string): string =>
    `${baseUrl}/api/recordings/${encodeURIComponent(name)}/download`,
})

const recordingsApi = createRecordingsApi('')

export { recordingsApi }
