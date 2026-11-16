import { DateTime } from 'luxon'
import Labour from '#models/labour'
import Attendance from '#models/attendance'
import WagePayment from '#models/wage_payment'
import { fromPaise, toPaise } from '#helpers/money'
import { monthRange, today } from '#helpers/dates'

type WageRowSnapshot = Pick<Attendance, 'wageType' | 'wageAmount' | 'date'>

/**
 * Wage earned by one labour's present days (attendance rows), in paise
 * (01-PRD §6.3, changed on 2026-11-16 at the owner's request):
 *   daily   → each present day earns that day's saved wage
 *   monthly → the FULL monthly wage for every month with at least one
 *             present day (not divided by the days); when the wage changed
 *             during the month, the latest saved amount counts.
 */
export function earnedForRows(rows: WageRowSnapshot[]): number {
  return [...earnedByDay(rows).values()].reduce((sum, paise) => sum + paise, 0)
}

/**
 * The same split per day, for day lists: a daily day earns its wage; a
 * monthly month's wage sits on its first present day (0 on the others), so
 * the days add up to the month's total.
 */
export function earnedByDay(rows: WageRowSnapshot[]): Map<string, number> {
  const byDay = new Map<string, number>()
  const months = new Map<string, { first: string; latest: string; amount: number }>()
  for (const row of rows) {
    if (row.wageType === 'daily') {
      byDay.set(row.date, toPaise(row.wageAmount))
      continue
    }
    byDay.set(row.date, 0)
    const ym = row.date.slice(0, 7)
    const m = months.get(ym)
    if (!m) {
      months.set(ym, { first: row.date, latest: row.date, amount: toPaise(row.wageAmount) })
    } else {
      if (row.date < m.first) m.first = row.date
      if (row.date > m.latest) {
        m.latest = row.date
        m.amount = toPaise(row.wageAmount)
      }
    }
  }
  for (const m of months.values()) byDay.set(m.first, (byDay.get(m.first) ?? 0) + m.amount)
  return byDay
}

export type WageRow = {
  labour_id: string
  name: string
  wage_type: string
  wage_amount: string
  is_active: boolean
  present_days: number
  /** Employed days so far in the month without a present mark */
  absent_days: number
  earned: string
  paid: string
  balance: string
  status: 'paid' | 'partial' | 'due'
}

/**
 * Monthly wages (01-PRD §6.3).
 *   earned  = daily: Σ each present day's wage; monthly: the full monthly
 *             wage when present at least one day (see earnedForRows)
 *   balance = earned − wage payments for the month (no separate advances)
 */
export default class WageService {
  /** Wage rows for every labour employed at any time in the month. */
  static async sheet(month: string): Promise<WageRow[]> {
    const { start, end } = monthRange(month)

    const labours = await Labour.query()
      .where('joining_date', '<=', end)
      .where((q) => q.whereNull('left_date').orWhere('left_date', '>=', start))
      .orderBy('name', 'asc')

    return this.rowsFor(labours, month)
  }

  /** Wage row for one labour plus day-by-day attendance and payments. */
  static async detail(labour: Labour, month: string) {
    const { start, end } = monthRange(month)
    const [row] = await this.rowsFor([labour], month)

    const attendances = await Attendance.query()
      .where('labour_id', labour.id)
      .whereBetween('date', [start, end])
      .orderBy('date', 'desc') // newest day first

    const payments = await WagePayment.query()
      .where('labour_id', labour.id)
      .where('wage_month', start)
      .preload('creator', (q) => q.select('id', 'name'))
      .orderBy('payment_date', 'desc') // newest payment first

    const perDay = earnedByDay(attendances)
    return {
      ...row,
      month,
      days: attendances.map((a) => ({
        date: a.date,
        earned: fromPaise(perDay.get(a.date) ?? 0),
      })),
      payments,
    }
  }

  /**
   * Total wages earned between two dates (for net profit). Rounded per
   * labour, the same way as the wage sheet, so the two always match.
   */
  static async earnedBetween(from: string, to: string): Promise<number> {
    const rows = await Attendance.query().whereBetween('date', [from, to])
    const perLabour = new Map<string, Attendance[]>()
    for (const row of rows) {
      perLabour.set(row.labourId, [...(perLabour.get(row.labourId) ?? []), row])
    }
    return [...perLabour.values()].reduce((sum, mine) => sum + earnedForRows(mine), 0)
  }

  private static async rowsFor(labours: Labour[], month: string): Promise<WageRow[]> {
    if (labours.length === 0) return []
    const { start, end } = monthRange(month)
    const ids = labours.map((l) => l.id)

    const attendances = await Attendance.query()
      .whereIn('labour_id', ids)
      .whereBetween('date', [start, end])
    const payments = await WagePayment.query().whereIn('labour_id', ids).where('wage_month', start)

    return labours.map((labour) => {
      const mine = attendances.filter((a) => a.labourId === labour.id)
      const earned = earnedForRows(mine)
      const paid = payments
        .filter((p) => p.labourId === labour.id)
        .reduce((sum, p) => sum + toPaise(p.amount), 0)
      const balance = earned - paid

      return {
        labour_id: labour.id,
        name: labour.name,
        wage_type: labour.wageType,
        wage_amount: labour.wageAmount,
        is_active: labour.isActive,
        present_days: mine.length,
        absent_days: Math.max(0, this.employedDays(labour, start, end) - mine.length),
        earned: fromPaise(earned),
        paid: fromPaise(paid),
        balance: fromPaise(balance),
        status: earned > 0 && paid === 0 ? 'due' : balance > 0 ? 'partial' : 'paid',
      }
    })
  }

  /** Days in the month (up to today) on which the labour was employed. */
  static employedDays(labour: Labour, start: string, end: string) {
    const from = [start, labour.joiningDate].sort().at(-1)!
    const to = [end, today(), labour.leftDate ?? end].sort()[0]
    if (to < from) return 0
    return DateTime.fromISO(to).diff(DateTime.fromISO(from), 'days').days + 1
  }
}
