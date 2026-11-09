import { BaseSchema } from '@adonisjs/lucid/schema'

export default class extends BaseSchema {
  protected tableName = 'app_versions'

  async up() {
    this.schema.createTable(this.tableName, (table) => {
      table.uuid('id').primary()
      table.string('platform', 20).notNullable()
      table.string('version_name', 20).notNullable()
      table.integer('build_number').unsigned().notNullable()
      table.integer('min_supported_build').unsigned().notNullable()
      table.string('download_url', 500).nullable()
      table.text('release_notes').nullable()
      table.boolean('is_active').notNullable().defaultTo(true)
      table.dateTime('created_at').notNullable()
      table.dateTime('updated_at').notNullable()

      table.unique(['platform', 'build_number'])
    })
  }

  async down() {
    this.schema.dropTable(this.tableName)
  }
}
