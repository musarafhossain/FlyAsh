import env from '#start/env'
import mail from '@adonisjs/mail/services/main'
import logger from '@adonisjs/core/services/logger'

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

  static async sendPasswordResetOtp(to: string, otp: string, factoryName: string) {
    const subject = `${factoryName}: password reset OTP`
    const text = [
      `Your OTP to reset your ${factoryName} password is: ${otp}`,
      'It is valid for 10 minutes. If you did not ask for this, ignore this email.',
      '',
      `${factoryName} পাসওয়ার্ড রিসেটের OTP: ${otp}`,
      'এটি ১০ মিনিট কাজ করবে। আপনি অনুরোধ না করে থাকলে এই ইমেইল উপেক্ষা করুন।',
    ].join('\n')

    const html = `
      <div style="font-family:Arial,sans-serif;max-width:480px;margin:auto;color:#0F172A">
        <h2 style="margin:0 0 16px">${factoryName}</h2>
        <p>Your OTP to reset your password is:</p>
        <p style="font-size:32px;font-weight:700;letter-spacing:8px;margin:16px 0">${otp}</p>
        <p>It is valid for <b>10 minutes</b>. If you did not ask for this, ignore this email.</p>
        <hr style="border:none;border-top:1px solid #E3E8F0;margin:24px 0">
        <p>পাসওয়ার্ড রিসেটের OTP: <b>${otp}</b></p>
        <p>এটি ১০ মিনিট কাজ করবে। আপনি অনুরোধ না করে থাকলে এই ইমেইল উপেক্ষা করুন।</p>
      </div>`

    await this.send(to, subject, html, text)
  }
}
