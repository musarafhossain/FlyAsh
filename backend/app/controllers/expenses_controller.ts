import type { HttpContext } from '@adonisjs/core/http'
import db from '@adonisjs/lucid/services/db'
import Expense from '#models/expense'
import ExpenseCategory from '#models/expense_category'
import { created, ok, paginated } from '#helpers/api_response'
import { money } from '#helpers/money'
import { today } from '#helpers/dates'
import { DEFAULT_LIMIT } from '#validators/rules'
import {
  categoryValidator,
  expenseValidator,
  listCategoriesValidator,
  listExpensesValidator,
} from '#validators/expense'

type Filters = { from?: string; to?: string; category_id?: string; search?: string }

export default class ExpensesController {
  /**
   * GET /expenses?from&to&category_id&search → paginated + period_total
   */
  async index({ request, response }: HttpContext) {
    const {
      page = 1,
      limit = DEFAULT_LIMIT,
      ...filters
    } = await request.validateUsing(listExpensesValidator)

    const expenses = await this.applyFilters(Expense.query(), filters)
      .preload('category', (q) => q.select('id', 'name', 'icon'))
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
      expenseCategoryId: data.expense_category_id,
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
      expenseCategoryId: data.expense_category_id,
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
   * GET /expense-categories?active (small list, not paginated)
   */
  async categories({ request, response }: HttpContext) {
    const { active } = await request.validateUsing(listCategoriesValidator)
    const categories = await ExpenseCategory.query()
      .if(active !== undefined, (q) => q.where('is_active', active!))
      .orderBy('sort_order', 'asc')
      .orderBy('name', 'asc')
    return ok(response, categories, 'expenses.categories')
  }

  async storeCategory({ request, response }: HttpContext) {
    const data = await request.validateUsing(categoryValidator)
    const maxOrder = await db.from('expense_categories').max('sort_order as max').first()
    const category = await ExpenseCategory.create({
      name: data.name,
      icon: data.icon ?? null,
      isActive: data.is_active ?? true,
      sortOrder: data.sort_order ?? Number(maxOrder?.max ?? 0) + 1,
    })
    await category.refresh()
    return created(response, category, 'expenses.category_created')
  }

  async updateCategory({ params, request, response }: HttpContext) {
    const category = await ExpenseCategory.findOrFail(params.id)
    const data = await request.validateUsing(categoryValidator, {
      meta: { categoryId: category.id },
    })
    category.merge({
      name: data.name,
      icon: data.icon === undefined ? category.icon : data.icon,
      isActive: data.is_active ?? category.isActive,
      sortOrder: data.sort_order ?? category.sortOrder,
    })
    await category.save()
    return ok(response, category, 'expenses.category_updated')
  }

  private applyFilters<Q extends { where: any; if: any }>(query: Q, filters: Filters): Q {
    return query
      .if(filters.from, (q: any) => q.where('expense_date', '>=', filters.from))
      .if(filters.to, (q: any) => q.where('expense_date', '<=', filters.to))
      .if(filters.category_id, (q: any) => q.where('expense_category_id', filters.category_id))
      .if(filters.search, (q: any) => q.where('note', 'like', `%${filters.search}%`))
  }

  private find(id: string) {
    return Expense.query()
      .where('id', id)
      .preload('category', (q) => q.select('id', 'name', 'icon'))
      .preload('creator', (q) => q.select('id', 'name'))
      .firstOrFail()
  }
}
