import { test } from '@japa/runner'
import testUtils from '@adonisjs/core/services/test_utils'
import { API, createUser } from '#tests/helpers'

/**
 * Wage calculation end to end (01-PRD §6.3, 2026-11-16) through the real
 * endpoints: daily (per present day), monthly (the full month when present
 * at least one day), raises, payments → balance and status, joining and
 * leaving mid-month, and the lifetime totals (calculated in SQL) agreeing
 * with the sum of the monthly wage pages.
 */
async function addLabour(client: any, user: any, body: Record<string, unknown>) {
  const res = await client.post(`${API}/labours`).loginAs(user).json(body)
  res.assertStatus(201)
  return res.body().data
}

async function present(client: any, user: any, labourId: string, dates: string[]) {
  for (const date of dates) {
    const res = await client
      .put(`${API}/attendance`)
      .loginAs(user)
      .json({ date, records: [{ labour_id: labourId, present: true }] })
    res.assertStatus(200)
  }
}

async function pay(client: any, user: any, labourId: string, month: string, amount: number, date: string) {
  const res = await client
    .post(`${API}/labours/${labourId}/wage-payments`)
    .loginAs(user)
    .json({ wage_month: month, amount, payment_date: date })
  res.assertStatus(201)
}

async function month(client: any, user: any, labourId: string, ym: string) {
  return (await client.get(`${API}/labours/${labourId}/wages?month=${ym}`).loginAs(user)).body()
    .data
}

async function setWage(client: any, user: any, lb: any, type: string, amount: number) {
  const res = await client.put(`${API}/labours/${lb.id}`).loginAs(user).json({
    name: lb.name,
    wage_type: type,
    wage_amount: amount,
    joining_date: lb.joining_date,
  })
  res.assertStatus(200)
}

const MONTHS = ['2026-08', '2026-09', '2026-10', '2026-11']

