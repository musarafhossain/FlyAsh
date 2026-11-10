import { CustomerSchema } from '#database/schema'
import { compose } from '@adonisjs/core/helpers'
import { withUuid } from '#models/mixins/with_uuid'
import { hasMany } from '@adonisjs/lucid/orm'
import type { HasMany } from '@adonisjs/lucid/types/relations'
import type { ModelQueryBuilderContract } from '@adonisjs/lucid/types/model'
import db from '@adonisjs/lucid/services/db'
import Sale from '#models/sale'
import { money } from '#helpers/money'
import AppError from '#exceptions/app_error'

export default class Customer extends compose(CustomerSchema, withUuid) {
  @hasMany(() => Sale)
  declare sales: HasMany<typeof Sale>

  /**
   * Adds total_sales / total_paid / total_due (delivered, not deleted sales)
   * to the query as extras.
   */
  static withTotals(query: ModelQueryBuilderContract<typeof Customer>) {
    const sum = (column: string, alias: string) =>
      db.raw(
        `(SELECT COALESCE(SUM(s.${column}), 0) FROM sales s
          WHERE s.customer_id = customers.id AND s.status = 'delivered'
          AND s.deleted_at IS NULL) AS ${alias}`
      )
    return query
      .select('customers.*')
      .select(sum('total', 'total_sales'))
      .select(sum('paid_amount', 'total_paid'))
      .select(sum('due_amount', 'total_due'))
  }

  /**
   * Phone numbers are unique. Throws a 422 that also carries the existing
   * customer's id, so the app can offer "Use this customer".
   */
  static async assertPhoneFree(
    phone: string | null | undefined,
    exceptId?: string,
    field = 'phone'
  ) {
    if (!phone) return
    const existing = await Customer.query()
      .where('phone', phone)
      .if(exceptId, (q) => q.whereNot('id', exceptId!))
      .first()
    if (existing) {
      throw AppError.validation(
        field,
        'customers.phone_taken',
        { name: existing.name },
        { existing_customer_id: existing.id }
      )
    }
  }

  /** API shape: model fields + totals (when loaded with withTotals). */
  toResponse() {
    return {
      ...this.serialize(),
      total_sales: money(this.$extras.total_sales),
      total_paid: money(this.$extras.total_paid),
      total_due: money(this.$extras.total_due),
    }
  }
}
