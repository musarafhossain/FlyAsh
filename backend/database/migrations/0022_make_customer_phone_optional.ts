import { BaseSchema } from '@adonisjs/lucid/schema'

/** A customer's phone is optional; when given it is still unique. */
export default class extends BaseSchema {
  protected tableName = 'customers'

  async up() {
    this.schema.alterTable(this.tableName, (table) => {
      table.string('phone', 15).nullable().alter()
    })
  }

  async down() {
    this.defer(async (db) => {
      await db
        .from(this.tableName)
        .whereNull('phone')
        .update({ phone: db.raw('LEFT(id, 15)') })
    })
    this.schema.alterTable(this.tableName, (table) => {
      table.string('phone', 15).notNullable().alter()
    })
  }
}
