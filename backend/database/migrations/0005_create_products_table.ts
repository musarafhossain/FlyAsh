import { BaseSchema } from '@adonisjs/lucid/schema'

export default class extends BaseSchema {
  protected tableName = 'products'

  async up() {
    this.schema.createTable(this.tableName, (table) => {
      table.increments('id')
      table.string('name', 100).notNullable().unique()
      table.string('unit', 20).notNullable().defaultTo('piece')
      table.string('unit_label', 30).nullable()
      table.decimal('default_cost', 12, 2).notNullable().defaultTo(0)
      table.decimal('default_price', 12, 2).notNullable().defaultTo(0)
      table.string('notes', 500).nullable()
      table.boolean('is_active').notNullable().defaultTo(true).index()
      table.integer('created_by').unsigned().nullable().references('id').inTable('users')
      table.dateTime('created_at').notNullable()
      table.dateTime('updated_at').notNullable()
    })
  }

  async down() {
    this.schema.dropTable(this.tableName)
  }
}
