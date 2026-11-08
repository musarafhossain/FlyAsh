import vine from '@vinejs/vine'
import { dateRule, monthRule, paginationRules } from '#validators/rules'

/** from / to default to the current month in the controller */
export const rangeValidator = vine.create({
  from: dateRule().optional(),
  to: dateRule().optional(),
})

export const reportMonthValidator = vine.create({
  month: monthRule().optional(),
})

export const duesReportValidator = vine.create(paginationRules)
