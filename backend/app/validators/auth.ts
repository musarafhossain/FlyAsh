import vine from '@vinejs/vine'
import { emailRule, localeRule, nameRule, passwordRule, phoneRule } from '#validators/rules'

/**
 * Unique check on the users table that ignores the user being edited
 * (pass `meta: { userId }` when validating).
 */
export const uniqueUser = (column: 'phone' | 'email') => ({
  table: 'users',
  column,
  filter: (query: any, _value: unknown, field: any) => {
    if (field.meta?.userId) query.whereNot('id', field.meta.userId)
  },
})

export const loginValidator = vine.create({
  login: vine.string().trim().toLowerCase().maxLength(150),
  password: vine.string().maxLength(64),
  device_name: vine.string().trim().maxLength(50).optional(),
})

export const profileValidator = vine.create({
  name: nameRule(),
  phone: phoneRule().unique(uniqueUser('phone')),
  email: emailRule().unique(uniqueUser('email')).nullable().optional(),
})

export const localeValidator = vine.create({
  locale: localeRule(),
})

export const changePasswordValidator = vine.create({
  current_password: vine.string().maxLength(64),
  password: passwordRule().confirmed({ confirmationField: 'password_confirmation' }),
})

export const forgotPasswordValidator = vine.create({
  email: emailRule(),
})

export const verifyOtpValidator = vine.create({
  email: emailRule(),
  otp: vine
    .string()
    .trim()
    .regex(/^\d{6}$/),
})

export const resetPasswordValidator = vine.create({
  reset_token: vine.string().maxLength(2000),
  password: passwordRule().confirmed({ confirmationField: 'password_confirmation' }),
})
