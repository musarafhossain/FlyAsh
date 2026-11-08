import { LabourAdvanceSchema } from '#database/schema'
import { belongsTo } from '@adonisjs/lucid/orm'
import type { BelongsTo } from '@adonisjs/lucid/types/relations'
import Labour from '#models/labour'
import User from '#models/user'

export default class LabourAdvance extends LabourAdvanceSchema {
  @belongsTo(() => Labour)
  declare labour: BelongsTo<typeof Labour>

  @belongsTo(() => User, { foreignKey: 'createdBy', serializeAs: 'created_by' })
  declare creator: BelongsTo<typeof User>
}
