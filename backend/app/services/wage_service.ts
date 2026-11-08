import { DateTime } from 'luxon'
import Labour from '#models/labour'
import Attendance from '#models/attendance'
import LabourAdvance from '#models/labour_advance'
import WagePayment from '#models/wage_payment'
import { fromPaise, toPaise } from '#helpers/money'
import { daysInMonthOf, monthRange, today } from '#helpers/dates'

/** Present = 1 day, Half day = 0.5, Absent = 0 */
export function dayValue(status: string) {
  return status === 'present' ? 1 : status === 'half_day' ? 0.5 : 0
}

/**
 * Wage earned for one attendance row, in (fractional) paise.
 * Uses the wage snapshot stored on the attendance row.
 * Monthly wage → per day = monthly wage ÷ days in that month.
 */
export function earnedPaise(row: Pick<Attendance, 'status' | 'wageType' | 'wageAmount' | 'date'>) {
  const rate =
    row.wageType === 'daily'
      ? toPaise(row.wageAmount)
      : toPaise(row.wageAmount) / daysInMonthOf(row.date)
  return dayValue(row.status) * rate
}

export type WageRow = {
  labour_id: number
  name: string
  wage_type: string
  wage_amount: string
  is_active: boolean
  present_days: number
  half_days: number
  absent_days: number
  not_marked_days: number
  worked_days: string
  earned: string
  advances: string
  paid: string
  balance: string
  status: 'paid' | 'partial' | 'due'
}

/**
 * Monthly wages (01-PRD §6.3).
 *   earned  = Σ day value × daily rate (from attendance snapshots)
 *   balance = earned − advances given in the month − payments for the month
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

  /** Wage row for one labour plus day-by-day attendance, advances and payments. */
  static async detail(labour: Labour, month: string) {
    const { start, end } = monthRange(month)
    const [row] = await this.rowsFor([labour], month)

    const attendances = await Attendance.query()
      .where('labour_id', labour.id)
      .whereBetween('date', [start, end])
      .orderBy('date', 'asc')

    const advances = await LabourAdvance.query()
      .where('labour_id', labour.id)
      .whereBetween('advance_date', [start, end])
      .preload('creator', (q) => q.select('id', 'name'))
      .orderBy('advance_date', 'asc')

    const payments = await WagePayment.query()
      .where('labour_id', labour.id)
      .where('wage_month', start)
      .preload('creator', (q) => q.select('id', 'name'))
      .orderBy('payment_date', 'asc')

    return {
      ...row,
      month,
      days: attendances.map((a) => ({
        date: a.date,
        status: a.status,
        earned: fromPaise(Math.round(earnedPaise(a))),
      })),
      advances,
      payments,
    }
  }

  /**
   * Total wages earned between two dates (for net profit). Rounded per
   * labour, the same way as the wage sheet, so the two always match.
   */
  static async earnedBetween(from: string, to: string): Promise<number> {
    const rows = await Attendance.query().whereBetween('date', [from, to])
    const perLabour = new Map<number, number>()
    for (const row of rows) {
      perLabour.set(row.labourId, (perLabour.get(row.labourId) ?? 0) + earnedPaise(row))
    }
    return [...perLabour.values()].reduce((sum, value) => sum + Math.round(value), 0)
  }

  private static async rowsFor(labours: Labour[], month: string): Promise<WageRow[]> {
    if (labours.length === 0) return []
    const { start, end } = monthRange(month)
    const ids = labours.map((l) => l.id)

    const attendances = await Attendance.query()
      .whereIn('labour_id', ids)
      .whereBetween('date', [start, end])
    const advances = await LabourAdvance.query()
      .whereIn('labour_id', ids)
      .whereBetween('advance_date', [start, end])
    const payments = await WagePayment.query().whereIn('labour_id', ids).where('wage_month', start)

    return labours.map((labour) => {
      const mine = attendances.filter((a) => a.labourId === labour.id)
      const earned = Math.round(mine.reduce((sum, a) => sum + earnedPaise(a), 0))
      const advanced = advances
        .filter((a) => a.labourId === labour.id)
        .reduce((sum, a) => sum + toPaise(a.amount), 0)
      const paid = payments
        .filter((p) => p.labourId === labour.id)
        .reduce((sum, p) => sum + toPaise(p.amount), 0)
      const balance = earned - advanced - paid
      const worked = mine.reduce((sum, a) => sum + dayValue(a.status), 0)

      return {
        labour_id: labour.id,
        name: labour.name,
        wage_type: labour.wageType,
        wage_amount: labour.wageAmount,
        is_active: labour.isActive,
        present_days: mine.filter((a) => a.status === 'present').length,
        half_days: mine.filter((a) => a.status === 'half_day').length,
        absent_days: mine.filter((a) => a.status === 'absent').length,
        not_marked_days: Math.max(0, this.employedDays(labour, start, end) - mine.length),
        worked_days: worked.toFixed(2),
        earned: fromPaise(earned),
        advances: fromPaise(advanced),
        paid: fromPaise(paid),
        balance: fromPaise(balance),
        status: earned > 0 && advanced + paid === 0 ? 'due' : balance > 0 ? 'partial' : 'paid',
      }
    })
  }

  /** Days in the month (up to today) on which the labour was employed. */
  private static employedDays(labour: Labour, start: string, end: string) {
    const from = [start, labour.joiningDate].sort().at(-1)!
    const to = [end, today(), labour.leftDate ?? end].sort()[0]
    if (to < from) return 0
    return DateTime.fromISO(to).diff(DateTime.fromISO(from), 'days').days + 1
  }
}
