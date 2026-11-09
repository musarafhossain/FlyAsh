import { LabourAdvanceSchema } from '#database/schema'
import { compose } from '@adonisjs/core/helpers'
import { withUuid } from '#models/mixins/with_uuid'
import { belongsTo } from '@adonisjs/lucid/orm'
import type { BelongsTo } from '@adonisjs/lucid/types/relations'
import Labour from '#models/labour'
import User from '#models/user'

export default class LabourAdvance extends compose(LabourAdvanceSchema, withUuid) {
  @belongsTo(() => Labour)
  declare labour: BelongsTo<typeof Labour>

  @belongsTo(() => User, { foreignKey: 'createdBy', serializeAs: 'created_by' })
  declare creator: BelongsTo<typeof User>
}
