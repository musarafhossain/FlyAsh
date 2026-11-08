import env from '#start/env'
import { defineConfig } from '@adonisjs/lucid'

const dbConfig = defineConfig({
  connection: 'mysql',

  connections: {
    mysql: {
      client: 'mysql2',
      connection: {
        host: env.get('DB_HOST'),
        port: env.get('DB_PORT'),
        user: env.get('DB_USER'),
        password: env.get('DB_PASSWORD'),
        database: env.get('DB_DATABASE'),
        charset: 'utf8mb4',
        /**
         * Timestamps are stored in UTC.
         */
        timezone: 'Z',
        /**
         * Return DATE columns as 'YYYY-MM-DD' strings (no timezone shifting).
         * DECIMAL columns are returned as strings by mysql2 by default.
         */
        dateStrings: ['DATE'],
        /**
         * TINYINT(1) columns are booleans.
         */
        typeCast: ((field: any, next: () => unknown) => {
          if (field.type === 'TINY' && field.length === 1) {
            const value = field.string()
            return value === null ? null : value === '1'
          }
          return next()
        }) as any,
      },
      migrations: {
        naturalSort: true,
        paths: ['database/migrations'],
      },
      schemaGeneration: {
        enabled: true,
        rulesPaths: ['./database/schema_rules.js'],
      },
      debug: false,
    },
  },
})

export default dbConfig
