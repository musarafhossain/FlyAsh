import { test } from '@japa/runner'
import Attendance from '#models/attendance'
import testUtils from '@adonisjs/core/services/test_utils'
import { API, createUser } from '#tests/helpers'

async function addLabour(client: any, user: any, body: Record<string, unknown>) {
  const response = await client.post(`${API}/labours`).loginAs(user).json(body)
  response.assertStatus(201)
  return response.body().data
}

async function mark(client: any, user: any, date: string, records: any[], onlySaved = false) {
  const response = await client
    .put(`${API}/attendance${onlySaved ? '?rows=saved' : ''}`)
    .loginAs(user)
    .json({ date, records })
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
    assert.containsSubset(labour, { wage_amount: '500.00', is_active: true, present_today: false })

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
      { labour_id: a.id, present: true },
      { labour_id: b.id, present: true },
    ])
    assert.containsSubset(day.summary, { total: 2, present: 2, absent: 0 })
    assert.isTrue(day.items.find((i: any) => i.labour_id === a.id).present)
    assert.notInclude(
      day.items.map((i: any) => i.labour_id),
      late.id
    )

    // Absent removes the row; marking present twice keeps one row
    const absent = await mark(client, user, '2026-10-02', [{ labour_id: b.id, present: false }])
    assert.isFalse(absent.items.find((i: any) => i.labour_id === b.id).present)
    assert.containsSubset(absent.summary, { present: 1, absent: 1 })
    await mark(client, user, '2026-10-02', [{ labour_id: a.id, present: true }])
    const rows = await Attendance.query().where('date', '2026-10-02')
    assert.deepEqual(
      rows.map((r) => r.labourId),
      [a.id]
    )

    const notEmployed = await client
      .put(`${API}/attendance`)
      .loginAs(user)
      .json({ date: '2026-10-02', records: [{ labour_id: late.id, present: true }] })
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
    assert.isTrue(calendar.body().data.days[1].present) // 2 Oct
    assert.isFalse(calendar.body().data.days[0].present)
  })

  test('attendance day: 20 a page, search, summary for the whole day', async ({
    client,
    assert,
  }) => {
    const user = await createUser()
    const ids: string[] = []
    for (let i = 1; i <= 25; i++) {
      const lb = await addLabour(client, user, {
        name: `Worker ${String(i).padStart(2, '0')}`,
        wage_type: 'daily',
        wage_amount: 400,
        joining_date: '2026-10-01',
      })
      ids.push(lb.id)
    }
    // 3 present, one of them on page 2
    const saved = await mark(
      client,
      user,
      '2026-10-05',
      [
        { labour_id: ids[0], present: true },
        { labour_id: ids[1], present: true },
        { labour_id: ids[22], present: true },
      ],
      true
    )
    // PUT ?rows=saved answers with only the saved rows and the day's summary
    assert.lengthOf(saved.items, 3)
    assert.containsSubset(saved.summary, { total: 25, present: 3, absent: 22 })

    // Older apps (no page, no rows=saved) still get every labour
    const legacyPut = await mark(client, user, '2026-10-05', [{ labour_id: ids[3], present: true }])
    assert.lengthOf(legacyPut.items, 25)
    const legacyGet = (await client.get(`${API}/attendance?date=2026-10-05`).loginAs(user)).body()
      .data
    assert.lengthOf(legacyGet.items, 25)

    const get = async (q: string) =>
      (await client.get(`${API}/attendance?date=2026-10-05&${q}`).loginAs(user)).body().data
    const page1 = await get('page=1')
    assert.lengthOf(page1.items, 20)
    assert.containsSubset(page1, { page: 1, limit: 20, total: 25, last_page: 2 })
    assert.containsSubset(page1.summary, { total: 25, present: 4, absent: 21 })
    assert.equal(page1.items[0].name, 'Worker 01')
    const page2 = await get('page=2')
    assert.lengthOf(page2.items, 5)
    assert.isTrue(page2.items.find((i: any) => i.labour_id === ids[22]).present)

    const search = await get('search=Worker 2')
    assert.sameMembers(
      search.items.map((i: any) => i.name),
      ['Worker 20', 'Worker 21', 'Worker 22', 'Worker 23', 'Worker 24', 'Worker 25']
    )
    assert.equal(search.total, 6)
    assert.equal(search.summary.total, 25, 'summary ignores the search')
  })

  test('day wage: default when absent, saved wage when present, custom wage', async ({
    client,
    assert,
  }) => {
    const user = await createUser()
    const daily = await addLabour(client, user, {
      name: 'Daily',
      wage_type: 'daily',
      wage_amount: 450,
      joining_date: '2026-10-01',
    })
    const monthly = await addLabour(client, user, {
      name: 'Monthly',
      wage_type: 'monthly',
      wage_amount: 31000,
      joining_date: '2026-10-01',
    })
    const of = (day: any, id: string) => day.items.find((i: any) => i.labour_id === id)

    // Absent: the usual wage — a day's for daily, the MONTH's for monthly
    const sheet = (await client.get(`${API}/attendance?date=2026-10-03`).loginAs(user)).body().data
    assert.equal(of(sheet, daily.id).day_wage, '450.00')
    assert.containsSubset(of(sheet, monthly.id), { wage_type: 'monthly', day_wage: '31000.00' })

    // Present with a custom wage: saved as that day's daily wage (daily
    // labours only; for a monthly labour the wage is ignored)
    const day = await mark(client, user, '2026-10-03', [
      { labour_id: daily.id, present: true, wage: 600 },
      { labour_id: monthly.id, present: true, wage: 800.5 },
    ])
    assert.equal(of(day, daily.id).day_wage, '600.00')
    assert.containsSubset(of(day, monthly.id), { wage_type: 'monthly', day_wage: '31000.00' })
    // The usual wage stays available next to the saved one
    assert.equal(of(day, daily.id).default_day_wage, '450.00')
    assert.equal(of(day, monthly.id).default_day_wage, '31000.00')

    // Already present: a new wage is ignored (the saved day keeps its wage)
    const again = await mark(client, user, '2026-10-03', [
      { labour_id: daily.id, present: true, wage: 999 },
    ])
    assert.equal(of(again, daily.id).day_wage, '600.00')

    // One present day in October earns the full monthly wage
    const wages = await client.get(`${API}/labours/${monthly.id}/wages?month=2026-10`).loginAs(user)
    assert.equal(wages.body().data.earned, '31000.00')
    const dailyWages = (
      await client.get(`${API}/labours/${daily.id}/wages?month=2026-10`).loginAs(user)
    ).body().data
    assert.equal(dailyWages.earned, '600.00')

    // Lifetime totals on the labour: earned − paid
    await client
      .post(`${API}/labours/${monthly.id}/wage-payments`)
      .loginAs(user)
      .json({ wage_month: '2026-10', amount: 300, payment_date: '2026-10-05' })
    const life = (await client.get(`${API}/labours/${monthly.id}`).loginAs(user)).body().data
    assert.containsSubset(life, {
      total_earned: '31000.00',
      total_paid: '300.00',
      total_balance: '30700.00',
    })
    const listed = (await client.get(`${API}/labours?search=Monthly`).loginAs(user)).body().data
    assert.equal(listed.items[0].total_balance, '30700.00')
    const detail = (
      await client.get(`${API}/labours/${monthly.id}/wages?month=2026-11`).loginAs(user)
    ).body().data
    assert.deepEqual(detail.lifetime, { earned: '31000.00', paid: '300.00', balance: '30700.00' })
    // No present day in November: nothing earned that month
    assert.equal(detail.earned, '0.00')

    // Absent again: back to the default
    const cleared = await mark(client, user, '2026-10-03', [
      { labour_id: daily.id, present: false },
    ])
    assert.equal(of(cleared, daily.id).day_wage, '450.00')

    const bad = await client
      .put(`${API}/attendance`)
      .loginAs(user)
      .json({ date: '2026-10-03', records: [{ labour_id: daily.id, present: true, wage: 0 }] })
    bad.assertStatus(422)
  })
})

