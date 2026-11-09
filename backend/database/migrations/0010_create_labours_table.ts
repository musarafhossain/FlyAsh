import { BaseSchema } from '@adonisjs/lucid/schema'

export default class extends BaseSchema {
  protected tableName = 'labours'

  async up() {
    this.schema.createTable(this.tableName, (table) => {
      table.uuid('id').primary()
      table.string('name', 100).notNullable().index()
      table.string('phone', 15).nullable()
      table.string('address', 500).nullable()
      table.string('wage_type', 20).notNullable()
      table.decimal('wage_amount', 12, 2).notNullable()
      table.date('joining_date').notNullable()
      table.date('left_date').nullable()
      table.boolean('is_active').notNullable().defaultTo(true).index()
      table.uuid('created_by').nullable().references('id').inTable('users')
      table.dateTime('created_at').notNullable()
      table.dateTime('updated_at').notNullable()
    })
  }

  async down() {
    this.schema.dropTable(this.tableName)
  }
}
