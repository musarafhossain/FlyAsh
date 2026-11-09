import { SalePaymentSchema } from '#database/schema'
import { compose } from '@adonisjs/core/helpers'
import { withUuid } from '#models/mixins/with_uuid'
import { belongsTo } from '@adonisjs/lucid/orm'
import type { BelongsTo } from '@adonisjs/lucid/types/relations'
import Sale from '#models/sale'
import User from '#models/user'

export default class SalePayment extends compose(SalePaymentSchema, withUuid) {
  @belongsTo(() => Sale)
  declare sale: BelongsTo<typeof Sale>

  @belongsTo(() => User, { foreignKey: 'createdBy', serializeAs: 'created_by' })
  declare creator: BelongsTo<typeof User>
}
