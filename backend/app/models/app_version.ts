import { AppVersionSchema } from '#database/schema'
import { compose } from '@adonisjs/core/helpers'
import { withUuid } from '#models/mixins/with_uuid'

export default class AppVersion extends compose(AppVersionSchema, withUuid) {}
