import { FactorySettingSchema } from '#database/schema'

/**
 * Single-row table (id = 1) holding the factory profile.
 * The logo is a static asset bundled in the app.
 */
export default class FactorySetting extends FactorySettingSchema {
  /** Returns the settings row, creating it with defaults if missing. */
  static async current() {
    const existing = await this.find(1)
    if (existing) return existing

    const created = await this.create({ id: 1 })
    await created.refresh() // load the column defaults (factory name, invoice prefix)
    return created
  }
}
