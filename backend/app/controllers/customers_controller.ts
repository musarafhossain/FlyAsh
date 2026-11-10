import type { HttpContext } from '@adonisjs/core/http'
import Customer from '#models/customer'
import Sale from '#models/sale'
import AppError from '#exceptions/app_error'
import { created, ok, paginated } from '#helpers/api_response'
import { DEFAULT_LIMIT } from '#validators/rules'
import {
  customerStatusValidator,
  customerValidator,
  listCustomersValidator,
} from '#validators/customer'

const DUE_SQL = `(SELECT COALESCE(SUM(s.due_amount), 0) FROM sales s
  WHERE s.customer_id = customers.id AND s.status = 'delivered' AND s.deleted_at IS NULL)`

export default class CustomersController {
  async index({ request, response }: HttpContext) {
    const {
      page = 1,
      limit = DEFAULT_LIMIT,
      search,
      has_due: hasDue,
      active,
    } = await request.validateUsing(listCustomersValidator)

    const query = Customer.query()
      .if(search, (q) => {
        q.where((sub) =>
          sub.where('name', 'like', `%${search}%`).orWhere('phone', 'like', `%${search}%`)
        )
      })
      .if(active !== undefined, (q) => q.where('is_active', active!))
      .if(hasDue, (q) => q.whereRaw(`${DUE_SQL} > 0`))

    Customer.withTotals(query)

    if (hasDue) {
      query.orderByRaw(`${DUE_SQL} DESC`)
    } else {
      query.orderBy('customers.created_at', 'desc')
    }

    const customers = await query.paginate(page, limit)
    return paginated(response, customers, 'customers.list', {
      map: (customer) => customer.toResponse(),
    })
  }

  async store({ auth, request, response }: HttpContext) {
    const data = await request.validateUsing(customerValidator)
    await Customer.assertPhoneFree(data.phone)

    const customer = await Customer.create({
      name: data.name,
      phone: data.phone ?? null,
      address: data.address ?? null,
      isActive: true,
      createdBy: auth.getUserOrFail().id,
    })

    return created(response, await this.find(customer.id), 'customers.created')
  }

  async show({ params, response }: HttpContext) {
    return ok(response, await this.find(params.id), 'customers.fetched')
  }

  async update({ params, request, response }: HttpContext) {
    const customer = await Customer.findOrFail(params.id)
    const data = await request.validateUsing(customerValidator)
    await Customer.assertPhoneFree(data.phone, customer.id)

    customer.merge({ name: data.name, phone: data.phone ?? null, address: data.address ?? null })
    await customer.save()

    return ok(response, await this.find(customer.id), 'customers.updated')
  }

  async status({ params, request, response }: HttpContext) {
    const customer = await Customer.findOrFail(params.id)
    const { is_active: isActive } = await request.validateUsing(customerStatusValidator)
    customer.isActive = isActive
    await customer.save()
    return ok(
      response,
      await this.find(customer.id),
      isActive ? 'customers.activated' : 'customers.deactivated'
    )
  }

  /**
   * Only customers without any sale can be deleted.
   */
  async destroy({ params, response }: HttpContext) {
    const customer = await Customer.findOrFail(params.id)
    if (await Sale.findBy('customer_id', customer.id)) {
      throw new AppError('customers.has_sales', 409)
    }
    await customer.delete()
    return ok(response, null, 'customers.deleted')
  }

  private async find(id: string) {
    const query = Customer.query().where('customers.id', id)
    Customer.withTotals(query)
    const customer = await query.firstOrFail()
    return customer.toResponse()
  }
}
