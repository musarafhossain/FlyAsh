import type { HttpContext } from '@adonisjs/core/http'
import db from '@adonisjs/lucid/services/db'
import { DateTime } from 'luxon'
import Labour from '#models/labour'
import Attendance from '#models/attendance'
import AppError from '#exceptions/app_error'
import { ok } from '#helpers/api_response'
import WageService, { earnedPaise } from '#services/wage_service'
import { fromPaise, toPaise } from '#helpers/money'
import { currentMonth, daysInMonthOf, monthRange, today } from '#helpers/dates'
import { attendanceDayValidator, monthValidator, saveAttendanceValidator } from '#validators/labour'

export default class AttendanceController {
  /**
   * GET /attendance?date=YYYY-MM-DD: all labours employed on that date and
   * whether each is present.
   */
  async show({ request, response }: HttpContext) {
    const { date = today() } = await request.validateUsing(attendanceDayValidator)
    return ok(response, await this.day(date), 'attendance.fetched')
  }

  /**
   * PUT /attendance { date, records: [{ labour_id, present, wage? }] }
   * present → a row is saved with the labour's current wage as a snapshot,
   * or with `wage` as that day's daily wage when given (an existing row
   * keeps its snapshot); absent → the row is removed.
   */
  async save({ auth, request, response }: HttpContext) {
    const { date, records } = await request.validateUsing(saveAttendanceValidator)
    const userId = auth.getUserOrFail().id

    const ids = records.map((r) => r.labour_id)
    const labours = await Labour.activeOn(Labour.query(), date).whereIn('id', ids)
    const byId = new Map(labours.map((l) => [l.id, l]))

    const invalid = ids.filter((id) => !byId.has(id))
    if (invalid.length > 0) {
      throw new AppError('attendance.not_employed', 400, null, { ids: invalid.join(', '), date })
    }

    await db.transaction(async (trx) => {
      for (const record of records) {
        const existing = await Attendance.query({ client: trx })
          .where('labour_id', record.labour_id)
          .where('date', date)
          .first()

        if (!record.present) {
          if (existing) await existing.delete()
        } else if (!existing) {
          const labour = byId.get(record.labour_id)!
          const custom = record.wage !== undefined
          await Attendance.create(
            {
              labourId: labour.id,
              date,
              wageType: custom ? 'daily' : labour.wageType,
              wageAmount: custom ? fromPaise(toPaise(record.wage)) : labour.wageAmount,
              createdBy: userId,
            },
            { client: trx }
          )
        }
      }
    })

    return ok(response, await this.day(date), 'attendance.saved', 200, { date })
  }

  /**
   * GET /labours/:id/attendance?month=YYYY-MM: one labour's calendar.
   * Absent = an employed day (up to today) without a present mark.
   */
  async labourMonth({ params, request, response }: HttpContext) {
    const labour = await Labour.findOrFail(params.id)
    const { month = currentMonth() } = await request.validateUsing(monthValidator)
    const { start, end } = monthRange(month)

    const rows = await Attendance.query()
      .where('labour_id', labour.id)
      .whereBetween('date', [start, end])
    const presentOn = new Set(rows.map((r) => r.date))

    const days: { date: string; present: boolean }[] = []
    for (let d = DateTime.fromISO(start); d.toISODate()! <= end; d = d.plus({ days: 1 })) {
      const date = d.toISODate()!
      days.push({ date, present: presentOn.has(date) })
    }

    return ok(
      response,
      {
        labour_id: labour.id,
        month,
        days,
        summary: {
          present: rows.length,
          absent: Math.max(0, WageService.employedDays(labour, start, end) - rows.length),
        },
      },
      'attendance.fetched'
    )
  }

  private async day(date: string) {
    const labours = await Labour.activeOn(Labour.query(), date).orderBy('name', 'asc')
    const rows = await Attendance.query()
      .where('date', date)
      .whereIn(
        'labour_id',
        labours.map((l) => l.id)
      )
    const rowOf = new Map(rows.map((r) => [r.labourId, r]))

    // day_wage: the saved day's wage when present, else the labour's wage
    // for one day (monthly ÷ days in that month).
    const items = labours.map((labour) => {
      const row = rowOf.get(labour.id)
      const dayPaise = row
        ? earnedPaise(row)
        : labour.wageType === 'daily'
          ? toPaise(labour.wageAmount)
          : toPaise(labour.wageAmount) / daysInMonthOf(date)
      return {
        labour_id: labour.id,
        name: labour.name,
        wage_type: labour.wageType,
        wage_amount: labour.wageAmount,
        present: row !== undefined,
        day_wage: fromPaise(Math.round(dayPaise)),
      }
    })

    const presentCount = items.filter((i) => i.present).length
    return {
      date,
      summary: { total: items.length, present: presentCount, absent: items.length - presentCount },
      items,
    }
  }
}
