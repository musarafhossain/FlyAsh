import { SaleSchema } from '#database/schema'
import { compose } from '@adonisjs/core/helpers'
import { withUuid } from '#models/mixins/with_uuid'
import { belongsTo, hasMany, scope } from '@adonisjs/lucid/orm'
import type { BelongsTo, HasMany } from '@adonisjs/lucid/types/relations'
import Customer from '#models/customer'
import SaleItem from '#models/sale_item'
import SalePayment from '#models/sale_payment'
import User from '#models/user'

export default class Sale extends compose(SaleSchema, withUuid) {
  @belongsTo(() => Customer)
  declare customer: BelongsTo<typeof Customer>

  @hasMany(() => SaleItem)
  declare items: HasMany<typeof SaleItem>

  @hasMany(() => SalePayment)
  declare payments: HasMany<typeof SalePayment>

  @belongsTo(() => User, { foreignKey: 'createdBy', serializeAs: 'created_by' })
  declare creator: BelongsTo<typeof User>

  /** Excludes soft-deleted sales. Use on every query. */
  static notDeleted = scope((query) => {
    query.whereNull('sales.deleted_at')
  })
}
