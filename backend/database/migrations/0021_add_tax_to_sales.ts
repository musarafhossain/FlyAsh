import { BaseSchema } from '@adonisjs/lucid/schema'

/**
 * Tax on a sale: a percentage of (subtotal + transport − discount).
 * total = that amount + tax_amount. Tax is not profit.
 */
export default class extends BaseSchema {
  protected tableName = 'sales'

  async up() {
    this.schema.alterTable(this.tableName, (table) => {
      table.decimal('tax_percent', 5, 2).notNullable().defaultTo(0).after('discount')
      table.decimal('tax_amount', 12, 2).notNullable().defaultTo(0).after('tax_percent')
    })
  }

  async down() {
    this.schema.alterTable(this.tableName, (table) => {
      table.dropColumn('tax_amount')
      table.dropColumn('tax_percent')
    })
  }
}
