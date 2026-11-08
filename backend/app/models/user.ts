import { UserSchema } from '#database/schema'
import hash from '@adonisjs/core/services/hash'
import { compose } from '@adonisjs/core/helpers'
import { withAuthFinder } from '@adonisjs/auth/mixins/lucid'
import { type AccessToken, DbAccessTokensProvider } from '@adonisjs/auth/access_tokens'

/**
 * Users log in with their phone or email. The password is hashed
 * automatically (scrypt) by the auth finder mixin when it changes.
 */
export default class User extends compose(
  UserSchema,
  withAuthFinder(hash, { uids: ['phone', 'email'], passwordColumnName: 'password' })
) {
  static accessTokens = DbAccessTokensProvider.forModel(User)
  declare currentAccessToken?: AccessToken
}
