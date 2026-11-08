import db from '@adonisjs/lucid/services/db'
import type { TransactionClientContract } from '@adonisjs/lucid/types/database'
import { DateTime } from 'luxon'
import Sale from '#models/sale'
import SaleItem from '#models/sale_item'
import SalePayment from '#models/sale_payment'
import Product from '#models/product'
import Customer from '#models/customer'
import FactorySetting from '#models/factory_setting'
import AppError from '#exceptions/app_error'
import { fromPaise, money, multiply, toPaise } from '#helpers/money'
import { today } from '#helpers/dates'

type Trx = TransactionClientContract

export type SaleItemInput = {
  product_id: number
  quantity: number
  unit_cost?: number
  unit_price?: number
}

export type SaleInput = {
  customer_id?: number
  new_customer?: { name: string; phone: string; address?: string | null }
  sale_date?: string
  delivery_date?: string
  delivery_address?: string | null
  items: SaleItemInput[]
  transport_charge?: number
  discount?: number
  notes?: string | null
}

export type PaymentInput = {
  amount: number
  payment_date?: string
  method?: string
  note?: string | null
}

/**
 * All sale business rules (01-PRD §6.1–6.2, 05-Backend-Schema §4.1).
 * Every change runs in one transaction and ends with recalculate().
 */
export default class SaleService {
  static async create(
    input: SaleInput & {
      type: 'instant' | 'booking'
      payment?: Omit<PaymentInput, 'payment_date'>
    },
    userId: number | null
  ) {
    return db.transaction(async (trx) => {
      const saleDate = input.sale_date ?? today()
      const isBooking = input.type === 'booking'
      this.assertDeliveryDate(isBooking, saleDate, input.delivery_date)

      const customerId = await this.resolveCustomer(input, userId, trx)

      const sale = new Sale()
      sale.useTransaction(trx)
      sale.merge({
        type: input.type,
        status: isBooking ? 'booked' : 'delivered',
        customerId,
        saleDate,
        deliveryDate: isBooking ? input.delivery_date! : null,
        deliveredDate: isBooking ? null : saleDate,
        deliveryAddress: input.delivery_address ?? null,
        transportCharge: money(input.transport_charge),
        discount: money(input.discount),
        notes: input.notes ?? null,
        createdBy: userId,
      })
      await sale.save()

      const settings = await FactorySetting.query({ client: trx }).where('id', 1).first()
      sale.invoiceNo = `${settings?.invoicePrefix ?? 'INV-'}${String(sale.id).padStart(6, '0')}`
      await sale.save()

      await this.replaceItems(sale, input.items, trx)

      if (input.payment) {
        await SalePayment.create(
          {
            saleId: sale.id,
            amount: money(input.payment.amount),
            paymentDate: saleDate,
            method: input.payment.method ?? 'cash',
            note: input.payment.note ?? null,
            createdBy: userId,
          },
          { client: trx }
        )
      }

      await this.recalculate(sale, trx)
      return sale.id
    })
  }

  static async update(sale: Sale, input: SaleInput, userId: number | null) {
    if (sale.status === 'cancelled') {
      throw new AppError('sales.cancelled_not_editable')
    }

    return db.transaction(async (trx) => {
      sale.useTransaction(trx)
      const saleDate = input.sale_date ?? sale.saleDate
      const isBooking = sale.type === 'booking'
      this.assertDeliveryDate(
        isBooking,
        saleDate,
        input.delivery_date ?? sale.deliveryDate ?? undefined
      )

      const customerId = await this.resolveCustomer(input, userId, trx)

      sale.merge({
        customerId,
        saleDate,
        deliveryDate: isBooking ? (input.delivery_date ?? sale.deliveryDate) : null,
        // Instant sales are delivered on their sale date
        deliveredDate: isBooking ? sale.deliveredDate : saleDate,
        deliveryAddress: input.delivery_address ?? null,
        transportCharge: money(input.transport_charge),
        discount: money(input.discount),
        notes: input.notes ?? null,
      })
      await sale.save()

      await this.replaceItems(sale, input.items, trx)
      await this.recalculate(sale, trx)
      return sale.id
    })
  }

  static async addPayment(sale: Sale, input: PaymentInput, userId: number | null) {
    if (sale.status === 'cancelled') {
      throw new AppError('sales.payment_on_cancelled')
    }
    if (toPaise(input.amount) > toPaise(sale.dueAmount)) {
      throw new AppError('sales.payment_over_due', 400, null, { due: sale.dueAmount })
    }
    const paymentDate = input.payment_date ?? today()
    if (paymentDate < sale.saleDate) {
      throw new AppError('sales.payment_before_sale')
    }

    await db.transaction(async (trx) => {
      sale.useTransaction(trx)
      await SalePayment.create(
        {
          saleId: sale.id,
          amount: money(input.amount),
          paymentDate,
          method: input.method ?? 'cash',
          note: input.note ?? null,
          createdBy: userId,
        },
        { client: trx }
      )
      await this.recalculate(sale, trx)
    })
  }

