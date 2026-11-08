import type { HttpContext } from '@adonisjs/core/http'
import type { ModelQueryBuilderContract } from '@adonisjs/lucid/types/model'
import Sale from '#models/sale'
import Customer from '#models/customer'
import SaleService from '#services/sale_service'
import { created, ok, paginated } from '#helpers/api_response'
import { today } from '#helpers/dates'
import { DEFAULT_LIMIT } from '#validators/rules'
import {
  createSaleValidator,
  deliverSaleValidator,
  listSalesValidator,
  paginationValidator,
  salePaymentValidator,
  updateSaleValidator,
} from '#validators/sale'

type SaleQuery = ModelQueryBuilderContract<typeof Sale>

export default class SalesController {
  /**
   * GET /sales?page&limit&search&type&status&from&to
   * status: paid | partial | due (delivered sales by payment) or booked | delivered | cancelled
   */
  async index({ request, response }: HttpContext) {
    const {
      page = 1,
      limit = DEFAULT_LIMIT,
      search,
      type,
      status,
      from,
      to,
    } = await request.validateUsing(listSalesValidator)

    const query = this.listQuery()
      .if(type, (q) => q.where('sales.type', type!))
      .if(from, (q) => q.where('sales.sale_date', '>=', from!))
      .if(to, (q) => q.where('sales.sale_date', '<=', to!))
      .if(search, (q) => {
        q.where((sub) => {
          sub.where('sales.invoice_no', 'like', `%${search}%`).orWhereHas('customer', (c) => {
            c.where('name', 'like', `%${search}%`).orWhere('phone', 'like', `%${search}%`)
          })
        })
      })

    if (status === 'paid' || status === 'partial' || status === 'due') {
      query.where('sales.status', 'delivered').where('sales.payment_status', status)
    } else if (status) {
      query.where('sales.status', status)
    }

    const sales = await query
      .orderBy('sales.sale_date', 'desc')
      .orderBy('sales.id', 'desc')
      .paginate(page, limit)

    return paginated(response, sales, 'Sales fetched successfully')
  }

  /**
   * GET /sales/upcoming-deliveries: booked sales by delivery date (overdue first).
   */
  async upcoming({ request, response }: HttpContext) {
    const { page = 1, limit = DEFAULT_LIMIT } = await request.validateUsing(paginationValidator)
    const sales = await this.listQuery()
      .where('sales.status', 'booked')
      .orderBy('sales.delivery_date', 'asc')
      .orderBy('sales.id', 'asc')
      .paginate(page, limit)

    const now = today()
    return paginated(response, sales, 'Upcoming deliveries fetched successfully', {
      map: (sale) => ({ ...sale.serialize(), is_overdue: (sale.deliveryDate ?? now) < now }),
    })
  }

  /**
   * GET /customers/:id/sales
   */
  async byCustomer({ params, request, response }: HttpContext) {
    const customer = await Customer.findOrFail(params.id)
    const { page = 1, limit = DEFAULT_LIMIT } = await request.validateUsing(paginationValidator)
    const sales = await this.listQuery()
      .where('sales.customer_id', customer.id)
      .orderBy('sales.sale_date', 'desc')
      .orderBy('sales.id', 'desc')
      .paginate(page, limit)
    return paginated(response, sales, 'Customer sales fetched successfully')
  }

  async store({ auth, request, response }: HttpContext) {
    const data = await request.validateUsing(createSaleValidator)
    const id = await SaleService.create(data, auth.getUserOrFail().id)
    return created(response, await this.detail(id), 'Sale saved successfully')
  }

  async show({ params, response }: HttpContext) {
    return ok(response, await this.detail(params.id), 'Sale fetched successfully')
  }

  async update({ auth, params, request, response }: HttpContext) {
    const sale = await this.find(params.id)
    const data = await request.validateUsing(updateSaleValidator)
    await SaleService.update(sale, data, auth.getUserOrFail().id)
    return ok(response, await this.detail(sale.id), 'Sale updated successfully')
  }

  async destroy({ params, response }: HttpContext) {
    const sale = await this.find(params.id)
    await SaleService.softDelete(sale)
    return ok(response, null, 'Sale deleted successfully')
  }

  async deliver({ params, request, response }: HttpContext) {
    const sale = await this.find(params.id)
    const { delivered_date: deliveredDate } = await request.validateUsing(deliverSaleValidator)
    await SaleService.deliver(sale, deliveredDate)
    return ok(response, await this.detail(sale.id), 'Marked as delivered')
  }

  async cancel({ params, response }: HttpContext) {
    const sale = await this.find(params.id)
    await SaleService.cancel(sale)
    return ok(response, await this.detail(sale.id), 'Booking cancelled')
  }

  async addPayment({ auth, params, request, response }: HttpContext) {
    const sale = await this.find(params.id)
    const data = await request.validateUsing(salePaymentValidator)
    await SaleService.addPayment(sale, data, auth.getUserOrFail().id)
    return ok(response, await this.detail(sale.id), 'Payment added')
  }

  async deletePayment({ params, response }: HttpContext) {
    const sale = await this.find(params.id)
    await SaleService.deletePayment(sale, Number(params.paymentId))
    return ok(response, await this.detail(sale.id), 'Payment removed')
  }

  /** Base list query: not deleted, with the customer's id/name/phone. */
  private listQuery(): SaleQuery {
    return Sale.query()
      .withScopes((scopes) => scopes.notDeleted())
      .preload('customer', (q) => q.select('id', 'name', 'phone'))
  }

  private find(id: number | string) {
    return Sale.query()
      .where('id', id)
      .withScopes((scopes) => scopes.notDeleted())
      .firstOrFail()
  }

  /** Full sale: customer, items, payments (with who added them), creator. */
  private async detail(id: number | string) {
    return Sale.query()
      .where('id', id)
      .withScopes((scopes) => scopes.notDeleted())
      .preload('customer', (q) => q.select('id', 'name', 'phone', 'address'))
      .preload('items', (q) => q.orderBy('id', 'asc'))
      .preload('payments', (q) =>
        q
          .orderBy('payment_date', 'asc')
          .orderBy('id', 'asc')
          .preload('creator', (u) => u.select('id', 'name'))
      )
      .preload('creator', (q) => q.select('id', 'name'))
      .firstOrFail()
  }
}
