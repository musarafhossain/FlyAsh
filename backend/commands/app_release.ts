import { BaseCommand, flags } from '@adonisjs/core/ace'
import type { CommandOptions } from '@adonisjs/core/types/ace'

/**
 * Publishes a new app version so installed apps can update.
 *
 *   node ace app:release --platform=android --version=1.2.0 --build=12 \
 *     --min-build=10 --url=https://api.example.com/downloads/flyash-1.2.0.apk \
 *     --notes="Sales report export added"
 *
 * Upload the APK / EXE to the downloads folder first. Web needs no --url.
 */
export default class AppRelease extends BaseCommand {
  static commandName = 'app:release'
  static description = 'Publish a new app version (android, windows or web)'
  static options: CommandOptions = { startApp: true }

  @flags.string({ description: 'android | windows | web' })
  declare platform: string

  @flags.string({ description: 'Version name, e.g. 1.2.0' })
  declare version: string

  @flags.number({ description: 'Build number (the +N in pubspec.yaml), e.g. 12' })
  declare build: number

  @flags.number({ flagName: 'min-build', description: 'Builds below this must update (default: no force)' })
  declare minBuild?: number

  @flags.string({ description: 'Download URL of the APK / EXE (not needed for web)' })
  declare url?: string

  @flags.string({ description: 'Release notes shown in the update dialog' })
  declare notes?: string

  async run() {
    const { default: AppVersion } = await import('#models/app_version')

    if (!['android', 'windows', 'web'].includes(this.platform)) {
      return this.fail('--platform must be android, windows or web')
    }
    if (!/^\d+\.\d+\.\d+$/.test(this.version ?? '')) {
      return this.fail('--version must look like 1.2.0')
    }
    if (!Number.isInteger(this.build) || this.build < 1) {
      return this.fail('--build must be a positive whole number')
    }
    if (this.platform !== 'web' && !this.url) {
      return this.fail('--url is required for android and windows')
    }

    const minBuild = this.minBuild ?? 0
    if (minBuild > this.build) {
      return this.fail('--min-build cannot be greater than --build')
    }

    const exists = await AppVersion.query()
      .where('platform', this.platform)
      .where('build_number', this.build)
      .first()
    if (exists) {
      return this.fail(`Build ${this.build} for ${this.platform} is already published`)
    }

    await AppVersion.create({
      platform: this.platform,
      versionName: this.version,
      buildNumber: this.build,
      minSupportedBuild: minBuild,
      downloadUrl: this.url ?? null,
      releaseNotes: this.notes ?? null,
      isActive: true,
    })

    this.logger.success(
      `Published ${this.platform} ${this.version}+${this.build}` +
        (minBuild ? ` (builds below ${minBuild} must update)` : '')
    )
  }

  private fail(message: string) {
    this.logger.error(message)
    this.exitCode = 1
  }
}
