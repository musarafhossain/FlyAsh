import { BaseCommand, args, flags } from '@adonisjs/core/ace'
import type { CommandOptions } from '@adonisjs/core/types/ace'

/**
 * Resets a user's password from the server (when nobody can log in).
 *
 *   node ace user:reset-password 9876543210
 *   node ace user:reset-password 9876543210 --password=newsecret
 */
export default class UserResetPassword extends BaseCommand {
  static commandName = 'user:reset-password'
  static description = "Reset a user's password and log them out of all devices"
  static options: CommandOptions = { startApp: true }

  @args.string({ description: 'Phone number or email of the user' })
  declare login: string

  @flags.string({ description: 'New password (min 6 characters)' })
  declare password?: string

  async run() {
    const { default: User } = await import('#models/user')

    const login = this.login.trim().toLowerCase()
    const user = await User.query().where('phone', login).orWhere('email', login).first()
    if (!user) {
      this.logger.error(`No user found for "${this.login}"`)
      this.exitCode = 1
      return
    }

    const password =
      this.password ||
      (await this.prompt.secure('New password (min 6 characters)', {
        validate: (v) => v.length >= 6 || 'Password must be at least 6 characters',
      })) ||
      ''

    if (password.length < 6) {
      this.logger.error('Password must be at least 6 characters')
      this.exitCode = 1
      return
    }

    user.password = password
    user.isActive = true
    await user.save()
    await User.revokeTokens(user)

    this.logger.success(`Password reset for "${user.name}". They must log in again.`)
  }
}
