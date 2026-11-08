import vine from '@vinejs/vine'
import { moneyRule, paginationRules } from '#validators/rules'

export const listProductsValidator = vine.create({
  ...paginationRules,
  active: vine.boolean().optional(),
})

export const productValidator = vine.create({
  name: vine
    .string()
    .trim()
    .minLength(1)
    .maxLength(100)
    .unique({
      table: 'products',
      column: 'name',
      filter: (query, _value, field) => {
        if (field.meta?.productId) query.whereNot('id', field.meta.productId)
      },
    }),
  unit: vine.enum(['piece', 'thousand', 'truck', 'other'] as const),
  unit_label: vine.string().trim().maxLength(30).optional().requiredWhen('unit', '=', 'other'),
  default_cost: moneyRule(),
  default_price: moneyRule(),
  notes: vine.string().trim().maxLength(500).nullable().optional(),
})

export const productStatusValidator = vine.create({
  is_active: vine.boolean(),
})
