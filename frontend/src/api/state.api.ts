import type { StateResponse } from './state.type'

const createStateApi = (baseUrl: string) => ({
  get: (): Promise<StateResponse> =>
    fetch(`${baseUrl}/api/state`).then(r => r.json()),
})

const stateApi = createStateApi('')

export { stateApi }
