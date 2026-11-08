import type { HttpContext } from '@adonisjs/core/http'
import Labour from '#models/labour'
import LabourAdvance from '#models/labour_advance'
import WagePayment from '#models/wage_payment'
import WageService from '#services/wage_service'
import { created, ok, paginated } from '#helpers/api_response'
import { fromPaise, money, toPaise } from '#helpers/money'
import { currentMonth, monthRange, today } from '#helpers/dates'
import { DEFAULT_LIMIT } from '#validators/rules'
import { paginationValidator } from '#validators/sale'
import {
  advanceValidator,
  monthValidator,
  wagePaymentValidator,
  wageSheetValidator,
} from '#validators/labour'

export default class WagesController {
  /**
   * GET /wages?month=YYYY-MM&page&limit → paginated rows + month totals
   */
  async sheet({ request, response }: HttpContext) {
    const { month = currentMonth(), page = 1, limit = DEFAULT_LIMIT, search } =
      await request.validateUsing(wageSheetValidator)

    let rows = await WageService.sheet(month)
    if (search) {
      const term = search.toLowerCase()
      rows = rows.filter((row) => row.name.toLowerCase().includes(term))
    }

    const sum = (key: 'earned' | 'advances' | 'paid' | 'balance') =>
      fromPaise(rows.reduce((total, row) => total + toPaise(row[key]), 0))

    const lastPage = Math.max(1, Math.ceil(rows.length / limit))
    return paginated(
      response,
      {
        all: () => rows.slice((page - 1) * limit, page * limit),
        currentPage: page,
        perPage: limit,
        total: rows.length,
        lastPage,
      },
      'Wage sheet fetched successfully',
      {
        extra: {
          month,
          totals: {
            earned: sum('earned'),
            advances: sum('advances'),
            paid: sum('paid'),
            balance: sum('balance'),
          },
        },
      }
    )
  }

  /**
   * GET /labours/:id/wages?month=YYYY-MM
   */
  async labour({ params, request, response }: HttpContext) {
    const labour = await Labour.findOrFail(params.id)
    const { month = currentMonth() } = await request.validateUsing(monthValidator)
    return ok(response, await WageService.detail(labour, month), 'Wage detail fetched successfully')
  }

  /**
   * GET /labours/:id/advances
   */
  async advances({ params, request, response }: HttpContext) {
    const labour = await Labour.findOrFail(params.id)
    const { page = 1, limit = DEFAULT_LIMIT } = await request.validateUsing(paginationValidator)
    const advances = await LabourAdvance.query()
      .where('labour_id', labour.id)
      .preload('creator', (q) => q.select('id', 'name'))
      .orderBy('advance_date', 'desc')
      .orderBy('id', 'desc')
      .paginate(page, limit)
    return paginated(response, advances, 'Advances fetched successfully')
  }

  async storeAdvance({ auth, params, request, response }: HttpContext) {
    const labour = await Labour.findOrFail(params.id)
    const data = await request.validateUsing(advanceValidator)
    const advance = await LabourAdvance.create({
      labourId: labour.id,
      amount: money(data.amount),
      advanceDate: data.advance_date ?? today(),
      note: data.note ?? null,
      createdBy: auth.getUserOrFail().id,
    })
    await advance.load('creator', (q) => q.select('id', 'name'))
    return created(response, advance, 'Advance recorded')
  }

  async destroyAdvance({ params, response }: HttpContext) {
    const advance = await LabourAdvance.findOrFail(params.id)
    await advance.delete()
    return ok(response, null, 'Advance deleted')
  }

  async storePayment({ auth, params, request, response }: HttpContext) {
    const labour = await Labour.findOrFail(params.id)
    const data = await request.validateUsing(wagePaymentValidator)
    const payment = await WagePayment.create({
      labourId: labour.id,
      wageMonth: monthRange(data.wage_month).start,
      amount: money(data.amount),
      paymentDate: data.payment_date ?? today(),
      method: data.method ?? 'cash',
      note: data.note ?? null,
      createdBy: auth.getUserOrFail().id,
    })
    await payment.load('creator', (q) => q.select('id', 'name'))
    return created(response, payment, 'Wage payment recorded')
  }

  async destroyPayment({ params, response }: HttpContext) {
    const payment = await WagePayment.findOrFail(params.id)
    await payment.delete()
    return ok(response, null, 'Wage payment deleted')
  }
}
