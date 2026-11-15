import { ProductSchema } from '#database/schema'
import { compose } from '@adonisjs/core/helpers'
import { withUuid } from '#models/mixins/with_uuid'
import { computed } from '@adonisjs/lucid/orm'
import { fromPaise, toPaise } from '#helpers/money'

export default class Product extends compose(ProductSchema, withUuid) {
  /** Selling price − production cost, per unit */
  @computed()
  get margin() {
    return fromPaise(toPaise(this.defaultPrice) - toPaise(this.defaultCost))
  }
}
