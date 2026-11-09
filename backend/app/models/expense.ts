import { ExpenseSchema } from '#database/schema'
import { compose } from '@adonisjs/core/helpers'
import { withUuid } from '#models/mixins/with_uuid'
import { belongsTo } from '@adonisjs/lucid/orm'
import type { BelongsTo } from '@adonisjs/lucid/types/relations'
import ExpenseCategory from '#models/expense_category'
import User from '#models/user'

export default class Expense extends compose(ExpenseSchema, withUuid) {
  @belongsTo(() => ExpenseCategory, { serializeAs: 'category' })
  declare category: BelongsTo<typeof ExpenseCategory>

  @belongsTo(() => User, { foreignKey: 'createdBy', serializeAs: 'created_by' })
  declare creator: BelongsTo<typeof User>
}
