import { test } from '@japa/runner'
import testUtils from '@adonisjs/core/services/test_utils'
import { API, createUser } from '#tests/helpers'

test.group('Localization (Accept-Language)', (group) => {
  group.each.setup(() => testUtils.db().withGlobalTransaction())

  test('English is the default', async ({ client }) => {
    const response = await client
      .post(`${API}/auth/login`)
      .json({ login: '9000000000', password: 'x' })
    response.assertBodyContains({ message: 'Invalid phone/email or password' })
    response.assertHeader('content-language', 'en')
  })

  test('Bengali business errors and success messages', async ({ client, assert }) => {
    const wrong = await client
      .post(`${API}/auth/login`)
      .header('Accept-Language', 'bn')
      .json({ login: '9000000000', password: 'x' })
    wrong.assertBodyContains({ message: 'ফোন/ইমেইল অথবা পাসওয়ার্ড ভুল' })
    wrong.assertHeader('content-language', 'bn')

    const user = await createUser()
    const list = await client
      .get(`${API}/products`)
      .header('Accept-Language', 'bn-IN')
      .loginAs(user)
    assert.equal(list.body().message, 'প্রোডাক্টের তালিকা পাওয়া গেছে')
  })

  test('Bengali validation messages with field names and Latin digits', async ({
    client,
    assert,
  }) => {
    const user = await createUser()
    const response = await client
      .post(`${API}/users`)
      .header('Accept-Language', 'bn')
      .loginAs(user)
      .json({ name: 'A', phone: '123', password: '123' })

    response.assertStatus(422)
    assert.equal(response.body().message, 'তথ্যে ভুল আছে')
    const messages = Object.fromEntries(
      response.body().data.errors.map((e: any) => [e.field, e.message])
    )
    assert.equal(messages.phone, 'ফোন নম্বর সঠিক ফরম্যাটে নেই')
    assert.equal(messages.password, 'পাসওয়ার্ড কমপক্ষে 6 অক্ষরের হতে হবে')
  })

  test('messages with values are translated', async ({ client }) => {
    const user = await createUser()
    const response = await client
      .put(`${API}/attendance`)
      .header('Accept-Language', 'bn')
      .loginAs(user)
      .json({ date: '2026-10-01', records: [] })
    response.assertBodyContains({ message: '2026-10-01 তারিখের হাজিরা সেভ হয়েছে' })
  })

  test('unsupported language falls back to English', async ({ client }) => {
    const response = await client.get(`${API}/auth/me`).header('Accept-Language', 'fr')
    response.assertBodyContains({ message: 'Unauthorized' })
  })
})

test.group('User locale', (group) => {
  group.each.setup(() => testUtils.db().withGlobalTransaction())

  test('PUT /auth/locale saves the language and answers in it', async ({ client, assert }) => {
    const user = await createUser()
    const response = await client.put(`${API}/auth/locale`).loginAs(user).json({ locale: 'bn' })

    response.assertStatus(200)
    assert.equal(response.body().message, 'ভাষা বদলানো হয়েছে')
    assert.equal(response.body().data.locale, 'bn')
    response.assertHeader('content-language', 'bn')

    await user.refresh()
    assert.equal(user.locale, 'bn')
  })

  test('invalid locale is rejected', async ({ client }) => {
    const user = await createUser()
    const response = await client.put(`${API}/auth/locale`).loginAs(user).json({ locale: 'fr' })
    response.assertStatus(422)
  })

  test("without Accept-Language the user's saved language is used", async ({ client, assert }) => {
    const user = await createUser()
    user.locale = 'bn'
    await user.save()

    const saved = await client.get(`${API}/auth/me`).loginAs(user)
    assert.equal(saved.body().message, 'প্রোফাইল পাওয়া গেছে')

    // The header still wins when it is sent
    const header = await client.get(`${API}/auth/me`).header('Accept-Language', 'en').loginAs(user)
    assert.equal(header.body().message, 'Profile fetched successfully')
  })

  test('new users get en by default, or the given locale', async ({ client, assert }) => {
    const me = await createUser()
    const plain = await client
      .post(`${API}/users`)
      .loginAs(me)
      .json({ name: 'Default Locale', phone: '9811100001', password: 'secret123' })
    assert.equal(plain.body().data.locale, 'en')

    const bengali = await client
      .post(`${API}/users`)
      .loginAs(me)
      .json({ name: 'Bengali User', phone: '9811100002', password: 'secret123', locale: 'bn' })
    assert.equal(bengali.body().data.locale, 'bn')
  })
})
