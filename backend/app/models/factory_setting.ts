import { FactorySettingSchema } from '#database/schema'
import { compose } from '@adonisjs/core/helpers'
import { withUuid } from '#models/mixins/with_uuid'

/**
 * Single-row table holding the factory profile.
 * The logo is a static asset bundled in the app.
 */
export default class FactorySetting extends compose(FactorySettingSchema, withUuid) {
  /** Returns the settings row, creating it with defaults if missing. */
  static async current() {
    const existing = await this.query().orderBy('created_at').first()
    if (existing) return existing

    const created = await this.create({})
    await created.refresh() // load the column defaults (factory name, invoice prefix)
    return created
  }
}
