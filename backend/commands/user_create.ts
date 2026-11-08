import { BaseCommand, flags } from '@adonisjs/core/ace'
import type { CommandOptions } from '@adonisjs/core/types/ace'

/**
 * Creates a user from the server (used for the first user, since the app
 * has no sign-up screen).
 *
 *   node ace user:create
 *   node ace user:create --name="Rahim" --phone=9876543210 --email=a@b.com --password=secret123
 */
export default class UserCreate extends BaseCommand {
  static commandName = 'user:create'
  static description = 'Create a user (for example the first user)'
  static options: CommandOptions = { startApp: true }

  @flags.string({ description: 'Full name' })
  declare name?: string

  @flags.string({ description: '10 digit phone number (used to log in)' })
  declare phone?: string

  @flags.string({ description: 'Email (optional, used for password reset)' })
  declare email?: string

  @flags.string({ description: 'Password (min 6 characters)' })
  declare password?: string

  async run() {
    const { default: User } = await import('#models/user')

    const name =
      this.name || (await this.prompt.ask('Name', { validate: (v) => v.trim().length > 0 })) || ''
    const phone =
      this.phone ||
      (await this.prompt.ask('Phone (10 digits)', {
        validate: (v) => /^[6-9]\d{9}$/.test(v.trim()) || 'Enter a valid 10 digit phone number',
      })) ||
      ''
    const email = this.email ?? (await this.prompt.ask('Email (optional, press enter to skip)'))
    const password =
      this.password ||
      (await this.prompt.secure('Password (min 6 characters)', {
        validate: (v) => v.length >= 6 || 'Password must be at least 6 characters',
      })) ||
      ''

    if (!/^[6-9]\d{9}$/.test(phone.trim())) {
      this.logger.error('Phone must be a valid 10 digit number')
      this.exitCode = 1
      return
    }
    if (password.length < 6) {
      this.logger.error('Password must be at least 6 characters')
      this.exitCode = 1
      return
    }
    if (await User.findBy('phone', phone.trim())) {
      this.logger.error(`A user with phone ${phone} already exists`)
      this.exitCode = 1
      return
    }
    const cleanEmail = email?.trim().toLowerCase() || null
    if (cleanEmail && (await User.findBy('email', cleanEmail))) {
      this.logger.error(`A user with email ${cleanEmail} already exists`)
      this.exitCode = 1
      return
    }

    const user = await User.create({
      name: name.trim(),
      phone: phone.trim(),
      email: cleanEmail,
      password,
      isActive: true,
      createdBy: null,
    })

    this.logger.success(`User "${user.name}" created (id ${user.id}). Log in with ${user.phone}`)
  }
}
