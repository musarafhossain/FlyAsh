import { SaleItemSchema } from '#database/schema'
import { compose } from '@adonisjs/core/helpers'
import { withUuid } from '#models/mixins/with_uuid'
import { belongsTo } from '@adonisjs/lucid/orm'
import type { BelongsTo } from '@adonisjs/lucid/types/relations'
import Sale from '#models/sale'
import Product from '#models/product'

export default class SaleItem extends compose(SaleItemSchema, withUuid) {
  @belongsTo(() => Sale)
  declare sale: BelongsTo<typeof Sale>

  @belongsTo(() => Product)
  declare product: BelongsTo<typeof Product>
}
