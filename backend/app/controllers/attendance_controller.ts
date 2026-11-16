import type { HttpContext } from '@adonisjs/core/http'
import db from '@adonisjs/lucid/services/db'
import { DateTime } from 'luxon'
import Labour from '#models/labour'
import Attendance from '#models/attendance'
import AppError from '#exceptions/app_error'
import { ok } from '#helpers/api_response'
import { DEFAULT_LIMIT } from '#validators/rules'
import WageService, { earnedPaise } from '#services/wage_service'
import { fromPaise, toPaise } from '#helpers/money'
import { currentMonth, daysInMonthOf, monthRange, today } from '#helpers/dates'
import { attendanceDayValidator, monthValidator, saveAttendanceValidator } from '#validators/labour'

/** Old apps (before paged attendance) expect every labour of the day. */
const LEGACY_ALL = 1000

export default class AttendanceController {
  /**
   * GET /attendance?date=YYYY-MM-DD&page&limit&search: the labours employed
   * on that date (20 a page, by name; search on the name) and whether each
   * is present. `summary` counts every labour of the day, not only the page.
   */
  async show({ request, response }: HttpContext) {
    const { date = today(), page, limit, search } = await request.validateUsing(attendanceDayValidator)
    // Without `page` (apps older than 1.1.2): every labour, like before.
    const paging =
      page === undefined
        ? { page: 1, limit: LEGACY_ALL, search }
        : { page, limit: limit ?? DEFAULT_LIMIT, search }
    return ok(response, await this.day(date, paging), 'attendance.fetched')
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

    // `rows: "saved"` (the app since 1.1.2): only the saved labours' rows and
    // the day's summary, merged into the page it shows. Older apps get
    // every labour of the day, like before.
    const onlySaved = request.input('rows') === 'saved' // body or query
    const day = await this.day(date, onlySaved ? { ids } : { limit: LEGACY_ALL })
    return ok(response, day, 'attendance.saved', 200, { date })
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

  /**
   * The day's rows: a page (with `page`/`limit`, optionally filtered by
   * `search`) or the labours in `ids`; `summary` always covers every labour
   * employed that day.
   */
  private async day(
    date: string,
    options: { page?: number; limit?: number; search?: string; ids?: string[] } = {}
  ) {
    const query = Labour.activeOn(Labour.query(), date).orderBy('name', 'asc').orderBy('id')
    if (options.ids) query.whereIn('id', options.ids)
    if (options.search) query.where('name', 'like', `%${options.search}%`)
    const page = options.page ?? 1
    const limit = options.ids ? Math.max(options.ids.length, 1) : (options.limit ?? DEFAULT_LIMIT)
    const paginator = await query.paginate(page, limit)
    const labours = paginator.all()
    const rows = await Attendance.query()
      .where('date', date)
      .whereIn(
        'labour_id',
        labours.map((l) => l.id)
      )
    const rowOf = new Map(rows.map((r) => [r.labourId, r]))

    // day_wage: the saved day's wage when present, else default_day_wage
    // (the labour's wage for one day; monthly ÷ days in that month).
    const items = labours.map((labour) => {
      const row = rowOf.get(labour.id)
      // The labour's usual wage for one day (monthly ÷ days in the month).
      const defaultPaise =
        labour.wageType === 'daily'
          ? toPaise(labour.wageAmount)
          : toPaise(labour.wageAmount) / daysInMonthOf(date)
      const dayPaise = row ? earnedPaise(row) : defaultPaise
      return {
        labour_id: labour.id,
        name: labour.name,
        wage_type: labour.wageType,
        wage_amount: labour.wageAmount,
        present: row !== undefined,
        day_wage: fromPaise(Math.round(dayPaise)),
        default_day_wage: fromPaise(Math.round(defaultPaise)),
      }
    })

    // Summary for the whole day (every labour employed that date).
    const employed = Labour.activeOn(Labour.query(), date)
    const total = Number((await employed.clone().count('* as n').first())?.$extras.n ?? 0)
    const present = Number(
      (
        await Attendance.query()
          .where('date', date)
          .whereIn('labour_id', employed.clone().select('id'))
          .count('* as n')
          .first()
      )?.$extras.n ?? 0
    )
    return {
      date,
      summary: { total, present, absent: total - present },
      items,
      page: paginator.currentPage,
      limit: paginator.perPage,
      total: paginator.total,
      last_page: paginator.lastPage,
    }
  }
}
