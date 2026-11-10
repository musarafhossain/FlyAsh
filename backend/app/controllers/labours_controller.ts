import type { HttpContext } from '@adonisjs/core/http'
import type { ModelQueryBuilderContract } from '@adonisjs/lucid/types/model'
import db from '@adonisjs/lucid/services/db'
import Labour from '#models/labour'
import AppError from '#exceptions/app_error'
import { created, ok, paginated } from '#helpers/api_response'
import { money } from '#helpers/money'
import { today } from '#helpers/dates'
import { DEFAULT_LIMIT } from '#validators/rules'
import { labourStatusValidator, labourValidator, listLaboursValidator } from '#validators/labour'

export default class LaboursController {
  async index({ request, response }: HttpContext) {
    const {
      page = 1,
      limit = DEFAULT_LIMIT,
      search,
      active,
    } = await request.validateUsing(listLaboursValidator)

    const labours = await this.withTodayStatus(Labour.query())
      .if(search, (q) => {
        q.where((sub) =>
          sub.where('name', 'like', `%${search}%`).orWhere('phone', 'like', `%${search}%`)
        )
      })
      .if(active !== undefined, (q) => q.where('is_active', active!))
      .orderBy('is_active', 'desc')
      .orderBy('name', 'asc')
      .paginate(page, limit)

    return paginated(response, labours, 'labours.list', {
      map: (labour) => labour.toResponse(),
    })
  }

  async store({ auth, request, response }: HttpContext) {
    const data = await request.validateUsing(labourValidator)
    const labour = await Labour.create({
      name: data.name,
      phone: data.phone ?? null,
      address: data.address ?? null,
      wageType: data.wage_type,
      wageAmount: money(data.wage_amount),
      joiningDate: data.joining_date ?? today(),
      leftDate: null,
      isActive: true,
      createdBy: auth.getUserOrFail().id,
    })
    return created(response, await this.find(labour.id), 'labours.created')
  }

  async show({ params, response }: HttpContext) {
    return ok(response, await this.find(params.id), 'labours.fetched')
  }

  /**
   * A wage change applies to attendance saved from now on; past days keep
   * the wage stored on their attendance rows.
   */
  async update({ params, request, response }: HttpContext) {
    const labour = await Labour.findOrFail(params.id)
    const data = await request.validateUsing(labourValidator)

    const joiningDate = data.joining_date ?? labour.joiningDate
    if (labour.leftDate && joiningDate > labour.leftDate) {
      throw new AppError('labours.joining_after_leaving')
    }

    labour.merge({
      name: data.name,
      phone: data.phone ?? null,
      address: data.address ?? null,
      wageType: data.wage_type,
      wageAmount: money(data.wage_amount),
      joiningDate,
    })
    await labour.save()
    return ok(response, await this.find(labour.id), 'labours.updated')
  }

  /**
   * PATCH /labours/:id/status { is_active, left_date? }
   */
  async status({ params, request, response }: HttpContext) {
    const labour = await Labour.findOrFail(params.id)
    const { is_active: isActive, left_date: leftDate } =
      await request.validateUsing(labourStatusValidator)

    if (isActive) {
      labour.merge({ isActive: true, leftDate: null })
    } else {
      const date = leftDate ?? today()
      if (date < labour.joiningDate) {
        throw new AppError('labours.leaving_before_joining')
      }
      labour.merge({ isActive: false, leftDate: date })
    }
    await labour.save()

    return ok(
      response,
      await this.find(labour.id),
      isActive ? 'labours.activated' : 'labours.deactivated'
    )
  }

  private withTodayStatus(query: ModelQueryBuilderContract<typeof Labour>) {
    return query
      .select('labours.*')
      .select(
        db.raw(
          'EXISTS (SELECT 1 FROM attendances a WHERE a.labour_id = labours.id AND a.date = ?) AS present_today',
          [today()]
        )
      )
  }

  private async find(id: string) {
    const labour = await this.withTodayStatus(Labour.query()).where('labours.id', id).firstOrFail()
    return labour.toResponse()
  }
}
