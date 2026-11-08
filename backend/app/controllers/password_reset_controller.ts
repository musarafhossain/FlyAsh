import type { HttpContext } from '@adonisjs/core/http'
import hash from '@adonisjs/core/services/hash'
import encryption from '@adonisjs/core/services/encryption'
import logger from '@adonisjs/core/services/logger'
import { randomInt } from 'node:crypto'
import { DateTime } from 'luxon'
import User from '#models/user'
import PasswordResetOtp from '#models/password_reset_otp'
import FactorySetting from '#models/factory_setting'
import MailService from '#services/mail_service'
import AppError from '#exceptions/app_error'
import { ok } from '#helpers/api_response'
import {
  forgotPasswordValidator,
  resetPasswordValidator,
  verifyOtpValidator,
} from '#validators/auth'

const OTP_MINUTES = 10
const MAX_ATTEMPTS = 5
const TOKEN_PURPOSE = 'password_reset'

type ResetTokenPayload = { user_id: number; otp_id: number }

/**
 * Forgot password in 3 steps:
 *   1. forgot  → email a 6-digit OTP
 *   2. verify  → check the OTP, return a signed reset_token (10 min, single use)
 *   3. reset   → set the new password using the reset_token
 */
export default class PasswordResetController {
  /**
   * POST /auth/forgot-password { email }
   * Always returns the same message so nobody can find out which emails exist.
   */
  async forgot({ request, response }: HttpContext) {
    const { email } = await request.validateUsing(forgotPasswordValidator)
    const user = await User.query().where('email', email).where('is_active', true).first()

    if (user) {
      await PasswordResetOtp.query().where('user_id', user.id).delete()

      const otp = String(randomInt(0, 1_000_000)).padStart(6, '0')
      await PasswordResetOtp.create({
        userId: user.id,
        otpHash: await hash.make(otp),
        attempts: 0,
        expiresAt: DateTime.now().plus({ minutes: OTP_MINUTES }),
        verifiedAt: null,
      })

      try {
        const factory = await FactorySetting.current()
        await MailService.sendPasswordResetOtp(email, otp, factory.factoryName)
      } catch (error) {
        logger.error({ err: error }, 'Failed to send password reset OTP email')
      }
    }

    return ok(response, null, 'auth.otp_sent')
  }

  /**
   * POST /auth/verify-otp { email, otp } → { reset_token }
   */
  async verify({ request, response }: HttpContext) {
    const { email, otp } = await request.validateUsing(verifyOtpValidator)
    const user = await User.query().where('email', email).where('is_active', true).first()

    const record = user
      ? await PasswordResetOtp.query()
          .where('user_id', user.id)
          .whereNull('verified_at')
          .where('expires_at', '>', new Date())
          .orderBy('id', 'desc')
          .first()
      : null

    if (!user || !record) {
      throw new AppError('auth.otp_invalid')
    }

    if (!(await hash.verify(record.otpHash, otp))) {
      record.attempts += 1
      const triesLeft = MAX_ATTEMPTS - record.attempts

      if (triesLeft <= 0) {
        await record.delete()
        throw new AppError('auth.otp_too_many')
      }

      await record.save()
      throw new AppError(
        'auth.otp_wrong',
        400,
        { tries_left: triesLeft },
        { triesLeft: String(triesLeft) }
      )
    }

    record.verifiedAt = DateTime.now()
    await record.save()

    const resetToken = encryption
      .getMessageVerifier()
      .sign(
        { user_id: user.id, otp_id: record.id } satisfies ResetTokenPayload,
        `${OTP_MINUTES} minutes`,
        TOKEN_PURPOSE
      )

    return ok(response, { reset_token: resetToken }, 'auth.otp_verified')
  }

  /**
   * POST /auth/reset-password { reset_token, password, password_confirmation }
   */
  async reset({ request, response }: HttpContext) {
    const { reset_token: resetToken, password } =
      await request.validateUsing(resetPasswordValidator)

    const payload = encryption
      .getMessageVerifier()
      .unsign<ResetTokenPayload>(resetToken, TOKEN_PURPOSE)

    const record = payload
      ? await PasswordResetOtp.query()
          .where('id', payload.otp_id)
          .where('user_id', payload.user_id)
          .whereNotNull('verified_at')
          .first()
      : null

    const user = record ? await User.find(record.userId) : null

    if (!payload || !record || !user || !user.isActive) {
      throw new AppError('auth.reset_expired')
    }

    user.password = password
    await user.save()
    await record.delete()
    await User.revokeTokens(user)

    return ok(response, null, 'auth.password_reset_done')
  }
}
