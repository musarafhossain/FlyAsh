import { AttendanceSchema } from '#database/schema'
import { belongsTo } from '@adonisjs/lucid/orm'
import type { BelongsTo } from '@adonisjs/lucid/types/relations'
import Labour from '#models/labour'

export default class Attendance extends AttendanceSchema {
  @belongsTo(() => Labour)
  declare labour: BelongsTo<typeof Labour>
}
