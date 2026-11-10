import { test } from '@japa/runner'
import testUtils from '@adonisjs/core/services/test_utils'
import { API, createUser } from '#tests/helpers'

test.group('Expenses', (group) => {
  group.each.setup(() => testUtils.db().withGlobalTransaction())

  test('category is free text; filter, search, period total, update, delete', async ({
    client,
    assert,
  }) => {
    const user = await createUser()

    const a = await client.post(`${API}/expenses`).loginAs(user).json({
      category: '  Tiffin   T ',
      expense_date: '2026-10-05',
      amount: 850,
      note: 'Tiffin for 15 labours',
    })
    a.assertStatus(201)
    assert.containsSubset(a.body().data, {
      amount: '850.00',
      category: 'Tiffin T',
      created_by: { id: user.id },
    })

    // Same category in other letters → saved with the spelling already used
    const b = await client.post(`${API}/expenses`).loginAs(user).json({
      category: 'tiffin t',
      expense_date: '2026-10-06',
      amount: '100',
    })
    assert.equal(b.body().data.category, 'Tiffin T')

    await client.post(`${API}/expenses`).loginAs(user).json({
      category: 'Generator rent',
      expense_date: '2026-10-07',
      amount: '1200.50',
    })

    const october = await client
      .get(`${API}/expenses?from=2026-10-01&to=2026-10-31&limit=1`)
      .loginAs(user)
    assert.equal(october.body().data.period_total, '2150.50')
    assert.lengthOf(october.body().data.items, 1)
    assert.equal(october.body().data.total, 3)

    const onlyTiffin = await client
      .get(`${API}/expenses?from=2026-10-01&to=2026-10-31&category=Tiffin T`)
      .loginAs(user)
    assert.equal(onlyTiffin.body().data.period_total, '950.00')

    const search = await client.get(`${API}/expenses?search=generator`).loginAs(user)
    assert.equal(search.body().data.total, 1)

    // Suggestions: used ones (most used first), then the defaults
    const names = (await client.get(`${API}/expense-categories`).loginAs(user)).body().data
    assert.deepEqual(names.slice(0, 2), ['Tiffin T', 'Generator rent'])
    assert.include(names, 'Labour Tiffin')

    const missing = await client.post(`${API}/expenses`).loginAs(user).json({ amount: 10 })
    missing.assertStatus(422)

    const future = await client.post(`${API}/expenses`).loginAs(user).json({
      category: 'Tiffin T',
      expense_date: '2099-01-01',
      amount: 10,
    })
    future.assertStatus(422)

    const id = a.body().data.id
    const updated = await client.put(`${API}/expenses/${id}`).loginAs(user).json({
      category: 'Machine repair',
      amount: 900,
    })
    updated.assertBodyContains({
      data: { amount: '900.00', expense_date: '2026-10-05', category: 'Machine Repair' },
    })

    const deleted = await client.delete(`${API}/expenses/${id}`).loginAs(user)
    deleted.assertStatus(200)
  })
})
