import vine from '@vinejs/vine'
import { dateRule, paginationRules, pastDateRule, positiveMoneyRule } from '#validators/rules'

/** Free text, e.g. "Labour Tiffin"; extra spaces are removed. */
const categoryRule = () =>
  vine
    .string()
    .trim()
    .minLength(1)
    .maxLength(60)
    .transform((value) => value.replace(/\s+/g, ' '))

export const listExpensesValidator = vine.create({
  ...paginationRules,
  from: dateRule().optional(),
  to: dateRule().optional(),
  category: categoryRule().optional(),
})

export const expenseValidator = vine.create({
  category: categoryRule(),
  /** Defaults to today */
  expense_date: pastDateRule().optional(),
  amount: positiveMoneyRule(),
  note: vine.string().trim().maxLength(500).nullable().optional(),
})
