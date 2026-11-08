import type { HttpContext } from '@adonisjs/core/http'
import type { NextFn } from '@adonisjs/core/types/http'
import type { Authenticators } from '@adonisjs/auth/types'
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
      throw new AppError('Your account is deactivated', 401)
    }

    return next()
  }
}
