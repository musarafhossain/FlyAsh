import { BaseSchema } from '@adonisjs/lucid/schema'

/**
 * The user's language for API messages and emails: 'en' | 'bn'.
 */
export default class extends BaseSchema {
  protected tableName = 'users'

  async up() {
    this.schema.alterTable(this.tableName, (table) => {
      table.string('locale', 5).notNullable().defaultTo('en').after('password')
    })
  }

  async down() {
    this.schema.alterTable(this.tableName, (table) => {
      table.dropColumn('locale')
    })
  }
}
