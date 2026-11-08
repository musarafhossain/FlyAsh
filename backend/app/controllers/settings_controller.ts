import type { HttpContext } from '@adonisjs/core/http'
import FactorySetting from '#models/factory_setting'
import AppVersion from '#models/app_version'
import { ok } from '#helpers/api_response'
import { appVersionValidator, factorySettingsValidator } from '#validators/setting'

export default class SettingsController {
  async factory({ response }: HttpContext) {
    return ok(response, await FactorySetting.current(), 'Factory profile fetched successfully')
  }

  /**
   * PUT /settings/factory: the invoice prefix applies to new sales only.
   */
  async updateFactory({ auth, request, response }: HttpContext) {
    const data = await request.validateUsing(factorySettingsValidator)
    const settings = await FactorySetting.current()

    settings.merge({
      factoryName: data.factory_name,
      ownerName: data.owner_name ?? null,
      phone: data.phone ?? null,
      email: data.email ?? null,
      address: data.address ?? null,
      invoicePrefix: data.invoice_prefix ?? settings.invoicePrefix,
      updatedBy: auth.getUserOrFail().id,
    })
    await settings.save()

    return ok(response, settings, 'Factory profile updated')
  }

  /**
   * GET /app/version?platform=android|windows|web&build=12 (public)
   */
  async appVersion({ request, response }: HttpContext) {
    const { platform, build } = await request.validateUsing(appVersionValidator)

    const latest = await AppVersion.query()
      .where('platform', platform)
      .where('is_active', true)
      .orderBy('build_number', 'desc')
      .first()

    if (!latest) {
      return ok(
        response,
        {
          latest_version: null,
          latest_build: null,
          update_available: false,
          force_update: false,
          download_url: null,
          release_notes: null,
        },
        'No release published yet'
      )
    }

    const installed = build ?? latest.buildNumber
    return ok(
      response,
      {
        latest_version: latest.versionName,
        latest_build: latest.buildNumber,
        update_available: installed < latest.buildNumber,
        force_update: installed < latest.minSupportedBuild,
        download_url: latest.downloadUrl,
        release_notes: latest.releaseNotes,
      },
      'Version info fetched'
    )
  }
}
