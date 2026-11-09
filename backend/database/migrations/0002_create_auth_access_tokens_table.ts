import { BaseSchema } from '@adonisjs/lucid/schema'

export default class extends BaseSchema {
  protected tableName = 'auth_access_tokens'

  async up() {
    this.schema.createTable(this.tableName, (table) => {
      // Stays numeric: the Adonis token value embeds this id. tokenable_id is the user's UUID.
      table.increments('id')
      table.uuid('tokenable_id').notNullable().references('id').inTable('users').onDelete('CASCADE')
      table.string('type').notNullable()
      table.string('name').nullable()
      table.string('hash').notNullable().unique()
      table.text('abilities').notNullable()
      table.dateTime('created_at').nullable()
      table.dateTime('updated_at').nullable()
      table.dateTime('last_used_at').nullable()
      table.dateTime('expires_at').nullable()
    })
  }

  async down() {
    this.schema.dropTable(this.tableName)
  }
}
