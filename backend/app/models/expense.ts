import { ExpenseSchema } from '#database/schema'
import { belongsTo, computed } from '@adonisjs/lucid/orm'
import type { BelongsTo } from '@adonisjs/lucid/types/relations'
import ExpenseCategory from '#models/expense_category'
import User from '#models/user'
import { uploadUrl } from '#helpers/uploads'

export default class Expense extends ExpenseSchema {
  @belongsTo(() => ExpenseCategory, { serializeAs: 'category' })
  declare category: BelongsTo<typeof ExpenseCategory>

  @belongsTo(() => User, { foreignKey: 'createdBy', serializeAs: 'created_by' })
  declare creator: BelongsTo<typeof User>

  @computed({ serializeAs: 'bill_photo_url' })
  get billPhotoUrl() {
    return uploadUrl(this.billPhotoPath)
  }
}