  static async deletePayment(sale: Sale, paymentId: number) {
    await db.transaction(async (trx) => {
      sale.useTransaction(trx)
      const payment = await SalePayment.query({ client: trx })
        .where('id', paymentId)
        .where('sale_id', sale.id)
        .firstOrFail()
      await payment.delete()
      await this.recalculate(sale, trx)
    })
  }

  static async deliver(sale: Sale, deliveredDate = today()) {
    if (sale.status !== 'booked') {
      throw new AppError('sales.deliver_only_booked')
    }
    if (deliveredDate < sale.saleDate) {
      throw new AppError('sales.delivered_before_booking')
    }
    sale.merge({ status: 'delivered', deliveredDate })
    await sale.save()
  }

  static async cancel(sale: Sale) {
    if (sale.status !== 'booked') {
      throw new AppError('sales.cancel_only_booked')
    }
    if (toPaise(sale.paidAmount) > 0) {
      throw new AppError('sales.cancel_has_payments')
    }
    sale.merge({ status: 'cancelled', cancelledAt: DateTime.now() })
    await sale.save()
  }

  static async softDelete(sale: Sale) {
    sale.deletedAt = DateTime.now()
    await sale.save()
  }

  /**
   * Recomputes and stores all totals from items and payments.
   */
  static async recalculate(sale: Sale, trx: Trx) {
    const items = await SaleItem.query({ client: trx }).where('sale_id', sale.id)
    const payments = await SalePayment.query({ client: trx }).where('sale_id', sale.id)

    const subtotal = items.reduce((sum, item) => sum + toPaise(item.lineTotal), 0)
    const totalCost = items.reduce((sum, item) => sum + toPaise(item.lineCost), 0)
    const total = subtotal + toPaise(sale.transportCharge) - toPaise(sale.discount)
    const paid = payments.reduce((sum, payment) => sum + toPaise(payment.amount), 0)

    if (total < 0) {
      throw new AppError('sales.discount_too_big')
    }
    if (paid > total) {
      throw new AppError('sales.payments_over_total', 400, null, {
        paid: fromPaise(paid),
        total: fromPaise(total),
      })
    }

    const due = total - paid
    sale.merge({
      subtotal: fromPaise(subtotal),
      total: fromPaise(total),
      totalCost: fromPaise(totalCost),
      profit: fromPaise(total - totalCost),
      paidAmount: fromPaise(paid),
      dueAmount: fromPaise(due),
      paymentStatus: paid === 0 ? 'due' : due === 0 ? 'paid' : 'partial',
    })
    await sale.save()
  }

  /**
   * Replaces all items. Cost and price default to the product's defaults,
   * and a snapshot of name / unit / cost / price is stored on each line.
   */
  private static async replaceItems(sale: Sale, items: SaleItemInput[], trx: Trx) {
    await SaleItem.query({ client: trx }).where('sale_id', sale.id).delete()

    const products = await Product.query({ client: trx }).whereIn(
      'id',
      items.map((item) => item.product_id)
    )
    const byId = new Map(products.map((product) => [product.id, product]))

    for (const item of items) {
      const product = byId.get(item.product_id)!
      const unitCost = money(item.unit_cost ?? product.defaultCost)
      const unitPrice = money(item.unit_price ?? product.defaultPrice)

      await SaleItem.create(
        {
          saleId: sale.id,
          productId: product.id,
          productName: product.name,
          unit: product.unitText,
          quantity: money(item.quantity),
          unitCost,
          unitPrice,
          lineCost: fromPaise(multiply(item.quantity, unitCost)),
          lineTotal: fromPaise(multiply(item.quantity, unitPrice)),
        },
        { client: trx }
      )
    }
  }

  /**
   * Uses customer_id, or creates new_customer inline (phone must be free).
   */
  private static async resolveCustomer(input: SaleInput, userId: number | null, trx: Trx) {
    if (input.customer_id) return input.customer_id

    if (!input.new_customer) {
      throw AppError.validation('customer_id', 'sales.select_customer')
    }

    await Customer.assertPhoneFree(input.new_customer.phone, undefined, 'new_customer.phone')
    const customer = await Customer.create(
      {
        name: input.new_customer.name,
        phone: input.new_customer.phone,
        address: input.new_customer.address ?? null,
        isActive: true,
        createdBy: userId,
      },
      { client: trx }
    )
    return customer.id
  }

  private static assertDeliveryDate(isBooking: boolean, saleDate: string, deliveryDate?: string) {
    if (!isBooking) return
    if (!deliveryDate) {
      throw AppError.validation('delivery_date', 'sales.delivery_date_required')
    }
    if (deliveryDate < saleDate) {
      throw AppError.validation('delivery_date', 'sales.delivery_before_sale')
    }
  }
}
