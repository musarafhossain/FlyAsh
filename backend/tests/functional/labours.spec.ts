import { test } from '@japa/runner'
import testUtils from '@adonisjs/core/services/test_utils'
import { API, createUser } from '#tests/helpers'

async function addLabour(client: any, user: any, body: Record<string, unknown>) {
  const response = await client.post(`${API}/labours`).loginAs(user).json(body)
  response.assertStatus(201)
  return response.body().data
}

async function mark(client: any, user: any, date: string, records: any[]) {
  const response = await client.put(`${API}/attendance`).loginAs(user).json({ date, records })
  response.assertStatus(200)
  return response.body().data
}

test.group('Labours & attendance', (group) => {
  group.each.setup(() => testUtils.db().withGlobalTransaction())

  test('add labour, list with today status, deactivate', async ({ client, assert }) => {
    const user = await createUser()
    const labour = await addLabour(client, user, {
      name: 'Kartik Mondal',
      wage_type: 'daily',
      wage_amount: 500,
      joining_date: '2026-10-01',
    })
    assert.containsSubset(labour, { wage_amount: '500.00', is_active: true, today_status: null })

    const status = await client
      .patch(`${API}/labours/${labour.id}/status`)
      .loginAs(user)
      .json({ is_active: false, left_date: '2026-10-20' })
    status.assertBodyContains({ data: { is_active: false, left_date: '2026-10-20' } })

    const list = await client.get(`${API}/labours?search=Kartik`).loginAs(user)
    assert.equal(list.body().data.items[0].id, labour.id)
  })

  test('attendance day: save, summary, clear, rules', async ({ client, assert }) => {
    const user = await createUser()
    const a = await addLabour(client, user, {
      name: 'A',
      wage_type: 'daily',
      wage_amount: 400,
      joining_date: '2026-10-01',
    })
    const b = await addLabour(client, user, {
      name: 'B',
      wage_type: 'daily',
      wage_amount: 400,
      joining_date: '2026-10-01',
    })
    const late = await addLabour(client, user, {
      name: 'Late',
      wage_type: 'daily',
      wage_amount: 400,
      joining_date: '2026-10-15',
    })

    const day = await mark(client, user, '2026-10-02', [
      { labour_id: a.id, status: 'present' },
      { labour_id: b.id, status: 'half_day' },
    ])
    assert.containsSubset(day.summary, { present: 1, half_day: 1 })
    assert.notInclude(
      day.items.map((i: any) => i.labour_id),
      late.id
    )

    const cleared = await mark(client, user, '2026-10-02', [{ labour_id: b.id, status: null }])
    assert.equal(cleared.items.find((i: any) => i.labour_id === b.id).status, null)

    const notEmployed = await client
      .put(`${API}/attendance`)
      .loginAs(user)
      .json({ date: '2026-10-02', records: [{ labour_id: late.id, status: 'present' }] })
    notEmployed.assertStatus(400)

    const future = await client
      .put(`${API}/attendance`)
      .loginAs(user)
      .json({ date: '2099-01-01', records: [] })
    future.assertStatus(422)

    const calendar = await client
      .get(`${API}/labours/${a.id}/attendance?month=2026-10`)
      .loginAs(user)
    assert.lengthOf(calendar.body().data.days, 31)
    assert.equal(calendar.body().data.summary.present, 1)
  })
})

test.group('Wages', (group) => {
  group.each.setup(() => testUtils.db().withGlobalTransaction())

  test('daily wage: half day, advances, payments, balance, status', async ({ client, assert }) => {
    const user = await createUser()
    const labour = await addLabour(client, user, {
      name: 'Daily Worker',
      wage_type: 'daily',
      wage_amount: 500,
      joining_date: '2026-10-01',
    })

    await mark(client, user, '2026-10-01', [{ labour_id: labour.id, status: 'present' }])
    await mark(client, user, '2026-10-02', [{ labour_id: labour.id, status: 'half_day' }])
    await mark(client, user, '2026-10-03', [{ labour_id: labour.id, status: 'absent' }])

    let sheet = await client.get(`${API}/wages?month=2026-10`).loginAs(user)
    let row = sheet.body().data.items.find((r: any) => r.labour_id === labour.id)
    assert.containsSubset(row, {
      worked_days: '1.50',
      earned: '750.00',
      status: 'due',
      not_marked_days: 28,
    })

    const adv = await client
      .post(`${API}/labours/${labour.id}/advances`)
      .loginAs(user)
      .json({ amount: 200, advance_date: '2026-10-05' })
    adv.assertStatus(201)

    const pay = await client
      .post(`${API}/labours/${labour.id}/wage-payments`)
      .loginAs(user)
      .json({ wage_month: '2026-10', amount: 300 })
    pay.assertStatus(201)

    sheet = await client.get(`${API}/wages?month=2026-10`).loginAs(user)
    row = sheet.body().data.items.find((r: any) => r.labour_id === labour.id)
    assert.containsSubset(row, {
      advances: '200.00',
      paid: '300.00',
      balance: '250.00',
      status: 'partial',
    })
    assert.property(sheet.body().data, 'totals')

    const detail = await client.get(`${API}/labours/${labour.id}/wages?month=2026-10`).loginAs(user)
    assert.lengthOf(detail.body().data.days, 3)
    assert.lengthOf(detail.body().data.advances, 1)
    assert.equal(detail.body().data.payments[0].created_by.id, user.id)
  })

  test('monthly wage uses days in month and keeps the wage snapshot', async ({
    client,
    assert,
  }) => {
    const user = await createUser()
    // October has 31 days → 31000 / 31 = 1000 per day
    const labour = await addLabour(client, user, {
      name: 'Monthly Worker',
      wage_type: 'monthly',
      wage_amount: 31000,
      joining_date: '2026-10-01',
    })

    await mark(client, user, '2026-10-01', [{ labour_id: labour.id, status: 'present' }])
    await mark(client, user, '2026-10-02', [{ labour_id: labour.id, status: 'present' }])

    // Wage doubles: only newly saved days use the new wage
    const update = await client.put(`${API}/labours/${labour.id}`).loginAs(user).json({
      name: 'Monthly Worker',
      wage_type: 'monthly',
      wage_amount: 62000,
      joining_date: '2026-10-01',
    })
    update.assertStatus(200)

    await mark(client, user, '2026-10-03', [{ labour_id: labour.id, status: 'present' }]) // 2000
    await mark(client, user, '2026-10-01', [{ labour_id: labour.id, status: 'half_day' }]) // 500 (old snapshot)

    const detail = await client.get(`${API}/labours/${labour.id}/wages?month=2026-10`).loginAs(user)
    // 500 + 1000 + 2000
    assert.equal(detail.body().data.earned, '3500.00')
  })
})