test.group('Wages', (group) => {
  group.each.setup(() => testUtils.db().withGlobalTransaction())

  test('daily wage: present days, absent days, payments, balance (no advances)', async ({
    client,
    assert,
  }) => {
    const user = await createUser()
    const labour = await addLabour(client, user, {
      name: 'Daily Worker',
      wage_type: 'daily',
      wage_amount: 500,
      joining_date: '2026-10-01',
    })

    await mark(client, user, '2026-10-01', [{ labour_id: labour.id, present: true }])
    await mark(client, user, '2026-10-02', [{ labour_id: labour.id, present: true }])
    await mark(client, user, '2026-10-03', [{ labour_id: labour.id, present: false }])

    let sheet = await client.get(`${API}/wages?month=2026-10`).loginAs(user)
    let row = sheet.body().data.items.find((r: any) => r.labour_id === labour.id)
    assert.containsSubset(row, {
      present_days: 2,
      absent_days: 29, // October so far (today is after October): 31 − 2
      earned: '1000.00',
      status: 'due',
    })

    // An advance is just a wage payment made early
    const early = await client
      .post(`${API}/labours/${labour.id}/wage-payments`)
      .loginAs(user)
      .json({ wage_month: '2026-10', amount: 200, payment_date: '2026-10-05' })
    early.assertStatus(201)

    const pay = await client
      .post(`${API}/labours/${labour.id}/wage-payments`)
      .loginAs(user)
      .json({ wage_month: '2026-10', amount: 300 })
    pay.assertStatus(201)

    const gone = await client
      .post(`${API}/labours/${labour.id}/advances`)
      .loginAs(user)
      .json({ amount: 200 })
    gone.assertStatus(404)

    sheet = await client.get(`${API}/wages?month=2026-10`).loginAs(user)
    row = sheet.body().data.items.find((r: any) => r.labour_id === labour.id)
    assert.containsSubset(row, {
      paid: '500.00',
      balance: '500.00',
      status: 'partial',
    })
    assert.notProperty(row, 'advances')
    assert.notProperty(sheet.body().data.totals, 'advances')

    const detail = await client.get(`${API}/labours/${labour.id}/wages?month=2026-10`).loginAs(user)
    assert.lengthOf(detail.body().data.days, 2)
    assert.lengthOf(detail.body().data.payments, 2)
    assert.notProperty(detail.body().data, 'advances')
    assert.equal(detail.body().data.payments[0].created_by.id, user.id)
  })

  test('monthly wage: the full month when present at least one day; latest amount counts', async ({
    client,
    assert,
  }) => {
    const user = await createUser()
    const labour = await addLabour(client, user, {
      name: 'Monthly Worker',
      wage_type: 'monthly',
      wage_amount: 31000,
      joining_date: '2026-10-01',
    })

    await mark(client, user, '2026-10-01', [{ labour_id: labour.id, present: true }])
    await mark(client, user, '2026-10-02', [{ labour_id: labour.id, present: true }])

    // Wage doubles: only newly saved days use the new wage
    const update = await client.put(`${API}/labours/${labour.id}`).loginAs(user).json({
      name: 'Monthly Worker',
      wage_type: 'monthly',
      wage_amount: 62000,
      joining_date: '2026-10-01',
    })
    update.assertStatus(200)

    await mark(client, user, '2026-10-03', [{ labour_id: labour.id, present: true }])
    // Marking an already present day again keeps its old snapshot
    await mark(client, user, '2026-10-01', [{ labour_id: labour.id, present: true }])

    // 3 present days → one full month, at the latest saved wage (62,000)
    const detail = (
      await client.get(`${API}/labours/${labour.id}/wages?month=2026-10`).loginAs(user)
    ).body().data
    assert.containsSubset(detail, { present_days: 3, earned: '62000.00' })
    // The days add up to the month: the wage sits on the first present day
    assert.deepEqual(
      detail.days.map((d: any) => [d.date, d.earned]),
      [
        ['2026-10-03', '0.00'],
        ['2026-10-02', '0.00'],
        ['2026-10-01', '62000.00'],
      ]
    )

    // One day in November → November's full wage too; lifetime = 2 months
    await mark(client, user, '2026-11-02', [{ labour_id: labour.id, present: true }])
    const nov = (
      await client.get(`${API}/labours/${labour.id}/wages?month=2026-11`).loginAs(user)
    ).body().data
    assert.equal(nov.earned, '62000.00')
    const life = (await client.get(`${API}/labours/${labour.id}`).loginAs(user)).body().data
    assert.equal(life.total_earned, '124000.00')
    const sheet = (await client.get(`${API}/wages?month=2026-10`).loginAs(user)).body().data
    assert.equal(sheet.items.find((r: any) => r.labour_id === labour.id).earned, '62000.00')
  })
})
