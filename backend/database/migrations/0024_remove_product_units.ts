import { BaseSchema } from '@adonisjs/lucid/schema'

/**
 * Products have no unit any more (piece / thousand / truck / custom label):
 * a product is just a name with a cost and a price. The unit copy on sale
 * items goes too.
 */
export default class extends BaseSchema {
  async up() {
    this.schema.alterTable('products', (table) => {
      table.dropColumn('unit_label')
      table.dropColumn('unit')
    })
    this.schema.alterTable('sale_items', (table) => {
      table.dropColumn('unit')
    })
  }

  async down() {
    this.schema.alterTable('products', (table) => {
      table.string('unit', 20).notNullable().defaultTo('piece').after('name')
      table.string('unit_label', 30).nullable().after('unit')
    })
    this.schema.alterTable('sale_items', (table) => {
      table.string('unit', 30).notNullable().defaultTo('piece').after('product_name')
    })
  }
}
