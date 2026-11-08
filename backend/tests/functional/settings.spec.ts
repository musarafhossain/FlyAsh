import { test } from '@japa/runner'
import testUtils from '@adonisjs/core/services/test_utils'
import AppVersion from '#models/app_version'
import Product from '#models/product'
import Customer from '#models/customer'
import { API, createUser } from '#tests/helpers'

test.group('Settings', (group) => {
  group.each.setup(() => testUtils.db().withGlobalTransaction())

  test('factory profile: read, update, invoice prefix used by new sales', async ({ client, assert }) => {
    const user = await createUser()

    const read = await client.get(`${API}/settings/factory`).loginAs(user)
    read.assertStatus(200)
    assert.property(read.body().data, 'logo_url')

    const updated = await client.put(`${API}/settings/factory`).loginAs(user).json({
      factory_name: 'Maa Tara Fly Ash Bricks',
      phone: '9833333333',
      address: 'Barasat',
      invoice_prefix: 'mt-',
    })
    updated.assertBodyContains({ data: { factory_name: 'Maa Tara Fly Ash Bricks', invoice_prefix: 'MT-' } })

    const product = await Product.create({ name: 'P', unit: 'piece', defaultCost: '1.00', defaultPrice: '2.00', isActive: true })
    const customer = await Customer.create({ name: 'C', phone: '9844444444', isActive: true })
    const sale = await client.post(`${API}/sales`).loginAs(user).json({
      type: 'instant',
      customer_id: customer.id,
      items: [{ product_id: product.id, quantity: 1 }],
    })
    assert.match(sale.body().data.invoice_no, /^MT-\d{6}$/)
  })
})

test.group('App version', (group) => {
  group.each.setup(() => testUtils.db().withGlobalTransaction())

  test('no release yet', async ({ client }) => {
    const response = await client.get(`${API}/app/version?platform=windows&build=1`)
    response.assertStatus(200)
    response.assertBodyContains({ data: { update_available: false, force_update: false } })
  })

  test('optional and forced updates', async ({ client, assert }) => {
    await AppVersion.create({
      platform: 'android',
      versionName: '1.2.0',
      buildNumber: 12,
      minSupportedBuild: 10,
      downloadUrl: 'https://example.com/flyash-1.2.0.apk',
      releaseNotes: 'New reports',
      isActive: true,
    })

    const optional = (await client.get(`${API}/app/version?platform=android&build=11`)).body().data
    assert.containsSubset(optional, { latest_version: '1.2.0', update_available: true, force_update: false })

    const forced = (await client.get(`${API}/app/version?platform=android&build=9`)).body().data
    assert.containsSubset(forced, { update_available: true, force_update: true })

    const current = (await client.get(`${API}/app/version?platform=android&build=12`)).body().data
    assert.containsSubset(current, { update_available: false, force_update: false })
  })
})
