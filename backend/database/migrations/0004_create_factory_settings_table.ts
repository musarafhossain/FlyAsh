import { BaseSchema } from '@adonisjs/lucid/schema'

export default class extends BaseSchema {
  protected tableName = 'factory_settings'

  async up() {
    this.schema.createTable(this.tableName, (table) => {
      table.increments('id')
      table.string('factory_name', 150).notNullable().defaultTo('My Brick Factory')
      table.string('owner_name', 100).nullable()
      table.string('phone', 15).nullable()
      table.string('email', 150).nullable()
      table.string('address', 500).nullable()
      table.string('logo_path').nullable()
      table.string('invoice_prefix', 10).notNullable().defaultTo('INV-')
      table.integer('updated_by').unsigned().nullable().references('id').inTable('users')
      table.dateTime('created_at').notNullable()
      table.dateTime('updated_at').notNullable()
    })
  }

  async down() {
    this.schema.dropTable(this.tableName)
  }
}
