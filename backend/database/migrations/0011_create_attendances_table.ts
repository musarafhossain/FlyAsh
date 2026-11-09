import { BaseSchema } from '@adonisjs/lucid/schema'

export default class extends BaseSchema {
  protected tableName = 'attendances'

  async up() {
    this.schema.createTable(this.tableName, (table) => {
      table.uuid('id').primary()
      table.uuid('labour_id').notNullable().references('id').inTable('labours')
      table.date('date').notNullable().index()
      table.string('status', 20).notNullable()
      table.string('wage_type', 20).notNullable()
      table.decimal('wage_amount', 12, 2).notNullable()
      table.uuid('created_by').nullable().references('id').inTable('users')
      table.dateTime('created_at').notNullable()
      table.dateTime('updated_at').notNullable()

      table.unique(['labour_id', 'date'])
    })
  }

  async down() {
    this.schema.dropTable(this.tableName)
  }
}
