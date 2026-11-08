import { BaseSeeder } from '@adonisjs/lucid/seeders'
import ExpenseCategory from '#models/expense_category'

export default class extends BaseSeeder {
  async run() {
    await ExpenseCategory.updateOrCreateMany('name', [
      { name: 'Labour Tiffin', icon: 'utensils', sortOrder: 1 },
      { name: 'Machine Repair', icon: 'wrench', sortOrder: 2 },
      { name: 'Diesel / Fuel', icon: 'fuel', sortOrder: 3 },
      { name: 'Electricity Bill', icon: 'zap', sortOrder: 4 },
      { name: 'Transport', icon: 'truck', sortOrder: 5 },
      { name: 'Others', icon: 'circle-dot', sortOrder: 6 },
    ])
  }
}
