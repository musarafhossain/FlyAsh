import type { HttpContext } from '@adonisjs/core/http'
import db from '@adonisjs/lucid/services/db'
import Expense from '#models/expense'
import { created, ok, paginated } from '#helpers/api_response'
import { money } from '#helpers/money'
import { today } from '#helpers/dates'
import { DEFAULT_LIMIT } from '#validators/rules'
import { expenseValidator, listExpensesValidator } from '#validators/expense'

type Filters = { from?: string; to?: string; category?: string; search?: string }

/** Offered while typing a category until the factory has its own. */
export const DEFAULT_CATEGORIES = [
  'Labour Tiffin',
  'Machine Repair',
  'Diesel / Fuel',
  'Electricity Bill',
  'Transport',
  'Others',
]

export default class ExpensesController {
  /**
   * GET /expenses?from&to&category&search → paginated + period_total
   */
  async index({ request, response }: HttpContext) {
    const {
      page = 1,
      limit = DEFAULT_LIMIT,
      ...filters
    } = await request.validateUsing(listExpensesValidator)

    const expenses = await this.applyFilters(Expense.query(), filters)
      .preload('creator', (q) => q.select('id', 'name'))
      .orderBy('expense_date', 'desc')
      .orderBy('id', 'desc')
      .paginate(page, limit)

    const totalRow = await this.applyFilters(db.from('expenses'), filters)
      .sum('amount as total')
      .first()

    return paginated(response, expenses, 'expenses.list', {
      extra: { period_total: money(totalRow?.total) },
    })
  }

  async store({ auth, request, response }: HttpContext) {
    const data = await request.validateUsing(expenseValidator)
    const expense = await Expense.create({
      category: await this.spelling(data.category),
      expenseDate: data.expense_date ?? today(),
      amount: money(data.amount),
      note: data.note ?? null,
      createdBy: auth.getUserOrFail().id,
    })
    return created(response, await this.find(expense.id), 'expenses.created')
  }

  async show({ params, response }: HttpContext) {
    return ok(response, await this.find(params.id), 'expenses.fetched')
  }

  async update({ params, request, response }: HttpContext) {
    const expense = await Expense.findOrFail(params.id)
    const data = await request.validateUsing(expenseValidator)
    expense.merge({
      category: await this.spelling(data.category),
      expenseDate: data.expense_date ?? expense.expenseDate,
      amount: money(data.amount),
      note: data.note ?? null,
    })
    await expense.save()
    return ok(response, await this.find(expense.id), 'expenses.updated')
  }

  async destroy({ params, response }: HttpContext) {
    const expense = await Expense.findOrFail(params.id)
    await expense.delete()
    return ok(response, null, 'expenses.deleted')
  }

  /**
   * GET /expense-categories → category names for suggestions and the
   * filter: the ones used most first, then the defaults not used yet.
   */
  async categories({ response }: HttpContext) {
    const rows = await db
      .from('expenses')
      .select('category')
      .count('* as uses')
      .groupBy('category')
      .orderBy('uses', 'desc')
      .orderBy('category', 'asc')
    const used = rows.map((r) => String(r.category))
    const seen = new Set(used.map((c) => c.toLowerCase()))
    const names = [...used, ...DEFAULT_CATEGORIES.filter((c) => !seen.has(c.toLowerCase()))]
    return ok(response, names, 'expenses.categories')
  }

  /**
   * "labour tiffin" is saved as "Labour Tiffin" when that is already used,
   * so the same category is not split by letter case.
   */
  private async spelling(category: string) {
    const known = await db
      .from('expenses')
      .whereRaw('LOWER(category) = ?', [category.toLowerCase()])
      .select('category')
      .first()
    if (known) return String(known.category)
    return DEFAULT_CATEGORIES.find((c) => c.toLowerCase() === category.toLowerCase()) ?? category
  }

  private applyFilters<Q extends { where: any; if: any }>(query: Q, filters: Filters): Q {
    return query
      .if(filters.from, (q: any) => q.where('expense_date', '>=', filters.from))
      .if(filters.to, (q: any) => q.where('expense_date', '<=', filters.to))
      .if(filters.category, (q: any) => q.where('category', filters.category))
      .if(filters.search, (q: any) =>
        q.where((w: any) =>
          w
            .where('note', 'like', `%${filters.search}%`)
            .orWhere('category', 'like', `%${filters.search}%`)
        )
      )
  }

  private find(id: string) {
    return Expense.query()
      .where('id', id)
      .preload('creator', (q) => q.select('id', 'name'))
      .firstOrFail()
  }
}
