import type { HttpContext } from '@adonisjs/core/http'
import db from '@adonisjs/lucid/services/db'
import { DateTime } from 'luxon'
import Labour from '#models/labour'
import Attendance from '#models/attendance'
import AppError from '#exceptions/app_error'
import { ok } from '#helpers/api_response'
import { currentMonth, monthRange, today } from '#helpers/dates'
import { attendanceDayValidator, monthValidator, saveAttendanceValidator } from '#validators/labour'

export default class AttendanceController {
  /**
   * GET /attendance?date=YYYY-MM-DD: all labours employed on that date with
   * their saved status (null = not marked).
   */
  async show({ request, response }: HttpContext) {
    const { date = today() } = await request.validateUsing(attendanceDayValidator)
    return ok(response, await this.day(date), 'Attendance fetched successfully')
  }

  /**
   * PUT /attendance { date, records: [{ labour_id, status }] }
   * New rows store the labour's current wage as a snapshot; existing rows
   * keep their snapshot and only change status. status null clears the day.
   */
  async save({ auth, request, response }: HttpContext) {
    const { date, records } = await request.validateUsing(saveAttendanceValidator)
    const userId = auth.getUserOrFail().id

    const ids = records.map((r) => r.labour_id)
    const labours = await Labour.activeOn(Labour.query(), date).whereIn('id', ids)
    const byId = new Map(labours.map((l) => [l.id, l]))

    const invalid = ids.filter((id) => !byId.has(id))
    if (invalid.length > 0) {
      throw new AppError(`Labour(s) ${invalid.join(', ')} were not employed on ${date}`)
    }

    await db.transaction(async (trx) => {
      for (const record of records) {
        const existing = await Attendance.query({ client: trx })
          .where('labour_id', record.labour_id)
          .where('date', date)
          .first()

        if (record.status === null) {
          if (existing) await existing.delete()
          continue
        }

        if (existing) {
          existing.merge({ status: record.status, createdBy: userId })
          await existing.save()
        } else {
          const labour = byId.get(record.labour_id)!
          await Attendance.create(
            {
              labourId: labour.id,
              date,
              status: record.status,
              wageType: labour.wageType,
              wageAmount: labour.wageAmount,
              createdBy: userId,
            },
            { client: trx }
          )
        }
      }
    })

    return ok(response, await this.day(date), `Attendance saved for ${date}`)
  }

  /**
   * GET /labours/:id/attendance?month=YYYY-MM: one labour's calendar.
   */
  async labourMonth({ params, request, response }: HttpContext) {
    const labour = await Labour.findOrFail(params.id)
    const { month = currentMonth() } = await request.validateUsing(monthValidator)
    const { start, end } = monthRange(month)

    const rows = await Attendance.query()
      .where('labour_id', labour.id)
      .whereBetween('date', [start, end])
    const byDate = new Map(rows.map((r) => [r.date, r.status]))

    const days: { date: string; status: string | null }[] = []
    for (let d = DateTime.fromISO(start); d.toISODate()! <= end; d = d.plus({ days: 1 })) {
      const date = d.toISODate()!
      days.push({ date, status: byDate.get(date) ?? null })
    }

    return ok(
      response,
      {
        labour_id: labour.id,
        month,
        days,
        summary: {
          present: rows.filter((r) => r.status === 'present').length,
          half_day: rows.filter((r) => r.status === 'half_day').length,
          absent: rows.filter((r) => r.status === 'absent').length,
        },
      },
      'Attendance fetched successfully'
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
    const statusOf = new Map(rows.map((r) => [r.labourId, r.status]))

    const items = labours.map((labour) => ({
      labour_id: labour.id,
      name: labour.name,
      wage_type: labour.wageType,
      wage_amount: labour.wageAmount,
      status: statusOf.get(labour.id) ?? null,
    }))

    return {
      date,
      summary: {
        total: items.length,
        present: items.filter((i) => i.status === 'present').length,
        half_day: items.filter((i) => i.status === 'half_day').length,
        absent: items.filter((i) => i.status === 'absent').length,
        not_marked: items.filter((i) => i.status === null).length,
      },
      items,
    }
  }
}
