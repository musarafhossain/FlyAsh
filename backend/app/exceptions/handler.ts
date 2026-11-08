import app from '@adonisjs/core/services/app'
import { type HttpContext, ExceptionHandler } from '@adonisjs/core/http'
import AppError from '#exceptions/app_error'
import { fail } from '#helpers/api_response'

export default class HttpExceptionHandler extends ExceptionHandler {
  protected debug = !app.inProduction

  /**
   * Converts every error into the standard envelope:
   * { success: false, status_code, message, data }
   */
  async handle(error: any, ctx: HttpContext) {
    const { response } = ctx

    if (error instanceof AppError) {
      return fail(response, error.status, error.message, error.data)
    }

    switch (error?.code) {
      case 'E_VALIDATION_ERROR':
        return fail(response, 422, 'Validation failed', {
          errors: (error.messages ?? []).map((item: any) => ({
            field: item.field,
            message: item.message,
          })),
        })
      case 'E_ROW_NOT_FOUND':
        return fail(response, 404, 'Record not found')
      case 'E_UNAUTHORIZED_ACCESS':
        return fail(response, 401, 'Unauthorized')
      case 'E_INVALID_CREDENTIALS':
        return fail(response, 400, 'Invalid phone/email or password')
      case 'E_TOO_MANY_REQUESTS': {
        const seconds = Number(error.response?.availableIn ?? 60)
        const minutes = Math.max(1, Math.ceil(seconds / 60))
        return fail(response, 429, `Too many attempts. Try again in ${minutes} minute(s)`)
      }
      case 'E_ROUTE_NOT_FOUND':
        return fail(response, 404, 'Route not found')
      case 'ER_DUP_ENTRY':
        return fail(response, 409, 'Duplicate record')
      case 'ER_ROW_IS_REFERENCED':
      case 'ER_ROW_IS_REFERENCED_2':
        return fail(response, 409, 'This record is in use and cannot be deleted')
    }

    const status = Number(error?.status)
    if (status >= 400 && status < 500) {
      return fail(response, status, error.message || 'Bad request')
    }

    return fail(
      response,
      500,
      this.debug && error?.message ? error.message : 'Something went wrong. Please try again'
    )
  }

  async report(error: unknown, ctx: HttpContext) {
    return super.report(error, ctx)
  }
}
