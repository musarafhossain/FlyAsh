import { AttendanceSchema } from '#database/schema'
import { compose } from '@adonisjs/core/helpers'
import { withUuid } from '#models/mixins/with_uuid'
import { belongsTo } from '@adonisjs/lucid/orm'
import type { BelongsTo } from '@adonisjs/lucid/types/relations'
import Labour from '#models/labour'

export default class Attendance extends compose(AttendanceSchema, withUuid) {
  @belongsTo(() => Labour)
  declare labour: BelongsTo<typeof Labour>
}
