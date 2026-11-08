import { HttpContext } from '@adonisjs/core/http'
import i18nManager from '@adonisjs/i18n/services/main'

/**
 * Translates a message key from resources/lang/<locale>/messages.json
 * using the current request's language (English outside a request).
 *
 *   t('sales.saved')                         → "Sale saved successfully" / "বিক্রি সেভ হয়েছে"
 *   t('auth.otp_wrong', { triesLeft: '4' })  → "Wrong OTP. 4 tries left"
 *
 * Pass numbers as strings so they always stay in Latin digits.
 */
export function t(key: string, data?: Record<string, string>) {
  const i18n = HttpContext.get()?.i18n ?? i18nManager.locale(i18nManager.defaultLocale)
  return i18n.t(`messages.${key}`, data)
}
