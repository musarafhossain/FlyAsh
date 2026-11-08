import vine from '@vinejs/vine'
import {
  emailRule,
  localeRule,
  nameRule,
  paginationRules,
  passwordRule,
  phoneRule,
} from '#validators/rules'
import { uniqueUser } from '#validators/auth'

export const listUsersValidator = vine.create({
  ...paginationRules,
  active: vine.boolean().optional(),
})

export const createUserValidator = vine.create({
  name: nameRule(),
  phone: phoneRule().unique(uniqueUser('phone')),
  email: emailRule().unique(uniqueUser('email')).nullable().optional(),
  password: passwordRule(),
  /** Default 'en' */
  locale: localeRule().optional(),
})

export const updateUserValidator = vine.create({
  name: nameRule(),
  phone: phoneRule().unique(uniqueUser('phone')),
  email: emailRule().unique(uniqueUser('email')).nullable().optional(),
})

export const userStatusValidator = vine.create({
  is_active: vine.boolean(),
})

export const resetUserPasswordValidator = vine.create({
  password: passwordRule().confirmed({ confirmationField: 'password_confirmation' }),
})
