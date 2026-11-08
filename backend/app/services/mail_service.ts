import env from '#start/env'
import mail from '@adonisjs/mail/services/main'
import logger from '@adonisjs/core/services/logger'

/** Password reset email text per language. */
const OTP_EMAIL = {
  en: {
    subject: (factory: string) => `${factory}: password reset OTP`,
    line1: (factory: string, otp: string) =>
      `Your OTP to reset your ${factory} password is: ${otp}`,
    intro: 'Your OTP to reset your password is:',
    valid: 'It is valid for <b>10 minutes</b>. If you did not ask for this, ignore this email.',
    validText: 'It is valid for 10 minutes. If you did not ask for this, ignore this email.',
  },
  bn: {
    subject: (factory: string) => `${factory}: পাসওয়ার্ড রিসেটের OTP`,
    line1: (factory: string, otp: string) => `${factory} পাসওয়ার্ড রিসেটের OTP: ${otp}`,
    intro: 'আপনার পাসওয়ার্ড রিসেটের OTP:',
    valid: 'এটি <b>১০ মিনিট</b> কাজ করবে। আপনি অনুরোধ না করে থাকলে এই ইমেইল উপেক্ষা করুন।',
    validText: 'এটি ১০ মিনিট কাজ করবে। আপনি অনুরোধ না করে থাকলে এই ইমেইল উপেক্ষা করুন।',
  },
}

export default class MailService {
  /**
   * Sends an email over SMTP. With MAIL_MAILER=log (development) the email
   * is printed to the console instead.
   */
  static async send(to: string, subject: string, html: string, text: string) {
    if (env.get('MAIL_MAILER') === 'log') {
      logger.info(`[mail] to=${to} subject="${subject}"\n${text}`)
      return
    }

    await mail.send((message) => {
      message.to(to).subject(subject).html(html).text(text)
    })
  }

  /**
   * The OTP email is written in the user's saved language (users.locale).
   */
  static async sendPasswordResetOtp(to: string, otp: string, factoryName: string, locale = 'en') {
    const copy = locale === 'bn' ? OTP_EMAIL.bn : OTP_EMAIL.en

    const text = [copy.line1(factoryName, otp), copy.validText].join('\n')
    const html = `
      <div style="font-family:Arial,sans-serif;max-width:480px;margin:auto;color:#0F172A">
        <h2 style="margin:0 0 16px">${factoryName}</h2>
        <p>${copy.intro}</p>
        <p style="font-size:32px;font-weight:700;letter-spacing:8px;margin:16px 0">${otp}</p>
        <p>${copy.valid}</p>
      </div>`

    await this.send(to, copy.subject(factoryName), html, text)
  }
}
