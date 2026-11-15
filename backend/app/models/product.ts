import { ProductSchema } from '#database/schema'
import { compose } from '@adonisjs/core/helpers'
import { withUuid } from '#models/mixins/with_uuid'

/** A product: a name and a default selling price (no cost). */
export default class Product extends compose(ProductSchema, withUuid) {}
