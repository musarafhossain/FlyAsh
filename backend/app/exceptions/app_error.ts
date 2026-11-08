import { t } from '#helpers/i18n'

/**
 * A business-rule error shown to the user. `key` is a message key from
 * resources/lang/<locale>/messages.json; the exception handler translates
 * it into the request language.
 *
 *   throw new AppError('sales.cancel_has_payments')
 *   throw new AppError('products.used_in_sales', 409)
 *   throw new AppError('auth.otp_wrong', 400, { tries_left: 4 }, { triesLeft: '4' })
 */
export default class AppError extends Error {
  constructor(
    public key: string,
    public status = 400,
    public data: unknown = null,
    public params: Record<string, string> = {}
  ) {
    super(key)
    this.name = 'AppError'
  }

  /**
   * A 422 with field errors, in the same shape as VineJS validation errors.
   *
   *   throw AppError.validation('phone', 'customers.phone_taken', { name }, { existing_customer_id: 5 })
   */
  static validation(
    field: string,
    key: string,
    params: Record<string, string> = {},
    extra: Record<string, unknown> = {}
  ) {
    return new AppError('errors.validation_failed', 422, {
      errors: [{ field, message: t(key, params) }],
      ...extra,
    })
  }
}