test.group('Wage calculation', (group) => {
  group.each.setup(() => testUtils.db().withGlobalTransaction())

  test('monthly: full month per month with a present day; raise; payments; status', async ({
    client,
    assert,
  }) => {
    const user = await createUser()
    const lb = await addLabour(client, user, {
      name: 'Monthly M',
      wage_type: 'monthly',
      wage_amount: 9000,
      joining_date: '2026-08-01',
    })
    await present(client, user, lb.id, ['2026-08-10']) // 1 day in August
    // September: absent all month
    await present(client, user, lb.id, ['2026-10-01', '2026-10-02', '2026-10-03'])
    await setWage(client, user, lb, 'monthly', 12000) // raise in October
    await present(client, user, lb.id, ['2026-10-20', '2026-11-01'])

    await pay(client, user, lb.id, '2026-08', 9000, '2026-09-02')
    await pay(client, user, lb.id, '2026-10', 5000, '2026-11-03')

    const [aug, sep, oct, nov] = await Promise.all(MONTHS.map((ym) => month(client, user, lb.id, ym)))
    assert.containsSubset(aug, { present_days: 1, earned: '9000.00', paid: '9000.00', balance: '0.00', status: 'paid' })
    assert.containsSubset(sep, { present_days: 0, earned: '0.00', paid: '0.00', balance: '0.00' })
    // October: 4 days, latest saved wage after the raise = 12,000
    assert.containsSubset(oct, { present_days: 4, earned: '12000.00', paid: '5000.00', balance: '7000.00', status: 'partial' })
    assert.containsSubset(nov, { present_days: 1, earned: '12000.00', paid: '0.00', balance: '12000.00', status: 'due' })

    // Lifetime (SQL) = 9,000 + 0 + 12,000 + 12,000; paid 14,000
    const life = (await client.get(`${API}/labours/${lb.id}`).loginAs(user)).body().data
    assert.containsSubset(life, { total_earned: '33000.00', total_paid: '14000.00', total_balance: '19000.00' })
    const listed = (await client.get(`${API}/labours?search=Monthly M`).loginAs(user)).body().data
    assert.containsSubset(listed.items[0], { total_earned: '33000.00', total_balance: '19000.00' })
    assert.deepEqual(nov.lifetime, { earned: '33000.00', paid: '14000.00', balance: '19000.00' })

    // Attendance shows the monthly wage (after the raise), not a day's
    const day = (await client.get(`${API}/attendance?date=2026-11-01&page=1`).loginAs(user)).body()
      .data
    const row = day.items.find((i: any) => i.labour_id === lb.id)
    assert.containsSubset(row, { wage_type: 'monthly', present: true, day_wage: '12000.00', default_day_wage: '12000.00' })
  })

  test('daily: per present day at the saved wage; raise; overpaid; absent days', async ({
    client,
    assert,
  }) => {
    const user = await createUser()
    const lb = await addLabour(client, user, {
      name: 'Daily D',
      wage_type: 'daily',
      wage_amount: 500,
      joining_date: '2026-10-10',
    })
    await present(client, user, lb.id, ['2026-10-10', '2026-10-11'])
    await setWage(client, user, lb, 'daily', 600)
    await present(client, user, lb.id, ['2026-10-12'])
    await pay(client, user, lb.id, '2026-10', 2000, '2026-10-31')

    const oct = await month(client, user, lb.id, '2026-10')
    assert.containsSubset(oct, {
      present_days: 3,
      absent_days: 19, // employed 10–31 Oct = 22 days, 3 present
      earned: '1600.00', // 500 + 500 + 600
      paid: '2000.00',
      balance: '-400.00', // paid ahead
      status: 'paid',
    })
    assert.deepEqual(
      oct.days.map((x: any) => [x.date, x.earned]),
      [
        ['2026-10-12', '600.00'],
        ['2026-10-11', '500.00'],
        ['2026-10-10', '500.00'],
      ]
    )
  })

  test('monthly labour who left mid-month still earns that month in full', async ({
    client,
    assert,
  }) => {
    const user = await createUser()
    const lb = await addLabour(client, user, {
      name: 'Leaver L',
      wage_type: 'monthly',
      wage_amount: 6000,
      joining_date: '2026-10-01',
    })
    await present(client, user, lb.id, ['2026-10-02'])
    const left = await client
      .patch(`${API}/labours/${lb.id}/status`)
      .loginAs(user)
      .json({ is_active: false, left_date: '2026-10-05' })
    left.assertStatus(200)

    // No attendance after leaving
    const after = await client
      .put(`${API}/attendance`)
      .loginAs(user)
      .json({ date: '2026-10-06', records: [{ labour_id: lb.id, present: true }] })
    after.assertStatus(400)

    assert.equal((await month(client, user, lb.id, '2026-10')).earned, '6000.00')
    assert.equal((await month(client, user, lb.id, '2026-11')).earned, '0.00')
  })

  test('switch daily → monthly mid-month: daily days + the full month', async ({
    client,
    assert,
  }) => {
    const user = await createUser()
    const lb = await addLabour(client, user, {
      name: 'Switcher S',
      wage_type: 'daily',
      wage_amount: 500,
      joining_date: '2026-10-01',
    })
    await present(client, user, lb.id, ['2026-10-01', '2026-10-02'])
    await setWage(client, user, lb, 'monthly', 15000)
    await present(client, user, lb.id, ['2026-10-15'])
    assert.equal((await month(client, user, lb.id, '2026-10')).earned, '16000.00')
  })

  test('lifetime (SQL) equals the sum of the monthly pages for every labour', async ({
    client,
    assert,
  }) => {
    const user = await createUser()
    const plans: Array<[Record<string, unknown>, string[], (lb: any) => Promise<void>]> = [
      [
        { name: 'Mix A', wage_type: 'monthly', wage_amount: 14000, joining_date: '2026-08-01' },
        ['2026-08-03', '2026-08-04', '2026-10-30', '2026-10-31', '2026-11-01'],
        async () => {},
      ],
      [
        { name: 'Mix B', wage_type: 'daily', wage_amount: 450.5, joining_date: '2026-08-01' },
        ['2026-08-01', '2026-09-15', '2026-09-16', '2026-11-02'],
        async () => {},
      ],
      [
        { name: 'Mix C', wage_type: 'monthly', wage_amount: 10000, joining_date: '2026-09-01' },
        ['2026-09-01'],
        async (lb) => {
          await setWage(client, user, lb, 'monthly', 11000)
          await present(client, user, lb.id, ['2026-09-20', '2026-11-10'])
        },
      ],
    ]
    for (const [body, days, after] of plans) {
      const lb = await addLabour(client, user, body)
      await present(client, user, lb.id, days)
      await after(lb)

      let sum = 0
      for (const ym of MONTHS) sum += Number((await month(client, user, lb.id, ym)).earned)
      const life = (await client.get(`${API}/labours/${lb.id}`).loginAs(user)).body().data
      assert.equal(life.total_earned, sum.toFixed(2), `${body.name}`)
    }

    // Expected by hand: A = Aug + Oct + Nov = 42,000; B = 4 × 450.50 = 1,802;
    // C = Sep (latest 11,000) + Nov 11,000 = 22,000
    const all = (await client.get(`${API}/labours?search=Mix`).loginAs(user)).body().data.items
    const byName = Object.fromEntries(all.map((l: any) => [l.name, l.total_earned]))
    assert.deepEqual(byName, { 'Mix A': '42000.00', 'Mix B': '1802.00', 'Mix C': '22000.00' })
  })
})
