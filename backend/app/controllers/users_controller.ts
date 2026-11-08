import type { HttpContext } from '@adonisjs/core/http'
import User from '#models/user'
import AppError from '#exceptions/app_error'
import { created, ok, paginated } from '#helpers/api_response'
import { DEFAULT_LIMIT } from '#validators/rules'
import {
  createUserValidator,
  listUsersValidator,
  resetUserPasswordValidator,
  updateUserValidator,
  userStatusValidator,
} from '#validators/user'

/**
 * Manage OTHER users. The logged-in user is never listed here and cannot be
 * changed through these endpoints (they use /auth/me instead).
 */
export default class UsersController {
  async index({ auth, request, response }: HttpContext) {
    const {
      page = 1,
      limit = DEFAULT_LIMIT,
      search,
      active,
    } = await request.validateUsing(listUsersValidator)

    const users = await User.query()
      .whereNot('id', auth.getUserOrFail().id)
      .if(search, (query) => {
        query.where((q) =>
          q.where('name', 'like', `%${search}%`).orWhere('phone', 'like', `%${search}%`)
        )
      })
      .if(active !== undefined, (query) => query.where('is_active', active!))
      .orderBy('name', 'asc')
      .paginate(page, limit)

    return paginated(response, users, 'Users fetched successfully')
  }

  async store({ auth, request, response }: HttpContext) {
    const data = await request.validateUsing(createUserValidator)

    const user = await User.create({
      name: data.name,
      phone: data.phone,
      email: data.email ?? null,
      password: data.password,
      isActive: true,
      createdBy: auth.getUserOrFail().id,
    })

    return created(response, await User.findOrFail(user.id), 'User created successfully')
  }

  async show({ auth, params, response }: HttpContext) {
    const user = await this.findOther(auth, params.id)
    return ok(response, user, 'User fetched successfully')
  }

  async update({ auth, params, request, response }: HttpContext) {
    const user = await this.findOther(auth, params.id)
    const data = await request.validateUsing(updateUserValidator, { meta: { userId: user.id } })

    user.merge({ name: data.name, phone: data.phone, email: data.email ?? null })
    await user.save()

    return ok(response, user, 'User updated successfully')
  }

  /**
   * PATCH /users/:id/status { is_active }: deactivating logs them out everywhere.
   */
  async status({ auth, params, request, response }: HttpContext) {
    const user = await this.findOther(auth, params.id)
    const { is_active: isActive } = await request.validateUsing(userStatusValidator)

    user.isActive = isActive
    await user.save()
    if (!isActive) await User.revokeTokens(user)

    return ok(response, user, isActive ? 'User activated' : 'User deactivated')
  }

  /**
   * PUT /users/:id/password: reset another user's password.
   */
  async resetPassword({ auth, params, request, response }: HttpContext) {
    const user = await this.findOther(auth, params.id)
    const { password } = await request.validateUsing(resetUserPasswordValidator)

    user.password = password
    await user.save()
    await User.revokeTokens(user)

    return ok(response, null, 'Password reset. The user was logged out of all devices')
  }

  private async findOther(auth: HttpContext['auth'], id: string | number) {
    if (Number(id) === auth.getUserOrFail().id) {
      throw new AppError('Use My Profile to change your own details')
    }
    return User.findOrFail(id)
  }
}
