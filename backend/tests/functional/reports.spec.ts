import { test } from '@japa/runner'
import testUtils from '@adonisjs/core/services/test_utils'
import Product from '#models/product'
import Customer from '#models/customer'
import ExpenseCategory from '#models/expense_category'
import { API, createUser } from '#tests/helpers'

/**
 * October 2026 sample:
 *  - instant sale 10 Oct: 1000 × 6.50 = 6500 (cost 4200, profit 2300), paid 1000 UPI
 *  - booking 11 Oct delivered 20 Oct: 2000 × 6.50 = 13000 (cost 8400, profit 4600), advance 3000 cash
 *  - booking 12 Oct not delivered: excluded from sales / profit / dues
 *  - expense 15 Oct: 850
 *  - daily labour ₹500 present 1 + 2 Oct: wages 1000
 */
async function seedOctober(client: any) {
  const user = await createUser()
  const brick = await Product.create({
    name: 'Report Brick',
    unit: 'piece',
    defaultCost: '4.20',
    defaultPrice: '6.50',
    isActive: true,
  })
  const customer = await Customer.create({
    name: 'Report Customer',
    phone: '9822222222',
    isActive: true,
  })

  await client
    .post(`${API}/sales`)
    .loginAs(user)
    .json({
      type: 'instant',
      customer_id: customer.id,
      sale_date: '2026-10-10',
      items: [{ product_id: brick.id, quantity: 1000 }],
      payment: { amount: 1000, method: 'upi' },
    })

  const booking = await client
    .post(`${API}/sales`)
    .loginAs(user)
    .json({
      type: 'booking',
      customer_id: customer.id,
      sale_date: '2026-10-11',
      delivery_date: '2026-10-20',
      items: [{ product_id: brick.id, quantity: 2000 }],
      payment: { amount: 3000, method: 'cash' },
    })
  await client
    .post(`${API}/sales/${booking.body().data.id}/deliver`)
    .loginAs(user)
    .json({ delivered_date: '2026-10-20' })

  await client
    .post(`${API}/sales`)
    .loginAs(user)
    .json({
      type: 'booking',
      customer_id: customer.id,
      sale_date: '2026-10-12',
      delivery_date: '2099-01-01',
      items: [{ product_id: brick.id, quantity: 100 }],
    })

  const category = await ExpenseCategory.create({
    name: 'Report Cat',
    isActive: true,
    sortOrder: 1,
  })
  await client.post(`${API}/expenses`).loginAs(user).json({
    expense_category_id: category.id,
    expense_date: '2026-10-15',
    amount: 850,
  })

  const labour = await client.post(`${API}/labours`).loginAs(user).json({
    name: 'Report Labour',
    wage_type: 'daily',
    wage_amount: 500,
    joining_date: '2026-10-01',
  })
  for (const date of ['2026-10-01', '2026-10-02']) {
    await client
      .put(`${API}/attendance`)
      .loginAs(user)
      .json({ date, records: [{ labour_id: labour.body().data.id, status: 'present' }] })
  }

  return { user, customer }
}

test.group('Reports', (group) => {
  group.each.setup(() => testUtils.db().withGlobalTransaction())

  test('sales, dues, expenses, collections and net profit add up', async ({ client, assert }) => {
    const { user, customer } = await seedOctober(client)
    const range = 'from=2026-10-01&to=2026-10-31'

    const sales = (await client.get(`${API}/reports/sales?${range}`).loginAs(user)).body().data
    assert.containsSubset(sales, {
      count: 2,
      amount: '19500.00',
      cost: '12600.00',
      profit: '6900.00',
    })
    assert.containsSubset(sales.by_product[0], {
      quantity: '3000.00',
      amount: '19500.00',
      profit: '6900.00',
    })
    assert.deepEqual(
      sales.daily.map((d: any) => d.date),
      ['2026-10-10', '2026-10-20']
    )

    const dues = (await client.get(`${API}/reports/dues`).loginAs(user)).body().data
    const row = dues.items.find((d: any) => d.customer_id === customer.id)
    assert.containsSubset(row, {
      total_due: '15500.00',
      oldest_due_date: '2026-10-10',
      sales_count: 2,
    })

    const expenses = (await client.get(`${API}/reports/expenses?${range}`).loginAs(user)).body()
      .data
    assert.equal(expenses.total, '850.00')
    assert.equal(expenses.by_category[0].percent, 100)

    const collections = (
      await client.get(`${API}/reports/collections?${range}`).loginAs(user)
    ).body().data
    assert.equal(collections.total, '4000.00')
    assert.sameDeepMembers(collections.by_method, [
      { method: 'cash', amount: '3000.00' },
      { method: 'upi', amount: '1000.00' },
    ])

    const net = (
      await client.get(`${API}/reports/net-profit?from=2026-09-01&to=2026-10-31`).loginAs(user)
    ).body().data
    // 6900 − 850 − 1000
    assert.containsSubset(net, {
      sales_profit: '6900.00',
      expenses: '850.00',
      wages: '1000.00',
      net_profit: '5050.00',
    })
    assert.deepEqual(
      net.monthly.map((m: any) => [m.month, m.net_profit]),
      [
        ['2026-09', '0.00'],
        ['2026-10', '5050.00'],
      ]
    )

    const wages = (await client.get(`${API}/reports/wages?month=2026-10`).loginAs(user)).body().data
    assert.equal(wages.earned, '1000.00')
  })

  test('dashboard returns every card', async ({ client, assert }) => {
    const user = await createUser()
    const response = await client.get(`${API}/dashboard`).loginAs(user)
    response.assertStatus(200)
    assert.properties(response.body().data, [
      'today_sales',
      'today_profit',
      'total_due',
      'deliveries_today',
      'overdue_deliveries',
      'present_today',
      'labours_total',
      'month_expenses',
      'recent_sales',
    ])
  })

  test('from after to is rejected', async ({ client }) => {
    const user = await createUser()
    const response = await client
      .get(`${API}/reports/sales?from=2026-10-31&to=2026-10-01`)
      .loginAs(user)
    response.assertStatus(422)
  })
})
