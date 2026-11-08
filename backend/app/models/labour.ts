import { LabourSchema } from '#database/schema'
import { hasMany } from '@adonisjs/lucid/orm'
import type { HasMany } from '@adonisjs/lucid/types/relations'
import type { ModelQueryBuilderContract } from '@adonisjs/lucid/types/model'
import Attendance from '#models/attendance'
import LabourAdvance from '#models/labour_advance'
import WagePayment from '#models/wage_payment'

export default class Labour extends LabourSchema {
  /** "labour" is treated as uncountable by the pluralizer, so set it explicitly. */
  static table = 'labours'

  @hasMany(() => Attendance)
  declare attendances: HasMany<typeof Attendance>

  @hasMany(() => LabourAdvance)
  declare advances: HasMany<typeof LabourAdvance>

  @hasMany(() => WagePayment)
  declare wagePayments: HasMany<typeof WagePayment>

  /** Labours employed on a date: joined on/before it and not left before it. */
  static activeOn(query: ModelQueryBuilderContract<typeof Labour>, date: string) {
    return query.where('joining_date', '<=', date).where((q) => {
      q.whereNull('left_date').orWhere('left_date', '>=', date)
    })
  }

  /** API shape: model fields + today's attendance status (when selected as an extra). */
  toResponse() {
    return {
      ...this.serialize(),
      today_status: this.$extras.today_status ?? null,
    }
  }
}
