import type { HttpContext } from '@adonisjs/core/http'

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
 */
export function ok(response: Response, data: unknown = null, message = 'Success', statusCode = 200) {
  return response.status(statusCode).send({ success: true, status_code: statusCode, message, data })
}

export function created(response: Response, data: unknown, message = 'Created successfully') {
  return ok(response, data, message, 201)
}

/**
 * Paginated list: data = { items, page, limit, total, last_page, ...extra }
 */
export function paginated<T>(
  response: Response,
  paginator: Paginator<T>,
  message = 'Success',
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
    message
  )
}

export function fail(response: Response, statusCode: number, message: string, data: unknown = null) {
  return response.status(statusCode).send({ success: false, status_code: statusCode, message, data })
}
