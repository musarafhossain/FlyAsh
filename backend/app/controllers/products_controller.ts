import type { HttpContext } from '@adonisjs/core/http'
import Product from '#models/product'
import SaleItem from '#models/sale_item'
import AppError from '#exceptions/app_error'
import { created, ok, paginated } from '#helpers/api_response'
import { money } from '#helpers/money'
import { DEFAULT_LIMIT } from '#validators/rules'
import {
  listProductsValidator,
  productStatusValidator,
  productValidator,
} from '#validators/product'

export default class ProductsController {
  async index({ request, response }: HttpContext) {
    const { page = 1, limit = DEFAULT_LIMIT, search, active } =
      await request.validateUsing(listProductsValidator)

    const products = await Product.query()
      .if(search, (query) => query.where('name', 'like', `%${search}%`))
      .if(active !== undefined, (query) => query.where('is_active', active!))
      .orderBy('is_active', 'desc')
      .orderBy('name', 'asc')
      .paginate(page, limit)

    return paginated(response, products, 'Products fetched successfully')
  }

  async store({ auth, request, response }: HttpContext) {
    const data = await request.validateUsing(productValidator)
    const product = await Product.create({
      ...this.fields(data),
      isActive: true,
      createdBy: auth.getUserOrFail().id,
    })
    await product.refresh()
    return created(response, product, 'Product created successfully')
  }

  async show({ params, response }: HttpContext) {
    return ok(response, await Product.findOrFail(params.id), 'Product fetched successfully')
  }

  async update({ params, request, response }: HttpContext) {
    const product = await Product.findOrFail(params.id)
    const data = await request.validateUsing(productValidator, { meta: { productId: product.id } })
    product.merge(this.fields(data))
    await product.save()
    await product.refresh()
    return ok(response, product, 'Product updated successfully')
  }

  async status({ params, request, response }: HttpContext) {
    const product = await Product.findOrFail(params.id)
    const { is_active: isActive } = await request.validateUsing(productStatusValidator)
    product.isActive = isActive
    await product.save()
    return ok(response, product, isActive ? 'Product activated' : 'Product deactivated')
  }

  /**
   * Only products never used in a sale can be deleted.
   */
  async destroy({ params, response }: HttpContext) {
    const product = await Product.findOrFail(params.id)
    if (await SaleItem.findBy('product_id', product.id)) {
      throw new AppError('Product is used in sales. Deactivate it instead', 409)
    }
    await product.delete()
    return ok(response, null, 'Product deleted successfully')
  }

  private fields(data: {
    name: string
    unit: string
    unit_label?: string
    default_cost: number
    default_price: number
    notes?: string | null
  }) {
    return {
      name: data.name,
      unit: data.unit,
      unitLabel: data.unit === 'other' ? (data.unit_label ?? null) : null,
      defaultCost: money(data.default_cost),
      defaultPrice: money(data.default_price),
      notes: data.notes ?? null,
    }
  }
}
