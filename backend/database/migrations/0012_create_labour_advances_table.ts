import { BaseSchema } from '@adonisjs/lucid/schema'

export default class extends BaseSchema {
  protected tableName = 'labour_advances'

  async up() {
    this.schema.createTable(this.tableName, (table) => {
      table.increments('id')
      table.integer('labour_id').unsigned().notNullable().references('id').inTable('labours')
      table.decimal('amount', 12, 2).notNullable()
      table.date('advance_date').notNullable().index()
      table.string('note', 500).nullable()
      table.integer('created_by').unsigned().nullable().references('id').inTable('users')
      table.dateTime('created_at').notNullable()
      table.dateTime('updated_at').notNullable()
    })
  }

  async down() {
    this.schema.dropTable(this.tableName)
  }
}
