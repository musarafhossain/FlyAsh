import { BaseSeeder } from '@adonisjs/lucid/seeders'
import FactorySetting from '#models/factory_setting'

export default class extends BaseSeeder {
  async run() {
    await FactorySetting.current()
  }
}
