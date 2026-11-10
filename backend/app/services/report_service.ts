import db from '@adonisjs/lucid/services/db'
import { DateTime } from 'luxon'
import WageService from '#services/wage_service'
import { fromPaise, money, toPaise } from '#helpers/money'

/** Delivered, not deleted sales whose delivery date is in [from, to]. */
function deliveredSales(from: string, to: string) {
  return db
    .from('sales')
    .whereNull('sales.deleted_at')
    .where('sales.status', 'delivered')
    .whereBetween('sales.delivered_date', [from, to])
}

/**
 * Reports (01-PRD §5.10, 05-Backend-Schema §5.9).
 * Sales and profit count on the delivered date; collections on the payment date.
 */
export default class ReportService {
  static async sales(from: string, to: string) {
    const totals = await deliveredSales(from, to)
      .count('* as count')
      .sum('total as amount')
      .sum('total_cost as cost')
      .sum('profit as profit')
      .first()

    const byProduct = await deliveredSales(from, to)
      .join('sale_items', 'sale_items.sale_id', 'sales.id')
      .groupBy('sale_items.product_id')
      .select('sale_items.product_id')
      .max('sale_items.product_name as product_name')
      .sum('sale_items.quantity as quantity')
      .sum('sale_items.line_total as amount')
      .sum('sale_items.line_cost as cost')
      .orderBy('amount', 'desc')

    const daily = await deliveredSales(from, to)
      .groupBy('sales.delivered_date')
      .select('sales.delivered_date as date')
      .sum('total as amount')
      .sum('profit as profit')
      .orderBy('date', 'asc')

    return {
      from,
      to,
      count: Number(totals?.count ?? 0),
      amount: money(totals?.amount),
      cost: money(totals?.cost),
      profit: money(totals?.profit),
      by_product: byProduct.map((row) => ({
        product_id: row.product_id,
        product_name: row.product_name,
        quantity: money(row.quantity),
        amount: money(row.amount),
        profit: fromPaise(toPaise(row.amount) - toPaise(row.cost)),
      })),
      daily: daily.map((row) => ({
        date: row.date,
        amount: money(row.amount),
        profit: money(row.profit),
      })),
    }
  }

  /** Customers with dues on delivered sales, highest first. */
  static async dues(page: number, limit: number) {
    const query = db
      .from('sales')
      .join('customers', 'customers.id', 'sales.customer_id')
      .whereNull('sales.deleted_at')
      .where('sales.status', 'delivered')
      .where('sales.due_amount', '>', 0)
      .groupBy('customers.id', 'customers.name', 'customers.phone')
      .select('customers.id as customer_id', 'customers.name', 'customers.phone')
      .sum('sales.due_amount as total_due')
      .min('sales.sale_date as oldest_due_date')
      .count('sales.id as sales_count')
      .orderBy('total_due', 'desc')

    const rows = await query
    const grandTotal = rows.reduce((sum, row) => sum + toPaise(row.total_due), 0)
    const items = rows.slice((page - 1) * limit, page * limit).map((row) => ({
      customer_id: row.customer_id,
      name: row.name,
      phone: row.phone,
      total_due: money(row.total_due),
      oldest_due_date: row.oldest_due_date,
      sales_count: Number(row.sales_count),
    }))

    return {
      items,
      page,
      limit,
      total: rows.length,
      last_page: Math.max(1, Math.ceil(rows.length / limit)),
      grand_total: fromPaise(grandTotal),
    }
  }

  static async expenses(from: string, to: string) {
    const rows = await db
      .from('expenses')
      .whereBetween('expense_date', [from, to])
      .groupBy('category')
      .select('category')
      .sum('amount as amount')
      .orderBy('amount', 'desc')

    const total = rows.reduce((sum, row) => sum + toPaise(row.amount), 0)
    return {
      from,
      to,
      total: fromPaise(total),
      by_category: rows.map((row) => ({
        name: row.category,
        amount: money(row.amount),
        percent: total === 0 ? 0 : Math.round((toPaise(row.amount) / total) * 1000) / 10,
      })),
    }
  }

  static async wages(month: string) {
    const rows = await WageService.sheet(month)
    const sum = (key: 'earned' | 'advances' | 'paid' | 'balance') =>
      fromPaise(rows.reduce((total, row) => total + toPaise(row[key]), 0))
    return {
      month,
      earned: sum('earned'),
      advances: sum('advances'),
      paid: sum('paid'),
      balance: sum('balance'),
      rows,
    }
  }

  /** Net profit = sales profit − expenses − wages earned, with a monthly series. */
  static async netProfit(from: string, to: string) {
    const total = await this.netProfitFor(from, to)

    const monthly = []
    let cursor = DateTime.fromISO(from).startOf('month')
    while (cursor.toISODate()! <= to) {
      const start = [from, cursor.toISODate()!].sort().at(-1)!
      const end = [to, cursor.endOf('month').toISODate()!].sort()[0]
      monthly.push({ month: cursor.toFormat('yyyy-MM'), ...(await this.netProfitFor(start, end)) })
      cursor = cursor.plus({ months: 1 })
    }

    return { from, to, ...total, monthly }
  }

  /** Money received from customers (by payment date). */
  static async collections(from: string, to: string) {
    const base = () =>
      db
        .from('sale_payments')
        .join('sales', 'sales.id', 'sale_payments.sale_id')
        .whereNull('sales.deleted_at')
        .whereBetween('sale_payments.payment_date', [from, to])

    const total = await base().sum('sale_payments.amount as total').first()
    const byMethod = await base()
      .groupBy('sale_payments.method')
      .select('sale_payments.method')
      .sum('sale_payments.amount as amount')
      .orderBy('amount', 'desc')
    const daily = await base()
      .groupBy('sale_payments.payment_date')
      .select('sale_payments.payment_date as date')
      .sum('sale_payments.amount as amount')
      .orderBy('date', 'asc')

    return {
      from,
      to,
      total: money(total?.total),
      by_method: byMethod.map((row) => ({ method: row.method, amount: money(row.amount) })),
      daily: daily.map((row) => ({ date: row.date, amount: money(row.amount) })),
    }
  }

  private static async netProfitFor(from: string, to: string) {
    const sales = await deliveredSales(from, to).sum('profit as profit').first()
    const expenses = await db
      .from('expenses')
      .whereBetween('expense_date', [from, to])
      .sum('amount as total')
      .first()
    const wages = await WageService.earnedBetween(from, to)

    const salesProfit = toPaise(sales?.profit)
    const expenseTotal = toPaise(expenses?.total)
    return {
      sales_profit: fromPaise(salesProfit),
      expenses: fromPaise(expenseTotal),
      wages: fromPaise(wages),
      net_profit: fromPaise(salesProfit - expenseTotal - wages),
    }
  }
}
