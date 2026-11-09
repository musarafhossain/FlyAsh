import { BaseSchema } from '@adonisjs/lucid/schema'

export default class extends BaseSchema {
  protected tableName = 'users'

  async up() {
    this.schema.createTable(this.tableName, (table) => {
      table.uuid('id').primary()
      table.string('name', 100).notNullable()
      table.string('phone', 15).notNullable().unique()
      table.string('email', 150).nullable().unique()
      table.string('password').notNullable()
      table.boolean('is_active').notNullable().defaultTo(true)
      table.dateTime('last_login_at').nullable()
      table.uuid('created_by').nullable().references('id').inTable('users')
      table.dateTime('created_at').notNullable()
      table.dateTime('updated_at').notNullable()
    })
  }

  async down() {
    this.schema.dropTable(this.tableName)
  }
}
