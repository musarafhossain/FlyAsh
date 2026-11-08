import { I18n } from '@adonisjs/i18n'
import i18nManager from '@adonisjs/i18n/services/main'
import type { NextFn } from '@adonisjs/core/types/http'
import { type HttpContext, RequestValidator } from '@adonisjs/core/http'

/**
 * Picks the response language from the "Accept-Language" header
 * (`bn` → Bengali, anything else → English) and shares it with the
 * request, so messages and validation errors are translated.
 */
export default class DetectUserLocaleMiddleware {
  /**
   * Validation messages use the request language
   * (resources/lang/<locale>/validator.json).
   */
  static {
    RequestValidator.messagesProvider = (ctx) => {
      return ctx.i18n.createMessagesProvider()
    }
  }

  protected getRequestLocale(ctx: HttpContext) {
    return i18nManager.getSupportedLocaleFor(ctx.request.languages())
  }

  async handle(ctx: HttpContext, next: NextFn) {
    ctx.i18n = i18nManager.locale(this.getRequestLocale(ctx) || i18nManager.defaultLocale)
    ctx.containerResolver.bindValue(I18n, ctx.i18n)
    ctx.response.header('Content-Language', ctx.i18n.locale)
    return next()
  }
}

declare module '@adonisjs/core/http' {
  export interface HttpContext {
    i18n: I18n
  }
}
