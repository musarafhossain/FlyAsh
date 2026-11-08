import { ProductSchema } from '#database/schema'
import { computed } from '@adonisjs/lucid/orm'
import { fromPaise, toPaise } from '#helpers/money'

export default class Product extends ProductSchema {
  /** Selling price − production cost, per unit */
  @computed()
  get margin() {
    return fromPaise(toPaise(this.defaultPrice) - toPaise(this.defaultCost))
  }

  /** Text shown for the unit ("piece", "thousand", "truck" or the custom label) */
  get unitText() {
    return this.unit === 'other' && this.unitLabel ? this.unitLabel : this.unit
  }
}
