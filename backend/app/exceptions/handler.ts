import app from '@adonisjs/core/services/app'
import { type HttpContext, ExceptionHandler } from '@adonisjs/core/http'
import AppError from '#exceptions/app_error'
import { fail } from '#helpers/api_response'
import { t } from '#helpers/i18n'

export default class HttpExceptionHandler extends ExceptionHandler {
  protected debug = !app.inProduction

  /**
   * Converts every error into the standard envelope, with the message in
   * the request language: { success: false, status_code, message, data }
   */
  async handle(error: any, ctx: HttpContext) {
    const { response } = ctx

    if (error instanceof AppError) {
      return fail(response, error.status, t(error.key, error.params), error.data)
    }

    switch (error?.code) {
      case 'E_VALIDATION_ERROR':
        return fail(response, 422, t('errors.validation_failed'), {
          errors: (error.messages ?? []).map((item: any) => ({
            field: item.field,
            message: item.message,
          })),
        })
      case 'E_ROW_NOT_FOUND':
        return fail(response, 404, t('errors.not_found'))
      case 'E_UNAUTHORIZED_ACCESS':
        return fail(response, 401, t('errors.unauthorized'))
      case 'E_INVALID_CREDENTIALS':
        return fail(response, 400, t('errors.invalid_credentials'))
      case 'E_TOO_MANY_REQUESTS': {
        const seconds = Number(error.response?.availableIn ?? 60)
        const minutes = String(Math.max(1, Math.ceil(seconds / 60)))
        return fail(response, 429, t('errors.too_many_attempts', { minutes }))
      }
      case 'E_ROUTE_NOT_FOUND':
        return fail(response, 404, t('errors.route_not_found'))
      case 'ER_DUP_ENTRY':
        return fail(response, 409, t('errors.duplicate'))
      case 'ER_ROW_IS_REFERENCED':
      case 'ER_ROW_IS_REFERENCED_2':
        return fail(response, 409, t('errors.in_use'))
    }

    const status = Number(error?.status)
    if (status >= 400 && status < 500) {
      return fail(response, status, error.message || t('errors.bad_request'))
    }

    return fail(response, 500, this.debug && error?.message ? error.message : t('errors.server'))
  }

  async report(error: unknown, ctx: HttpContext) {
    return super.report(error, ctx)
  }
}
