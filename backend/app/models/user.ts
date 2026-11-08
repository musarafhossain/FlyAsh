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

  /**
   * Logs the user out of every device, optionally keeping one token
   * (the current device).
   */
  static async revokeTokens(user: User, exceptTokenId?: string | number | BigInt) {
    const tokens = await User.accessTokens.all(user)
    for (const token of tokens) {
      if (exceptTokenId !== undefined && String(token.identifier) === String(exceptTokenId))
        continue
      await User.accessTokens.delete(user, token.identifier)
    }
  }
}
