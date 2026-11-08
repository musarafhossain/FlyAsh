import type { HttpContext } from '@adonisjs/core/http'
import { t } from '#helpers/i18n'

type Response = HttpContext['response']

/**
 * Minimal shape shared by Lucid model and query paginators.
 */
type Paginator<T> = {
  all(): T[]
  currentPage: number
  perPage: number
  total: number
  lastPage: number
}

/**
 * Every API response uses the same envelope:
 * { success, status_code, message, data }
 *
 * `messageKey` is a key from resources/lang/<locale>/messages.json and is
 * translated into the request language (Accept-Language: en | bn).
 */
export function ok(
  response: Response,
  data: unknown = null,
  messageKey = 'common.success',
  statusCode = 200,
  params?: Record<string, string>
) {
  return response
    .status(statusCode)
    .send({ success: true, status_code: statusCode, message: t(messageKey, params), data })
}

export function created(response: Response, data: unknown, messageKey = 'common.created') {
  return ok(response, data, messageKey, 201)
}

/**
 * Paginated list: data = { items, page, limit, total, last_page, ...extra }
 */
export function paginated<T>(
  response: Response,
  paginator: Paginator<T>,
  messageKey = 'common.success',
  options: { map?: (item: T) => unknown; extra?: Record<string, unknown> } = {}
) {
  const items = options.map ? paginator.all().map(options.map) : paginator.all()
  return ok(
    response,
    {
      items,
      page: paginator.currentPage,
      limit: paginator.perPage,
      total: Number(paginator.total),
      last_page: paginator.lastPage,
      ...options.extra,
    },
    messageKey
  )
}

/**
 * Error envelope. `message` is already translated by the caller.
 */
export function fail(
  response: Response,
  statusCode: number,
  message: string,
  data: unknown = null
) {
  return response
    .status(statusCode)
    .send({ success: false, status_code: statusCode, message, data })
}
