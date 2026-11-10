import { BaseSchema } from '@adonisjs/lucid/schema'
import { v7 as uuidv7 } from 'uuid'

/**
 * An expense's category is now plain text typed by the user (with
 * suggestions from earlier expenses), not a link to a category table.
 * Existing expenses keep their category name; the table is removed.
 */
export default class extends BaseSchema {
  async up() {
    this.schema.alterTable('expenses', (table) => {
      table.string('category', 60).nullable().after('expense_date')
    })
    this.defer(async (db) => {
      await db.rawQuery(
        'UPDATE expenses e JOIN expense_categories c ON c.id = e.expense_category_id SET e.category = c.name'
      )
      await db.from('expenses').whereNull('category').update({ category: 'Others' })
    })
    this.schema.alterTable('expenses', (table) => {
      table.dropForeign(['expense_category_id'])
      table.dropColumn('expense_category_id')
    })
    this.schema.alterTable('expenses', (table) => {
      table.string('category', 60).notNullable().alter()
      table.index(['category'])
    })
    this.schema.dropTable('expense_categories')
  }

  async down() {
    this.schema.createTable('expense_categories', (table) => {
      table.uuid('id').primary()
      table.string('name', 50).notNullable().unique()
      table.string('icon', 30).nullable()
      table.boolean('is_active').notNullable().defaultTo(true)
      table.integer('sort_order').notNullable().defaultTo(0)
      table.dateTime('created_at').notNullable()
      table.dateTime('updated_at').notNullable()
    })
    this.schema.alterTable('expenses', (table) => {
      table.uuid('expense_category_id').nullable().after('id')
    })
    this.defer(async (db) => {
      const names = await db.from('expenses').distinct('category')
      const now = new Date()
      for (const [i, row] of names.entries()) {
        const id = uuidv7()
        await db.table('expense_categories').insert({
          id,
          name: String(row.category).slice(0, 50),
          is_active: true,
          sort_order: i + 1,
          created_at: now,
          updated_at: now,
        })
        await db
          .from('expenses')
          .where('category', row.category)
          .update({ expense_category_id: id })
      }
    })
    this.schema.alterTable('expenses', (table) => {
      table.dropIndex(['category'])
      table.dropColumn('category')
      table.foreign('expense_category_id').references('id').inTable('expense_categories')
    })
  }
}
