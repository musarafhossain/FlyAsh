import app from '@adonisjs/core/services/app'
import { defineConfig, formatters, loaders } from '@adonisjs/i18n'

/**
 * API messages in English (default) and Bengali.
 * The app sends `Accept-Language: bn` or `en`; anything else falls back to English.
 *
 * resources/lang/<locale>/messages.json   → success / error messages (keys used in code)
 * resources/lang/<locale>/validator.json  → validation messages and field names
 */
const i18nConfig = defineConfig({
  defaultLocale: 'en',
  supportedLocales: ['en', 'bn'],
  formatter: formatters.icu(),

  loaders: [
    loaders.fs({
      location: app.languageFilesPath(),
    }),
  ],
})

export default i18nConfig
