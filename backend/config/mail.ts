import env from '#start/env'
import { defineConfig, transports } from '@adonisjs/mail'

/**
 * Emails are sent over SMTP (e.g. Gmail with an App Password).
 * When MAIL_MAILER=log (development), MailService prints the email to the
 * console instead of sending it.
 */
const mailConfig = defineConfig({
  default: 'smtp',

  from: {
    address: env.get('MAIL_FROM_ADDRESS') || 'no-reply@flyash.local',
    name: env.get('MAIL_FROM_NAME') || 'FlyAsh',
  },

  mailers: {
    smtp: transports.smtp({
      host: env.get('SMTP_HOST') || 'localhost',
      port: env.get('SMTP_PORT') || 587,
      auth: {
        type: 'login',
        user: env.get('SMTP_USERNAME') || '',
        pass: env.get('SMTP_PASSWORD') || '',
      },
    }),
  },
})

export default mailConfig

declare module '@adonisjs/mail/types' {
  export interface MailersList extends InferMailers<typeof mailConfig> {}
}
