import vine from '@vinejs/vine'
import { nameRule, paginationRules, phoneRule } from '#validators/rules'

export const listCustomersValidator = vine.create({
  ...paginationRules,
  has_due: vine.boolean().optional(),
  active: vine.boolean().optional(),
})

/** Phone uniqueness is checked in Customer.assertPhoneFree (to return the existing customer id). */
export const customerFields = {
  name: nameRule(),
  phone: phoneRule(),
  address: vine.string().trim().maxLength(500).nullable().optional(),
}

export const customerValidator = vine.create(customerFields)

export const customerStatusValidator = vine.create({
  is_active: vine.boolean(),
})
