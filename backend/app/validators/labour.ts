import vine from '@vinejs/vine'
import {
  dateRule,
  monthRule,
  nameRule,
  paginationRules,
  pastDateRule,
  paymentMethodRule,
  phoneRule,
  positiveMoneyRule,
  idRule,
} from '#validators/rules'

export const listLaboursValidator = vine.create({
  ...paginationRules,
  active: vine.boolean().optional(),
})

export const labourValidator = vine.create({
  name: nameRule(),
  phone: phoneRule().nullable().optional(),
  address: vine.string().trim().maxLength(500).nullable().optional(),
  wage_type: vine.enum(['daily', 'monthly'] as const),
  wage_amount: positiveMoneyRule(),
  /** Defaults to today */
  joining_date: dateRule().optional(),
})

export const labourStatusValidator = vine.create({
  is_active: vine.boolean(),
  /** When deactivating; defaults to today */
  left_date: pastDateRule().optional(),
})

export const attendanceDayValidator = vine.create({
  /** Defaults to today */
  date: pastDateRule().optional(),
})

export const saveAttendanceValidator = vine.create({
  date: pastDateRule(),
  records: vine
    .array(
      vine.object({
        labour_id: idRule(),
        /** true = present (a row is saved), false = absent (the row is removed) */
        present: vine.boolean(),
      })
    )
    .maxLength(500),
})

export const monthValidator = vine.create({
  /** "YYYY-MM", defaults to the current month */
  month: monthRule().optional(),
})

export const wageSheetValidator = vine.create({
  ...paginationRules,
  month: monthRule().optional(),
})

export const wagePaymentValidator = vine.create({
  /** Month being paid: "YYYY-MM" */
  wage_month: monthRule(),
  amount: positiveMoneyRule(),
  /** Defaults to today */
  payment_date: pastDateRule().optional(),
  method: paymentMethodRule().optional(),
  note: vine.string().trim().maxLength(500).nullable().optional(),
})
