import vine from '@vinejs/vine'
import { DateTime } from 'luxon'
import { today } from '#helpers/dates'

/**
 * Shared validation rules used by all validators.
 */

const validDate = vine.createRule((value, _options, field) => {
  if (typeof value !== 'string') return
  if (!DateTime.fromISO(value).isValid) {
    field.report('The {{ field }} field must be a valid date (YYYY-MM-DD)', 'validDate', field)
  }
})

const notFuture = vine.createRule((value, _options, field) => {
  if (typeof value !== 'string') return
  if (value > today()) {
    field.report('The {{ field }} field cannot be a future date', 'notFuture', field)
  }
})

/** Indian mobile number: 10 digits starting with 6-9 */
export const phoneRule = () =>
  vine
    .string()
    .trim()
    .regex(/^[6-9]\d{9}$/)

export const emailRule = () => vine.string().trim().toLowerCase().email().maxLength(150)

export const passwordRule = () => vine.string().minLength(6).maxLength(64)

export const nameRule = () => vine.string().trim().minLength(1).maxLength(100)

/** ≥ 0, max 2 decimals */
export const moneyRule = () => vine.number().min(0).max(9999999999.99).decimal([0, 2])

/** > 0, max 2 decimals (payments, advances, expenses) */
export const positiveMoneyRule = () => vine.number().min(0.01).max(9999999999.99).decimal([0, 2])

/** "YYYY-MM-DD" */
export const dateRule = () =>
  vine
    .string()
    .trim()
    .regex(/^\d{4}-\d{2}-\d{2}$/)
    .use(validDate())

/** "YYYY-MM-DD", today or earlier */
export const pastDateRule = () => dateRule().use(notFuture())

/** "YYYY-MM" */
export const monthRule = () =>
  vine
    .string()
    .trim()
    .regex(/^\d{4}-(0[1-9]|1[0-2])$/)

/** App / message language */
export const localeRule = () => vine.enum(['en', 'bn'] as const)

export const paymentMethodRule = () => vine.enum(['cash', 'upi', 'bank', 'other'] as const)

/** page / limit / search for every list endpoint */
export const paginationRules = {
  page: vine.number().withoutDecimals().min(1).optional(),
  limit: vine.number().withoutDecimals().min(1).max(100).optional(),
  search: vine.string().trim().maxLength(100).optional(),
}

export const DEFAULT_LIMIT = 20
