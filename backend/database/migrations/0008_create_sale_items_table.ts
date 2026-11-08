import { BaseSchema } from '@adonisjs/lucid/schema'

export default class extends BaseSchema {
  protected tableName = 'sale_items'

  async up() {
    this.schema.createTable(this.tableName, (table) => {
      table.increments('id')
      table
        .integer('sale_id')
        .unsigned()
        .notNullable()
        .references('id')
        .inTable('sales')
        .onDelete('CASCADE')
      table.integer('product_id').unsigned().notNullable().references('id').inTable('products')
      table.string('product_name', 100).notNullable()
      table.string('unit', 30).notNullable()
      table.decimal('quantity', 12, 2).notNullable()
      table.decimal('unit_cost', 12, 2).notNullable()
      table.decimal('unit_price', 12, 2).notNullable()
      table.decimal('line_cost', 12, 2).notNullable()
      table.decimal('line_total', 12, 2).notNullable()
      table.dateTime('created_at').notNullable()
      table.dateTime('updated_at').notNullable()
    })
  }

  async down() {
    this.schema.dropTable(this.tableName)
  }
}
