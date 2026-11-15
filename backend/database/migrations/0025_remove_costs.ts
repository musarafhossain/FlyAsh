import { BaseSchema } from '@adonisjs/lucid/schema'

/**
 * Products have a price only (no production cost), so cost and per-sale
 * profit are removed: products.default_cost, sale_items.unit_cost and
 * line_cost, sales.total_cost and profit. Net profit is now
 * sales (without tax) − expenses − wages.
 */
export default class extends BaseSchema {
  async up() {
    this.schema.alterTable('products', (table) => {
      table.dropColumn('default_cost')
    })
    this.schema.alterTable('sale_items', (table) => {
      table.dropColumn('unit_cost')
      table.dropColumn('line_cost')
    })
    this.schema.alterTable('sales', (table) => {
      table.dropColumn('total_cost')
      table.dropColumn('profit')
    })
  }

  async down() {
    this.schema.alterTable('products', (table) => {
      table.decimal('default_cost', 12, 2).notNullable().defaultTo(0)
    })
    this.schema.alterTable('sale_items', (table) => {
      table.decimal('unit_cost', 12, 2).notNullable().defaultTo(0)
      table.decimal('line_cost', 12, 2).notNullable().defaultTo(0)
    })
    this.schema.alterTable('sales', (table) => {
      table.decimal('total_cost', 12, 2).notNullable().defaultTo(0)
      table.decimal('profit', 12, 2).notNullable().defaultTo(0)
    })
  }
}
