import { BaseSchema } from '@adonisjs/lucid/schema'

/**
 * Attendance is present / absent only (no half day). A row means the labour
 * was present that day; no row means absent. Old half-day and absent rows
 * are removed with the status column.
 */
export default class extends BaseSchema {
  protected tableName = 'attendances'

  async up() {
    this.defer(async (db) => {
      await db.from(this.tableName).whereNot('status', 'present').delete()
    })
    this.schema.alterTable(this.tableName, (table) => {
      table.dropColumn('status')
    })
  }

  async down() {
    this.schema.alterTable(this.tableName, (table) => {
      table.string('status', 20).notNullable().defaultTo('present').after('date')
    })
  }
}
