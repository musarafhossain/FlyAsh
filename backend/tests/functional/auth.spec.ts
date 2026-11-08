import { test } from '@japa/runner'
import testUtils from '@adonisjs/core/services/test_utils'
import hash from '@adonisjs/core/services/hash'
import { DateTime } from 'luxon'
import User from '#models/user'
import PasswordResetOtp from '#models/password_reset_otp'
import { API, createUser } from '#tests/helpers'

test.group('Auth', (group) => {
  group.each.setup(() => testUtils.db().withGlobalTransaction())

  test('login returns the envelope with a token and snake_case user', async ({
    client,
    assert,
  }) => {
    const user = await createUser()
    const response = await client
      .post(`${API}/auth/login`)
      .json({ login: user.phone, password: 'secret123' })

    response.assertStatus(200)
    const body = response.body()
    assert.isTrue(body.success)
    assert.equal(body.status_code, 200)
    assert.isString(body.data.token)
    assert.equal(body.data.user.id, user.id)
    assert.property(body.data.user, 'is_active')
    assert.notProperty(body.data.user, 'password')
  })

  test('wrong password returns 400', async ({ client }) => {
    const user = await createUser()
    const response = await client
      .post(`${API}/auth/login`)
      .json({ login: user.phone, password: 'nope' })
    response.assertStatus(400)
    response.assertBodyContains({ success: false, message: 'Invalid phone/email or password' })
  })

  test('deactivated user gets 401', async ({ client }) => {
    const user = await createUser({ isActive: false })
    const response = await client.get(`${API}/auth/me`).loginAs(user)
    response.assertStatus(401)
  })

  test('change password keeps the current device and revokes others', async ({
    client,
    assert,
  }) => {
    const user = await createUser()
    await User.accessTokens.create(user) // other device
    const current = await User.accessTokens.create(user)

    const response = await client
      .put(`${API}/auth/password`)
      .bearerToken(current.value!.release())
      .json({
        current_password: 'secret123',
        password: 'newpass1',
        password_confirmation: 'newpass1',
      })

    response.assertStatus(200)
    const tokens = await User.accessTokens.all(user)
    assert.lengthOf(tokens, 1)
  })
})

test.group('Users', (group) => {
  group.each.setup(() => testUtils.db().withGlobalTransaction())

  test('list excludes the logged-in user', async ({ client, assert }) => {
    const me = await createUser()
    const other = await createUser()
    const response = await client.get(`${API}/users?limit=100`).loginAs(me)

    response.assertStatus(200)
    const ids = response.body().data.items.map((u: any) => u.id)
    assert.include(ids, other.id)
    assert.notInclude(ids, me.id)
    assert.containsSubset(response.body().data, { page: 1, limit: 100 })
  })

  test('cannot change yourself through /users/:id', async ({ client }) => {
    const me = await createUser()
    const response = await client
      .patch(`${API}/users/${me.id}/status`)
      .loginAs(me)
      .json({ is_active: false })
    response.assertStatus(400)
  })

  test('deactivating a user revokes their tokens', async ({ client, assert }) => {
    const me = await createUser()
    const other = await createUser()
    await User.accessTokens.create(other)

    const response = await client
      .patch(`${API}/users/${other.id}/status`)
      .loginAs(me)
      .json({ is_active: false })
    response.assertStatus(200)
    assert.lengthOf(await User.accessTokens.all(other), 0)
  })
})

test.group('Password reset', (group) => {
  group.each.setup(() => testUtils.db().withGlobalTransaction())

  async function createOtp(userId: number, otp = '123456') {
    return PasswordResetOtp.create({
      userId,
      otpHash: await hash.make(otp),
      attempts: 0,
      expiresAt: DateTime.now().plus({ minutes: 10 }),
      verifiedAt: null,
    })
  }

  test('forgot password always returns the same message', async ({ client }) => {
    const response = await client
      .post(`${API}/auth/forgot-password`)
      .json({ email: 'nobody@example.com' })
    response.assertStatus(200)
    response.assertBodyContains({ message: 'If this email is registered, an OTP has been sent' })
  })

  test('verify OTP → reset token → new password (single use)', async ({ client, assert }) => {
    const user = await createUser({ email: 'reset@example.com' })
    await createOtp(user.id)

    const verify = await client
      .post(`${API}/auth/verify-otp`)
      .json({ email: 'reset@example.com', otp: '123456' })
    verify.assertStatus(200)
    const token = verify.body().data.reset_token

    const reset = await client
      .post(`${API}/auth/reset-password`)
      .json({ reset_token: token, password: 'brandnew1', password_confirmation: 'brandnew1' })
    reset.assertStatus(200)

    const again = await client
      .post(`${API}/auth/reset-password`)
      .json({ reset_token: token, password: 'brandnew2', password_confirmation: 'brandnew2' })
    again.assertStatus(400)

    await user.refresh()
    assert.isTrue(await hash.verify(user.password, 'brandnew1'))
  })

  test('5 wrong OTPs delete the OTP', async ({ client, assert }) => {
    const user = await createUser({ email: 'wrong@example.com' })
    const otp = await createOtp(user.id)

    for (let i = 0; i < 5; i++) {
      await client
        .post(`${API}/auth/verify-otp`)
        .json({ email: 'wrong@example.com', otp: '999999' })
    }
    assert.isNull(await PasswordResetOtp.find(otp.id))
  })

  test('tampered reset token is rejected', async ({ client }) => {
    const response = await client
      .post(`${API}/auth/reset-password`)
      .json({ reset_token: 'abc.def', password: 'brandnew1', password_confirmation: 'brandnew1' })
    response.assertStatus(400)
  })
})
