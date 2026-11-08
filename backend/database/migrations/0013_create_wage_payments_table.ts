import { BaseSchema } from '@adonisjs/lucid/schema'

export default class extends BaseSchema {
  protected tableName = 'wage_payments'

  async up() {
    this.schema.createTable(this.tableName, (table) => {
      table.increments('id')
      table.integer('labour_id').unsigned().notNullable().references('id').inTable('labours')
      table.date('wage_month').notNullable()
      table.decimal('amount', 12, 2).notNullable()
      table.date('payment_date').notNullable()
      table.string('method', 20).notNullable().defaultTo('cash')
      table.string('note', 500).nullable()
      table.integer('created_by').unsigned().nullable().references('id').inTable('users')
      table.dateTime('created_at').notNullable()
      table.dateTime('updated_at').notNullable()

      table.index(['labour_id', 'wage_month'])
    })
  }

  async down() {
    this.schema.dropTable(this.tableName)
  }
}
