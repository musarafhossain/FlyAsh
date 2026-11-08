import { test } from '@japa/runner'
import { Settings } from 'luxon'
import { currentMonth, monthRange, today } from '#helpers/dates'

/**
 * Business dates use the factory timezone (APP_TIMEZONE = Asia/Kolkata, UTC+5:30),
 * not the server's UTC clock.
 */
test.group('Business dates (factory timezone)', (group) => {
  group.each.teardown(() => {
    Settings.now = () => Date.now()
  })

  test('today() switches at midnight IST, not midnight UTC', ({ assert }) => {
    // 18:29 UTC = 23:59 IST on 8 Nov
    Settings.now = () => Date.parse('2026-11-08T18:29:00Z')
    assert.equal(today(), '2026-11-08')

    // 18:30 UTC = 00:00 IST on 9 Nov (UTC is still 8 Nov)
    Settings.now = () => Date.parse('2026-11-08T18:30:00Z')
    assert.equal(today(), '2026-11-09')
  })

  test('the month also changes at midnight IST', ({ assert }) => {
    Settings.now = () => Date.parse('2026-11-30T19:00:00Z') // 1 Dec 00:30 IST
    assert.equal(currentMonth(), '2026-12')
  })

  test('monthRange gives first/last day and day count', ({ assert }) => {
    assert.deepEqual(monthRange('2026-10'), { start: '2026-10-01', end: '2026-10-31', days: 31 })
    assert.deepEqual(monthRange('2028-02'), { start: '2028-02-01', end: '2028-02-29', days: 29 })
  })
})
