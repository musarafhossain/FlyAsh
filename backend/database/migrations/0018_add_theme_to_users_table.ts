import { BaseSchema } from '@adonisjs/lucid/schema'

/**
 * The user's appearance, saved to the account so it follows them to every device:
 *   theme_mode:   'system' | 'light' | 'dark'
 *   accent_color: 'blue' | 'brick' | 'emerald' | 'violet' | 'slate'
 */
export default class extends BaseSchema {
  protected tableName = 'users'

  async up() {
    this.schema.alterTable(this.tableName, (table) => {
      table.string('theme_mode', 10).notNullable().defaultTo('system').after('locale')
      table.string('accent_color', 20).notNullable().defaultTo('blue').after('theme_mode')
    })
  }

  async down() {
    this.schema.alterTable(this.tableName, (table) => {
      table.dropColumn('accent_color')
      table.dropColumn('theme_mode')
    })
  }
}
