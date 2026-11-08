import type { HttpContext } from '@adonisjs/core/http'
import type { NextFn } from '@adonisjs/core/types/http'
import type { Authenticators } from '@adonisjs/auth/types'
import i18nManager from '@adonisjs/i18n/services/main'
import AppError from '#exceptions/app_error'

/**
 * Requires a valid Bearer token from an ACTIVE user.
 */
export default class AuthMiddleware {
  async handle(
    ctx: HttpContext,
    next: NextFn,
    options: {
      guards?: (keyof Authenticators)[]
    } = {}
  ) {
    await ctx.auth.authenticateUsing(options.guards)

    if (!ctx.auth.user?.isActive) {
      throw new AppError('errors.account_deactivated', 401)
    }

    /**
     * No Accept-Language header → answer in the user's saved language.
     */
    if (!ctx.request.header('accept-language')) {
      ctx.i18n = i18nManager.locale(ctx.auth.user.locale)
      ctx.response.header('Content-Language', ctx.i18n.locale)
    }

    return next()
  }
}
