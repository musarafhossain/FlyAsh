import { test } from '@japa/runner'
import testUtils from '@adonisjs/core/services/test_utils'
import { API, createUser } from '#tests/helpers'

test.group('Products', (group) => {
  group.each.setup(() => testUtils.db().withGlobalTransaction())

  test('create, list with margin, validation', async ({ client, assert }) => {
    const user = await createUser()

    const created = await client.post(`${API}/products`).loginAs(user).json({
      name: 'Fly Ash Brick 9x4x3',
      unit: 'piece',
      default_cost: '4.20',
      default_price: 6.5,
    })
    created.assertStatus(201)
    assert.containsSubset(created.body().data, {
      name: 'Fly Ash Brick 9x4x3',
      default_cost: '4.20',
      default_price: '6.50',
      margin: '2.30',
      is_active: true,
    })

    const duplicate = await client.post(`${API}/products`).loginAs(user).json({
      name: 'Fly Ash Brick 9x4x3',
      unit: 'other',
      default_cost: 1,
      default_price: 1,
    })
    duplicate.assertStatus(422)
    const fields = duplicate.body().data.errors.map((e: any) => e.field)
    assert.includeMembers(fields, ['name', 'unit_label'])

    const list = await client.get(`${API}/products?search=Fly`).loginAs(user)
    list.assertStatus(200)
    assert.equal(list.body().data.total, 1)
  })

  test('deactivate and delete an unused product', async ({ client }) => {
    const user = await createUser()
    const product = await client.post(`${API}/products`).loginAs(user).json({
      name: 'Block',
      unit: 'piece',
      default_cost: 10,
      default_price: 15,
    })
    const id = product.body().data.id

    const status = await client
      .patch(`${API}/products/${id}/status`)
      .loginAs(user)
      .json({ is_active: false })
    status.assertBodyContains({ data: { is_active: false } })

    const deleted = await client.delete(`${API}/products/${id}`).loginAs(user)
    deleted.assertStatus(200)
  })
})

test.group('Customers', (group) => {
  group.each.setup(() => testUtils.db().withGlobalTransaction())

  test('create with totals, duplicate phone returns existing id', async ({ client, assert }) => {
    const user = await createUser()

    const first = await client
      .post(`${API}/customers`)
      .loginAs(user)
      .json({ name: 'Rahim Traders', phone: '9800000001', address: 'Barasat' })
    first.assertStatus(201)
    assert.containsSubset(first.body().data, {
      name: 'Rahim Traders',
      total_sales: '0.00',
      total_due: '0.00',
    })

    const duplicate = await client
      .post(`${API}/customers`)
      .loginAs(user)
      .json({ name: 'Someone', phone: '9800000001' })
    duplicate.assertStatus(422)
    assert.equal(duplicate.body().data.existing_customer_id, first.body().data.id)

    // Phone is optional
    const noPhone = await client
      .post(`${API}/customers`)
      .loginAs(user)
      .json({ name: 'Walk-in Buyer' })
    noPhone.assertStatus(201)
    assert.isNull(noPhone.body().data.phone)
    const cleared = await client
      .put(`${API}/customers/${first.body().data.id}`)
      .loginAs(user)
      .json({ name: 'Rahim Traders', phone: null })
    cleared.assertStatus(200)
    assert.isNull(cleared.body().data.phone)
  })

  test('list, search and update', async ({ client, assert }) => {
    const user = await createUser()
    const created = await client
      .post(`${API}/customers`)
      .loginAs(user)
      .json({ name: 'Karim', phone: '9800000002' })
    const id = created.body().data.id

    const list = await client.get(`${API}/customers?search=980000000&page=1&limit=10`).loginAs(user)
    list.assertStatus(200)
    assert.equal(list.body().data.limit, 10)
    assert.isAtLeast(list.body().data.items.length, 1)

    const updated = await client
      .put(`${API}/customers/${id}`)
      .loginAs(user)
      .json({ name: 'Karim Sheikh', phone: '9800000002', address: null })
    updated.assertBodyContains({ data: { name: 'Karim Sheikh', address: null } })

    const hasDue = await client.get(`${API}/customers?has_due=true`).loginAs(user)
    hasDue.assertStatus(200)
  })
})
