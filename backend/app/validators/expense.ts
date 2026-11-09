import vine from '@vinejs/vine'
import {
  dateRule,
  idRule,
  paginationRules,
  pastDateRule,
  positiveMoneyRule,
} from '#validators/rules'

export const listExpensesValidator = vine.create({
  ...paginationRules,
  from: dateRule().optional(),
  to: dateRule().optional(),
  category_id: idRule().optional(),
})

export const expenseValidator = vine.create({
  expense_category_id: idRule().exists({ table: 'expense_categories', column: 'id' }),
  /** Defaults to today */
  expense_date: pastDateRule().optional(),
  amount: positiveMoneyRule(),
  note: vine.string().trim().maxLength(500).nullable().optional(),
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
