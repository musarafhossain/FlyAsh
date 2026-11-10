import type { HttpContext } from '@adonisjs/core/http'
import db from '@adonisjs/lucid/services/db'
import { DateTime } from 'luxon'
import Labour from '#models/labour'
import Attendance from '#models/attendance'
import AppError from '#exceptions/app_error'
import { ok } from '#helpers/api_response'
import WageService from '#services/wage_service'
import { currentMonth, monthRange, today } from '#helpers/dates'
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
   * PUT /attendance { date, records: [{ labour_id, present }] }
   * present → a row is saved with the labour's current wage as a snapshot
   * (an existing row keeps its snapshot); absent → the row is removed.
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
          await Attendance.create(
            {
              labourId: labour.id,
              date,
              wageType: labour.wageType,
              wageAmount: labour.wageAmount,
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
    const present = new Set(rows.map((r) => r.labourId))

    const items = labours.map((labour) => ({
      labour_id: labour.id,
      name: labour.name,
      wage_type: labour.wageType,
      wage_amount: labour.wageAmount,
      present: present.has(labour.id),
    }))

    const presentCount = items.filter((i) => i.present).length
    return {
      date,
      summary: { total: items.length, present: presentCount, absent: items.length - presentCount },
      items,
    }
  }
}
