import { BaseSchema } from '@adonisjs/lucid/schema'

export default class extends BaseSchema {
  protected tableName = 'sales'

  async up() {
    this.schema.createTable(this.tableName, (table) => {
      table.increments('id')
      table.string('invoice_no', 20).nullable().unique()
      table.string('type', 20).notNullable()
      table.string('status', 20).notNullable()
      table.integer('customer_id').unsigned().notNullable().references('id').inTable('customers')
      table.date('sale_date').notNullable().index()
      table.date('delivery_date').nullable()
      table.date('delivered_date').nullable()
      table.string('delivery_address', 500).nullable()
      table.decimal('subtotal', 12, 2).notNullable().defaultTo(0)
      table.decimal('transport_charge', 12, 2).notNullable().defaultTo(0)
      table.decimal('discount', 12, 2).notNullable().defaultTo(0)
      table.decimal('total', 12, 2).notNullable().defaultTo(0)
      table.decimal('total_cost', 12, 2).notNullable().defaultTo(0)
      table.decimal('profit', 12, 2).notNullable().defaultTo(0)
      table.decimal('paid_amount', 12, 2).notNullable().defaultTo(0)
      table.decimal('due_amount', 12, 2).notNullable().defaultTo(0)
      table.string('payment_status', 20).notNullable().defaultTo('due').index()
      table.string('notes', 1000).nullable()
      table.dateTime('cancelled_at').nullable()
      table.integer('created_by').unsigned().nullable().references('id').inTable('users')
      table.dateTime('created_at').notNullable()
      table.dateTime('updated_at').notNullable()
      table.dateTime('deleted_at').nullable().index()

      table.index(['status', 'delivered_date'])
      table.index(['status', 'delivery_date'])
    })
  }

  async down() {
    this.schema.dropTable(this.tableName)
  }
}
