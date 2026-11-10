import db from '@adonisjs/lucid/services/db'
import Sale from '#models/sale'
import Labour from '#models/labour'
import { money } from '#helpers/money'
import { startOfMonth, today } from '#helpers/dates'

/**
 * Every dashboard number in one call (01-PRD §6.5).
 */
export default class DashboardService {
  static async get() {
    const date = today()
    const notDeletedSales = () => db.from('sales').whereNull('deleted_at')

    const todaySales = await notDeletedSales()
      .where('status', 'delivered')
      .where('delivered_date', date)
      .count('* as count')
      .sum('total as amount')
      .sum('profit as profit')
      .first()

    const due = await notDeletedSales()
      .where('status', 'delivered')
      .sum('due_amount as total')
      .first()

    const deliveriesToday = await notDeletedSales()
      .where('status', 'booked')
      .where('delivery_date', date)
      .count('* as count')
      .first()

    const overdue = await notDeletedSales()
      .where('status', 'booked')
      .where('delivery_date', '<', date)
      .count('* as count')
      .first()

    const present = await db.from('attendances').where('date', date).count('* as count').first()

    const labours = await Labour.activeOn(Labour.query(), date).count('* as total')

    const expenses = await db
      .from('expenses')
      .whereBetween('expense_date', [startOfMonth(), date])
      .sum('amount as total')
      .first()

    const recentSales = await Sale.query()
      .withScopes((scopes) => scopes.notDeleted())
      .preload('customer', (q) => q.select('id', 'name', 'phone'))
      .orderBy('id', 'desc')
      .limit(5)

    return {
      date,
      today_sales: { amount: money(todaySales?.amount), count: Number(todaySales?.count ?? 0) },
      today_profit: money(todaySales?.profit),
      total_due: money(due?.total),
      deliveries_today: Number(deliveriesToday?.count ?? 0),
      overdue_deliveries: Number(overdue?.count ?? 0),
      present_today: Number(present?.count ?? 0),
      labours_total: Number(labours[0]?.$extras.total ?? 0),
      month_expenses: money(expenses?.total),
      recent_sales: recentSales,
    }
  }
}
