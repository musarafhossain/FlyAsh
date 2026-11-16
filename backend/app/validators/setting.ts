import vine from '@vinejs/vine'
import { emailRule, phoneRule } from '#validators/rules'

export const factorySettingsValidator = vine.create({
  factory_name: vine.string().trim().minLength(1).maxLength(150),
  owner_name: vine.string().trim().maxLength(100).nullable().optional(),
  phone: phoneRule().nullable().optional(),
  email: emailRule().nullable().optional(),
  address: vine.string().trim().maxLength(500).nullable().optional(),
  /** GSTIN: 2-digit state code + PAN (10) + entity + Z + check, e.g. 19ABCDE1234F1Z5 */
  gst_number: vine
    .string()
    .trim()
    .toUpperCase()
    .regex(/^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$/)
    .nullable()
    .optional(),
  invoice_prefix: vine
    .string()
    .trim()
    .toUpperCase()
    .regex(/^[A-Z0-9-]{1,10}$/)
    .optional(),
})

export const appVersionValidator = vine.create({
  platform: vine.enum(['android', 'windows', 'web'] as const),
  /** Installed build number (pubspec "+N"); omit to just get the latest */
  build: vine.number().withoutDecimals().min(0).optional(),
})
