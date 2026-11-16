import { BaseSchema } from '@adonisjs/lucid/schema'

/**
 * Indexes for the queries the app runs most (lists of 20, reports):
 * each one matches a filter + sort in a controller or service.
 */
const INDEXES: [table: string, columns: string[]][] = [
  // Sales list: not deleted, newest first (sale_date desc, id desc)
  ['sales', ['deleted_at', 'sale_date', 'id']],
  // Sales tabs: Instant / Booking, newest first
  ['sales', ['type', 'sale_date']],
  // A customer's sales and dues (customer_id + status)
  ['sales', ['customer_id', 'status']],
  // Sale detail: payments in date order
  ['sale_payments', ['sale_id', 'payment_date']],
  // Net profit: wages paid in a period
  ['wage_payments', ['payment_date']],
  // Expenses: one category in a period
  ['expenses', ['category', 'expense_date']],
  // Lists: newest first
  ['labours', ['created_at']],
  ['products', ['created_at']],
  ['users', ['created_at']],
  // Attendance: who was employed on a date
  ['labours', ['joining_date', 'left_date']],
  // Customers list: active filter, newest first
  ['customers', ['is_active', 'created_at']],
]

/** Foreign-key columns that lead one of the indexes above. */
const FOREIGN_KEY_FIRST = new Set(['sales.customer_id', 'sale_payments.sale_id'])

export default class extends BaseSchema {
  async up() {
    for (const [table, columns] of INDEXES) {
      this.schema.alterTable(table, (t) => {
        t.index(columns)
      })
    }
  }

  async down() {
    for (const [table, columns] of INDEXES) {
      this.schema.alterTable(table, (t) => {
        // MySQL lets an index that starts with a foreign-key column replace
        // the key's own index; give the key a plain index back first.
        if (FOREIGN_KEY_FIRST.has(`${table}.${columns[0]}`)) t.index([columns[0]])
        t.dropIndex(columns)
      })
    }
  }
}
