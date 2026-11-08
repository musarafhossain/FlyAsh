/*
|--------------------------------------------------------------------------
| Routes: all API routes live under /api/v1
|--------------------------------------------------------------------------
*/

import router from '@adonisjs/core/services/router'
import db from '@adonisjs/lucid/services/db'
import { ok } from '#helpers/api_response'

router.get('/', ({ response }) => ok(response, { name: 'FlyAsh API' }))

router
  .group(() => {
    router.get('health', async ({ response }) => {
      await db.rawQuery('SELECT 1')
      return ok(response, { status: 'ok', db: 'ok', time: new Date().toISOString() }, 'Healthy')
    })
  })
  .prefix('/api/v1')
