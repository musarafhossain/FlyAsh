import { test } from '@japa/runner'
import { readFileSync } from 'node:fs'
import app from '@adonisjs/core/services/app'

function keys(value: unknown, prefix = ''): string[] {
  if (value && typeof value === 'object') {
    return Object.entries(value).flatMap(([k, v]) => keys(v, prefix ? `${prefix}.${k}` : k))
  }
  return [prefix]
}

function load(locale: string, file: string) {
  return JSON.parse(readFileSync(app.languageFilesPath(locale, `${file}.json`), 'utf8'))
}

test.group('Translations', () => {
  for (const file of ['messages', 'validator']) {
    test(`en and bn ${file}.json have the same keys`, ({ assert }) => {
      const en = keys(load('en', file)).sort()
      const bn = keys(load('bn', file)).sort()
      assert.deepEqual(
        bn.filter((k) => !en.includes(k)),
        [],
        'keys only in bn'
      )
      assert.deepEqual(
        en.filter((k) => !bn.includes(k)),
        [],
        'keys missing in bn'
      )
    })
  }
})
