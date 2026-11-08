/*
|--------------------------------------------------------------------------
| App-wide defaults (loaded before routes)
|--------------------------------------------------------------------------
|
| - All timestamps are created and stored in UTC. Business dates use the
|   factory timezone through the helpers in app/helpers/dates.ts.
| - API JSON keys are snake_case (is_active, created_at, ...).
|
*/

import { Settings } from 'luxon'
import { BaseModel, SnakeCaseNamingStrategy } from '@adonisjs/lucid/orm'

Settings.defaultZone = 'utc'
BaseModel.namingStrategy = new SnakeCaseNamingStrategy()
