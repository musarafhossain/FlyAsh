import type { HttpContext } from '@adonisjs/core/http'
import type { NextFn } from '@adonisjs/core/types/http'
import { today, zone } from '#helpers/dates'

/**
 * Tells the app which day "today" is for the factory, on every response:
 *
 *   X-Business-Date: 2026-11-08
 *   X-Business-Timezone: Asia/Kolkata
 *
 * The app uses this (not the device clock) as the default date for forms and
 * filters, so a device in another timezone never picks a "future" date.
 */
export default class BusinessDateMiddleware {
  async handle(ctx: HttpContext, next: NextFn) {
    ctx.response.header('X-Business-Date', today())
    ctx.response.header('X-Business-Timezone', zone())
    return next()
  }
}
