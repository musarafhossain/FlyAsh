import { test } from '@japa/runner'
import testUtils from '@adonisjs/core/services/test_utils'
import ExpenseCategory from '#models/expense_category'
import { API, createUser } from '#tests/helpers'

test.group('Expenses', (group) => {
  group.each.setup(() => testUtils.db().withGlobalTransaction())

  test('categories: create, unique name, rename, deactivate', async ({ client, assert }) => {
    const user = await createUser()
    const created = await client
      .post(`${API}/expense-categories`)
      .loginAs(user)
      .json({ name: 'Test Cat' })
    created.assertStatus(201)
    const id = created.body().data.id

    const dup = await client
      .post(`${API}/expense-categories`)
      .loginAs(user)
      .json({ name: 'Test Cat' })
    dup.assertStatus(422)

    const renamed = await client
      .put(`${API}/expense-categories/${id}`)
      .loginAs(user)
      .json({ name: 'Renamed Cat', is_active: false })
    renamed.assertBodyContains({ data: { name: 'Renamed Cat', is_active: false } })

    const active = await client.get(`${API}/expense-categories?active=true`).loginAs(user)
    assert.notInclude(
      active.body().data.map((c: any) => c.id),
      id
    )
  })

  test('expenses: create, filter, period total, update, delete', async ({ client, assert }) => {
    const user = await createUser()
    const tiffin = await ExpenseCategory.create({ name: 'Tiffin T', isActive: true, sortOrder: 1 })
    const repair = await ExpenseCategory.create({ name: 'Repair T', isActive: true, sortOrder: 2 })

    const a = await client.post(`${API}/expenses`).loginAs(user).json({
      expense_category_id: tiffin.id,
      expense_date: '2026-10-05',
      amount: 850,
      note: 'Tiffin for 15 labours',
    })
    a.assertStatus(201)
    assert.containsSubset(a.body().data, {
      amount: '850.00',
      category: { id: tiffin.id, name: 'Tiffin T' },
      created_by: { id: user.id },
    })

    await client.post(`${API}/expenses`).loginAs(user).json({
      expense_category_id: repair.id,
      expense_date: '2026-10-06',
      amount: '1200.50',
    })

    const october = await client
      .get(`${API}/expenses?from=2026-10-01&to=2026-10-31&limit=1`)
      .loginAs(user)
    assert.equal(october.body().data.period_total, '2050.50')
    assert.lengthOf(october.body().data.items, 1)
    assert.equal(october.body().data.total, 2)

    const onlyTiffin = await client
      .get(`${API}/expenses?from=2026-10-01&to=2026-10-31&category_id=${tiffin.id}`)
      .loginAs(user)
    assert.equal(onlyTiffin.body().data.period_total, '850.00')

    const future = await client.post(`${API}/expenses`).loginAs(user).json({
      expense_category_id: tiffin.id,
      expense_date: '2099-01-01',
      amount: 10,
    })
    future.assertStatus(422)

    const id = a.body().data.id
    const updated = await client.put(`${API}/expenses/${id}`).loginAs(user).json({
      expense_category_id: repair.id,
      amount: 900,
    })
    updated.assertBodyContains({ data: { amount: '900.00', expense_date: '2026-10-05' } })

    const deleted = await client.delete(`${API}/expenses/${id}`).loginAs(user)
    deleted.assertStatus(200)
  })
})
