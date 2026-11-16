import { test } from '@japa/runner'
import { earnedByDay, earnedForRows } from '#services/wage_service'

/**
 * The wage rule (01-PRD §6.3, 2026-11-16), on attendance snapshots:
 *   daily   → each present day earns that day's saved wage
 *   monthly → the FULL monthly wage once for every month with at least one
 *             present day (latest saved amount in that month), not ÷ days
 * Results are in paise.
 */
const d = (date: string, amount: string) => ({ wageType: 'daily', wageAmount: amount, date })
const m = (date: string, amount: string) => ({ wageType: 'monthly', wageAmount: amount, date })

test.group('Wage rule · daily', () => {
  test('no present day earns nothing', ({ assert }) => {
    assert.equal(earnedForRows([]), 0)
  })

  test('each present day earns its saved wage', ({ assert }) => {
    const rows = [d('2026-10-01', '500.00'), d('2026-10-02', '500.00'), d('2026-10-03', '500.00')]
    assert.equal(earnedForRows(rows), 150_000) // 3 × 500
  })

  test('a raise mid-month only changes the days saved after it', ({ assert }) => {
    const rows = [d('2026-10-01', '500.00'), d('2026-10-02', '500.00'), d('2026-10-03', '550.00')]
    assert.equal(earnedForRows(rows), 155_000) // 500 + 500 + 550
  })

  test('paise are kept exactly (no rounding drift)', ({ assert }) => {
    const rows = [d('2026-10-01', '450.50'), d('2026-10-02', '450.25'), d('2026-10-03', '0.25')]
    assert.equal(earnedForRows(rows), 90_100) // 901.00
  })

  test('the day list is each day’s own wage', ({ assert }) => {
    const byDay = earnedByDay([d('2026-10-01', '500.00'), d('2026-10-05', '600.00')])
    assert.deepEqual(Object.fromEntries(byDay), { '2026-10-01': 50_000, '2026-10-05': 60_000 })
  })
})

test.group('Wage rule · monthly', () => {
  test('one present day earns the FULL month (not ÷ days)', ({ assert }) => {
    assert.equal(earnedForRows([m('2026-11-16', '8000.00')]), 800_000)
  })

  test('many present days in a month still earn the month once', ({ assert }) => {
    const rows = Array.from({ length: 26 }, (_, i) =>
      m(`2026-10-${String(i + 1).padStart(2, '0')}`, '16000.00')
    )
    assert.equal(earnedForRows(rows), 1_600_000)
  })

  test('every month with a present day counts, months without do not', ({ assert }) => {
    // Present in Sep (1 day) and Nov (3 days), absent all of October
    const rows = [
      m('2026-09-30', '8000.00'),
      m('2026-11-01', '8000.00'),
      m('2026-11-02', '8000.00'),
      m('2026-11-20', '8000.00'),
    ]
    assert.equal(earnedForRows(rows), 1_600_000) // Sep + Nov
  })

  test('a raise in the month: the latest saved amount counts', ({ assert }) => {
    const rows = [m('2026-10-01', '31000.00'), m('2026-10-02', '31000.00'), m('2026-10-20', '62000.00')]
    assert.equal(earnedForRows(rows), 6_200_000)
  })

  test('a cut in the month: the latest saved amount counts too', ({ assert }) => {
    const rows = [m('2026-10-01', '20000.00'), m('2026-10-25', '18000.00')]
    assert.equal(earnedForRows(rows), 1_800_000)
  })

  test('row order does not matter', ({ assert }) => {
    const rows = [m('2026-10-20', '62000.00'), m('2026-10-01', '31000.00')]
    assert.equal(earnedForRows(rows), 6_200_000)
  })

  test('the month’s wage sits on its first present day; the days add up', ({ assert }) => {
    const rows = [m('2026-10-03', '62000.00'), m('2026-10-01', '31000.00'), m('2026-10-02', '31000.00')]
    const byDay = earnedByDay(rows)
    assert.deepEqual(Object.fromEntries(byDay), {
      '2026-10-01': 6_200_000,
      '2026-10-02': 0,
      '2026-10-03': 0,
    })
    assert.equal([...byDay.values()].reduce((a, b) => a + b, 0), earnedForRows(rows))
  })

  test('month boundaries: 31 Oct and 1 Nov are two months', ({ assert }) => {
    assert.equal(earnedForRows([m('2026-10-31', '9000.00'), m('2026-11-01', '9000.00')]), 1_800_000)
  })

  test('same month in different years are different months', ({ assert }) => {
    assert.equal(earnedForRows([m('2025-11-05', '7000.00'), m('2026-11-05', '8000.00')]), 1_500_000)
  })
})

test.group('Wage rule · mixed', () => {
  test('switched from daily to monthly mid-month: daily days + the full month', ({ assert }) => {
    const rows = [
      d('2026-10-01', '500.00'),
      d('2026-10-02', '500.00'),
      m('2026-10-15', '15000.00'),
      m('2026-10-16', '15000.00'),
    ]
    assert.equal(earnedForRows(rows), 1_600_000) // 1,000 + 15,000
  })

  test('a monthly labour’s custom-wage day (saved as daily) adds on top', ({ assert }) => {
    // Older data: a day saved with its own wage before monthly ignored it
    const rows = [m('2026-10-01', '15000.00'), d('2026-10-02', '700.00')]
    assert.equal(earnedForRows(rows), 1_570_000)
  })
})
