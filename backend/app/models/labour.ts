import db from '@adonisjs/lucid/services/db'
import { fromPaise, toPaise } from '#helpers/money'
import { LabourSchema } from '#database/schema'
import { compose } from '@adonisjs/core/helpers'
import { withUuid } from '#models/mixins/with_uuid'
import { hasMany } from '@adonisjs/lucid/orm'
import type { HasMany } from '@adonisjs/lucid/types/relations'
import type { ModelQueryBuilderContract } from '@adonisjs/lucid/types/model'
import Attendance from '#models/attendance'
import WagePayment from '#models/wage_payment'

export default class Labour extends compose(LabourSchema, withUuid) {
  /** "labour" is treated as uncountable by the pluralizer, so set it explicitly. */
  static table = 'labours'

  @hasMany(() => Attendance)
  declare attendances: HasMany<typeof Attendance>

  @hasMany(() => WagePayment)
  declare wagePayments: HasMany<typeof WagePayment>

  /** Labours employed on a date: joined on/before it and not left before it. */
  static activeOn(query: ModelQueryBuilderContract<typeof Labour>, date: string) {
    return query.where('joining_date', '<=', date).where((q) => {
      q.whereNull('left_date').orWhere('left_date', '>=', date)
    })
  }

  /**
   * Adds the lifetime wage totals as extras: earned_paise (every present day
   * at its saved wage; monthly: the full monthly wage for each month with a
   * present day) and paid_total (all
   * wage payments).
   */
  static withLifetime(query: ModelQueryBuilderContract<typeof Labour>) {
    return query
      .select(
        db.raw(
          // Daily days at their saved wage + the full monthly wage (latest
          // saved amount) for each month with a present day.
          `((SELECT COALESCE(SUM(a.wage_amount), 0) FROM attendances a
              WHERE a.labour_id = labours.id AND a.wage_type = 'daily')
            + (SELECT COALESCE(SUM(m.wage_amount), 0) FROM (
                SELECT a.labour_id, a.wage_amount, ROW_NUMBER() OVER (
                  PARTITION BY a.labour_id, YEAR(a.date), MONTH(a.date)
                  ORDER BY a.date DESC) AS rn
                FROM attendances a WHERE a.wage_type = 'monthly') m
              WHERE m.labour_id = labours.id AND m.rn = 1)) * 100 AS earned_paise`
        )
      )
      .select(
        db.raw(
          `(SELECT COALESCE(SUM(w.amount), 0) FROM wage_payments w
            WHERE w.labour_id = labours.id) AS paid_total`
        )
      )
  }

  /** { earned, paid, balance } for all time (needs [withLifetime]). */
  lifetime() {
    const earned = Math.round(Number(this.$extras.earned_paise ?? 0))
    const paid = toPaise(this.$extras.paid_total ?? 0)
    return {
      earned: fromPaise(earned),
      paid: fromPaise(paid),
      balance: fromPaise(earned - paid),
    }
  }

  /**
   * API shape: model fields + present_today and the lifetime wage totals
   * (when selected as extras by the labours controller).
   */
  toResponse() {
    const life = this.lifetime()
    return {
      ...this.serialize(),
      present_today: Boolean(Number(this.$extras.present_today ?? 0)),
      total_earned: life.earned,
      total_paid: life.paid,
      total_balance: life.balance,
    }
  }
}
