import { FactorySettingSchema } from '#database/schema'
import { computed } from '@adonisjs/lucid/orm'
import { uploadUrl } from '#helpers/uploads'

/**
 * Single-row table (id = 1) holding the factory profile.
 */
export default class FactorySetting extends FactorySettingSchema {
  @computed({ serializeAs: 'logo_url' })
  get logoUrl() {
    return uploadUrl(this.logoPath)
  }

  /** Returns the settings row, creating it with defaults if missing. */
  static async current() {
    return this.firstOrCreate({ id: 1 }, { id: 1 })
  }
}
