import { BaseSchema } from '@adonisjs/lucid/schema'

/**
 * New users start with the Brick Terracotta accent (it was Royal Blue).
 * Existing users keep the colour saved on their account.
 */
export default class extends BaseSchema {
  protected tableName = 'users'

  async up() {
    this.schema.alterTable(this.tableName, (table) => {
      table.string('accent_color', 20).notNullable().defaultTo('brick').alter()
    })
  }

  async down() {
    this.schema.alterTable(this.tableName, (table) => {
      table.string('accent_color', 20).notNullable().defaultTo('blue').alter()
    })
  }
}
