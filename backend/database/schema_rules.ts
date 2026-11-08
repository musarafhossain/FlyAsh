import { type SchemaRules } from '@adonisjs/lucid/types/schema_generator'

const hidden = (tsType: string) => ({
  tsType,
  imports: [],
  decorators: [{ name: '@column', args: { serializeAs: null } }],
})

export default {
  types: {
    /**
     * DATE columns are returned by mysql2 as 'YYYY-MM-DD' strings
     * (see `dateStrings` in config/database.ts), so they are plain strings
     * in the models too. This avoids any timezone shifting of business dates.
     */
    date: {
      tsType: 'string',
      imports: [],
      decorators: [{ name: '@column' }],
    },
  },
  columns: {
    /**
     * The numeric FK is hidden; models expose a `creator` relation that is
     * serialized as `created_by: { id, name }` when preloaded.
     */
    created_by: hidden('number'),
    otp_hash: hidden('string'),
  },
  tables: {
    sales: {
      columns: {
        deleted_at: {
          tsType: 'DateTime',
          imports: [{ source: 'luxon', namedImports: ['DateTime'] }],
          decorators: [{ name: '@column.dateTime', args: { serializeAs: null } }],
        },
      },
    },
  },
} satisfies SchemaRules
