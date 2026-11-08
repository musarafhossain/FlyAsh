import type { HttpContext } from '@adonisjs/core/http'
import ReportService from '#services/report_service'
import DashboardService from '#services/dashboard_service'
import AppError from '#exceptions/app_error'
import { ok } from '#helpers/api_response'
import { currentMonth, startOfMonth, today } from '#helpers/dates'
import { DEFAULT_LIMIT } from '#validators/rules'
import { duesReportValidator, rangeValidator, reportMonthValidator } from '#validators/report'

export default class ReportsController {
  async dashboard({ response }: HttpContext) {
    return ok(response, await DashboardService.get(), 'reports.dashboard')
  }

  async sales({ request, response }: HttpContext) {
    const { from, to } = await this.range(request)
    return ok(response, await ReportService.sales(from, to), 'reports.sales')
  }

  async dues({ request, response }: HttpContext) {
    const { page = 1, limit = DEFAULT_LIMIT } = await request.validateUsing(duesReportValidator)
    return ok(response, await ReportService.dues(page, limit), 'reports.dues')
  }

  async expenses({ request, response }: HttpContext) {
    const { from, to } = await this.range(request)
    return ok(response, await ReportService.expenses(from, to), 'reports.expenses')
  }

  async wages({ request, response }: HttpContext) {
    const { month = currentMonth() } = await request.validateUsing(reportMonthValidator)
    return ok(response, await ReportService.wages(month), 'reports.wages')
  }

  async netProfit({ request, response }: HttpContext) {
    const { from, to } = await this.range(request)
    return ok(response, await ReportService.netProfit(from, to), 'reports.net_profit')
  }

  async collections({ request, response }: HttpContext) {
    const { from, to } = await this.range(request)
    return ok(response, await ReportService.collections(from, to), 'reports.collections')
  }

  /** from/to default to the current month (1st → today). */
  private async range(request: HttpContext['request']) {
    const { from = startOfMonth(), to = today() } = await request.validateUsing(rangeValidator)
    if (from > to) {
      throw AppError.validation('from', 'reports.bad_range')
    }
    return { from, to }
  }
}
