import type { HttpContext } from '@adonisjs/core/http'
import hash from '@adonisjs/core/services/hash'
import { DateTime } from 'luxon'
import User from '#models/user'
import AppError from '#exceptions/app_error'
import { ok } from '#helpers/api_response'
import { loginLimiter } from '#start/limiter'
import {
  changePasswordValidator,
  localeValidator,
  loginValidator,
  profileValidator,
} from '#validators/auth'
import i18nManager from '@adonisjs/i18n/services/main'

export default class AuthController {
  /**
   * POST /auth/login → { token, user }
   */
  async login({ request, response }: HttpContext) {
    const { login, password, device_name: deviceName } = await request.validateUsing(loginValidator)

    const [error, user] = await loginLimiter.penalize(`login_${request.ip()}_${login}`, () =>
      User.verifyCredentials(login, password)
    )
    if (error) throw error

    if (!user.isActive) {
      throw new AppError('errors.account_deactivated')
    }

    user.lastLoginAt = DateTime.now()
    await user.save()

    const token = await User.accessTokens.create(user, ['*'], { name: deviceName })

    return ok(response, { token: token.value!.release(), user }, 'auth.login_success')
  }

  /**
   * POST /auth/logout: revokes the current token only.
   */
  async logout({ auth, response }: HttpContext) {
    const user = auth.getUserOrFail()
    if (user.currentAccessToken) {
      await User.accessTokens.delete(user, user.currentAccessToken.identifier)
    }
    return ok(response, null, 'auth.logged_out')
  }

  /**
   * GET /auth/me
   */
  async me({ auth, response }: HttpContext) {
    return ok(response, auth.getUserOrFail(), 'auth.profile_fetched')
  }

  /**
   * PUT /auth/me: edit my own name, phone, email.
   */
  async updateMe({ auth, request, response }: HttpContext) {
    const user = auth.getUserOrFail()
    const data = await request.validateUsing(profileValidator, { meta: { userId: user.id } })

    user.merge({ name: data.name, phone: data.phone, email: data.email ?? null })
    await user.save()

    return ok(response, user, 'auth.profile_updated')
  }

  /**
   * PUT /auth/locale { locale }: save my language (en | bn). It is used for
   * emails and for API messages when the request has no Accept-Language.
   */
  async updateLocale(ctx: HttpContext) {
    const user = ctx.auth.getUserOrFail()
    const { locale } = await ctx.request.validateUsing(localeValidator)

    user.locale = locale
    await user.save()

    // Answer in the newly chosen language
    ctx.i18n = i18nManager.locale(locale)
    ctx.response.header('Content-Language', locale)
    return ok(ctx.response, user, 'auth.locale_updated')
  }

  /**
   * PUT /auth/password: change my password. Other devices are logged out.
   */
  async changePassword({ auth, request, response }: HttpContext) {
    const user = auth.getUserOrFail()
    const { current_password: currentPassword, password } =
      await request.validateUsing(changePasswordValidator)

    if (!(await hash.verify(user.password, currentPassword))) {
      throw AppError.validation('current_password', 'auth.current_password_incorrect')
    }

    user.password = password
    await user.save()
    await User.revokeTokens(user, user.currentAccessToken?.identifier)

    return ok(response, null, 'auth.password_changed')
  }
}
