import vine from '@vinejs/vine'
import { dateRule, paginationRules, pastDateRule, positiveMoneyRule } from '#validators/rules'

/** A path returned by POST /uploads, e.g. "expenses/2026/11/<uuid>.jpg" */
export const uploadPathRule = () =>
  vine
    .string()
    .trim()
    .maxLength(255)
    .regex(/^(expenses|logo)\/\d{4}\/\d{2}\/[\w-]+\.(jpg|jpeg|png|webp)$/)

export const listExpensesValidator = vine.create({
  ...paginationRules,
  from: dateRule().optional(),
  to: dateRule().optional(),
  category_id: vine.number().withoutDecimals().optional(),
})

export const expenseValidator = vine.create({
  expense_category_id: vine
    .number()
    .withoutDecimals()
    .exists({ table: 'expense_categories', column: 'id' }),
  /** Defaults to today */
  expense_date: pastDateRule().optional(),
  amount: positiveMoneyRule(),
  note: vine.string().trim().maxLength(500).nullable().optional(),
  bill_photo_path: uploadPathRule().nullable().optional(),
})

export const listCategoriesValidator = vine.create({
  active: vine.boolean().optional(),
})

export const categoryValidator = vine.create({
  name: vine
    .string()
    .trim()
    .minLength(1)
    .maxLength(50)
    .unique({
      table: 'expense_categories',
      column: 'name',
      filter: (query, _value, field) => {
        if (field.meta?.categoryId) query.whereNot('id', field.meta.categoryId)
      },
    }),
  icon: vine.string().trim().maxLength(30).nullable().optional(),
  is_active: vine.boolean().optional(),
  sort_order: vine.number().withoutDecimals().min(0).max(9999).optional(),
})

export const uploadValidator = vine.create({
  folder: vine.enum(['expenses', 'logo'] as const),
})
