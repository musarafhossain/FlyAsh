import { BaseSchema } from '@adonisjs/lucid/schema'

/**
 * Optional GSTIN of the factory (15 characters, e.g. 19ABCDE1234F1Z5),
 * printed on sale receipts.
 */
export default class extends BaseSchema {
  protected tableName = 'factory_settings'

  async up() {
    this.schema.alterTable(this.tableName, (table) => {
      table.string('gst_number', 15).nullable().after('address')
    })
  }

  async down() {
    this.schema.alterTable(this.tableName, (table) => {
      table.dropColumn('gst_number')
    })
  }
}
