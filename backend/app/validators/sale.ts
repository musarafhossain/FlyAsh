import vine from '@vinejs/vine'
import { customerFields } from '#validators/customer'
import {
  dateRule,
  idRule,
  moneyRule,
  paginationRules,
  pastDateRule,
  paymentMethodRule,
  positiveMoneyRule,
} from '#validators/rules'

const item = vine.object({
  product_id: idRule().exists({ table: 'products', column: 'id' }),
  quantity: vine.number().min(0.01).max(9999999999.99).decimal([0, 2]),
  /** Optional: defaults to the product's default cost / price */
  unit_cost: moneyRule().optional(),
  unit_price: moneyRule().optional(),
})

const saleFields = {
  /** Existing customer, OR new_customer to create one inline */
  customer_id: idRule().exists({ table: 'customers', column: 'id' }).optional(),
  new_customer: vine.object(customerFields).optional(),
  /** Defaults to today */
  sale_date: pastDateRule().optional(),
  /** Booking only (required for bookings) */
  delivery_date: dateRule().optional(),
  delivery_address: vine.string().trim().maxLength(500).nullable().optional(),
  items: vine.array(item).minLength(1).maxLength(50),
  transport_charge: moneyRule().optional(),
  discount: moneyRule().optional(),
  notes: vine.string().trim().maxLength(1000).nullable().optional(),
}

export const createSaleValidator = vine.create({
  type: vine.enum(['instant', 'booking'] as const),
  ...saleFields,
  /** Money received now (the advance for bookings) */
  payment: vine
    .object({
      amount: positiveMoneyRule(),
      method: paymentMethodRule().optional(),
      note: vine.string().trim().maxLength(500).nullable().optional(),
    })
    .optional(),
})

/** The sale type cannot be changed after creation. */
export const updateSaleValidator = vine.create(saleFields)

export const listSalesValidator = vine.create({
  ...paginationRules,
  type: vine.enum(['instant', 'booking'] as const).optional(),
  status: vine
    .enum(['paid', 'partial', 'due', 'booked', 'delivered', 'cancelled'] as const)
    .optional(),
  from: dateRule().optional(),
  to: dateRule().optional(),
})

export const salePaymentValidator = vine.create({
  amount: positiveMoneyRule(),
  /** Defaults to today */
  payment_date: pastDateRule().optional(),
  method: paymentMethodRule().optional(),
  note: vine.string().trim().maxLength(500).nullable().optional(),
})

export const deliverSaleValidator = vine.create({
  /** Defaults to today */
  delivered_date: pastDateRule().optional(),
})

export const paginationValidator = vine.create(paginationRules)
