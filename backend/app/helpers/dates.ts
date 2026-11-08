import env from '#start/env'
import { DateTime } from 'luxon'

/**
 * Business dates ("today", months) are calculated in the factory timezone
 * (APP_TIMEZONE, e.g. Asia/Kolkata). Timestamps are stored in UTC.
 */
export function zone() {
  return env.get('APP_TIMEZONE')
}

export function now() {
  return DateTime.now().setZone(zone())
}

/** Today's date in the factory timezone: "2026-11-08" */
export function today(): string {
  return now().toISODate()!
}

/** Current month: "2026-11" */
export function currentMonth(): string {
  return now().toFormat('yyyy-MM')
}

/** "2026-11" → { start: "2026-11-01", end: "2026-11-30", days: 30 } */
export function monthRange(month: string) {
  const start = DateTime.fromFormat(month, 'yyyy-MM', { zone: zone() })
  return {
    start: start.toISODate()!,
    end: start.endOf('month').toISODate()!,
    days: start.daysInMonth!,
  }
}

/** Number of days in the month of a "YYYY-MM-DD" date. */
export function daysInMonthOf(date: string): number {
  return DateTime.fromISO(date, { zone: zone() }).daysInMonth!
}

/** First day of the current month: "2026-11-01" */
export function startOfMonth(): string {
  return now().startOf('month').toISODate()!
}
