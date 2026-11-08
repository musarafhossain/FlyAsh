import { defineConfig, stores } from '@adonisjs/limiter'

/**
 * One API process runs on the server, so the in-memory store is enough
 * (no extra table). Counters reset when the API restarts.
 */
const limiterConfig = defineConfig({
  default: 'memory',
  stores: {
    memory: stores.memory({}),
  },
})

export default limiterConfig

declare module '@adonisjs/limiter/types' {
  export interface LimitersList extends InferLimiters<typeof limiterConfig> {}
}
