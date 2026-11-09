import { BaseSchema } from '@adonisjs/lucid/schema'

export default class extends BaseSchema {
  protected tableName = 'factory_settings'

  async up() {
    this.schema.createTable(this.tableName, (table) => {
      table.uuid('id').primary()
      table.string('factory_name', 150).notNullable().defaultTo('My Brick Factory')
      table.string('owner_name', 100).nullable()
      table.string('phone', 15).nullable()
      table.string('email', 150).nullable()
      table.string('address', 500).nullable()
      table.string('invoice_prefix', 10).notNullable().defaultTo('INV-')
      /** Last invoice number used; the next sale takes +1 (row locked in the sale transaction). */
      table.integer('last_invoice_no').unsigned().notNullable().defaultTo(0)
      table.uuid('updated_by').nullable().references('id').inTable('users')
      table.dateTime('created_at').notNullable()
      table.dateTime('updated_at').notNullable()
    })
  }

  async down() {
    this.schema.dropTable(this.tableName)
  }
}
