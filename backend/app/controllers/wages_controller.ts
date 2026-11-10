import type { HttpContext } from '@adonisjs/core/http'
import Labour from '#models/labour'
import WagePayment from '#models/wage_payment'
import WageService from '#services/wage_service'
import { created, ok, paginated } from '#helpers/api_response'
import { fromPaise, money, toPaise } from '#helpers/money'
import { currentMonth, monthRange, today } from '#helpers/dates'
import { DEFAULT_LIMIT } from '#validators/rules'
import { monthValidator, wagePaymentValidator, wageSheetValidator } from '#validators/labour'

export default class WagesController {
  /**
   * GET /wages?month=YYYY-MM&page&limit → paginated rows + month totals
   */
  async sheet({ request, response }: HttpContext) {
    const {
      month = currentMonth(),
      page = 1,
      limit = DEFAULT_LIMIT,
      search,
    } = await request.validateUsing(wageSheetValidator)

    let rows = await WageService.sheet(month)
    if (search) {
      const term = search.toLowerCase()
      rows = rows.filter((row) => row.name.toLowerCase().includes(term))
    }

    const sum = (key: 'earned' | 'paid' | 'balance') =>
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
      'wages.sheet',
      {
        extra: {
          month,
          totals: {
            earned: sum('earned'),
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
    return ok(response, await WageService.detail(labour, month), 'wages.detail')
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
    return created(response, payment, 'wages.payment_recorded')
  }

  async destroyPayment({ params, response }: HttpContext) {
    const payment = await WagePayment.findOrFail(params.id)
    await payment.delete()
    return ok(response, null, 'wages.payment_deleted')
  }
}
