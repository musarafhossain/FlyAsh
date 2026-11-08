import { test } from '@japa/runner'
import testUtils from '@adonisjs/core/services/test_utils'
import Product from '#models/product'
import Customer from '#models/customer'
import { API, createUser } from '#tests/helpers'
import { today } from '#helpers/dates'

async function setup() {
  const user = await createUser()
  const brick = await Product.create({
    name: `Brick ${Math.random()}`,
    unit: 'piece',
    defaultCost: '4.20',
    defaultPrice: '6.50',
    isActive: true,
  })
  const block = await Product.create({
    name: `Block ${Math.random()}`,
    unit: 'piece',
    defaultCost: '30.00',
    defaultPrice: '45.00',
    isActive: true,
  })
  const customer = await Customer.create({
    name: 'Rahim Traders',
    phone: `97${String(Date.now()).slice(-8)}`,
    isActive: true,
  })
  return { user, brick, block, customer }
}

test.group('Sales: calculations', (group) => {
  group.each.setup(() => testUtils.db().withGlobalTransaction())

  test('instant sale: totals, profit, due, status and snapshots', async ({ client, assert }) => {
    const { user, brick, block, customer } = await setup()

    const response = await client
      .post(`${API}/sales`)
      .loginAs(user)
      .json({
        type: 'instant',
        customer_id: customer.id,
        items: [
          { product_id: brick.id, quantity: 5000 },
          { product_id: block.id, quantity: 100, unit_price: '50.00' },
        ],
        transport_charge: 1500,
        discount: 500,
        payment: { amount: 10000, method: 'upi' },
      })

    response.assertStatus(201)
    const sale = response.body().data
    // brick: 5000 × 6.50 = 32500 (cost 21000) · block: 100 × 50 = 5000 (cost 3000)
    assert.containsSubset(sale, {
      type: 'instant',
      status: 'delivered',
      delivered_date: today(),
      subtotal: '37500.00',
      transport_charge: '1500.00',
      discount: '500.00',
      total: '38500.00',
      total_cost: '24000.00',
      profit: '14500.00',
      paid_amount: '10000.00',
      due_amount: '28500.00',
      payment_status: 'partial',
    })
    assert.match(sale.invoice_no, /^INV-\d{6}$/)
    assert.lengthOf(sale.items, 2)
    assert.containsSubset(sale.items[0], {
      product_name: brick.name,
      unit_cost: '4.20',
      line_total: '32500.00',
    })
    assert.equal(sale.payments[0].created_by.id, user.id)
    assert.equal(sale.created_by.name, user.name)

    // Product price changes do not affect the old sale
    brick.defaultPrice = '9.00'
    await brick.save()
    const again = await client.get(`${API}/sales/${sale.id}`).loginAs(user)
    assert.equal(again.body().data.total, '38500.00')

    // Customer due
    const cust = await client.get(`${API}/customers/${customer.id}`).loginAs(user)
    assert.containsSubset(cust.body().data, { total_sales: '38500.00', total_due: '28500.00' })
  })

  test('payments: no overpayment, paying the rest makes it paid', async ({ client, assert }) => {
    const { user, brick, customer } = await setup()
    const created = await client
      .post(`${API}/sales`)
      .loginAs(user)
      .json({
        type: 'instant',
        customer_id: customer.id,
        items: [{ product_id: brick.id, quantity: 1000 }],
      })
    const sale = created.body().data
    assert.equal(sale.payment_status, 'due')

    const tooMuch = await client
      .post(`${API}/sales/${sale.id}/payments`)
      .loginAs(user)
      .json({ amount: 7000 })
    tooMuch.assertStatus(400)

    const rest = await client
      .post(`${API}/sales/${sale.id}/payments`)
      .loginAs(user)
      .json({ amount: 6500 })
    rest.assertStatus(200)
    assert.containsSubset(rest.body().data, {
      paid_amount: '6500.00',
      due_amount: '0.00',
      payment_status: 'paid',
    })

    const paymentId = rest.body().data.payments[0].id
    const removed = await client
      .delete(`${API}/sales/${sale.id}/payments/${paymentId}`)
      .loginAs(user)
    assert.equal(removed.body().data.payment_status, 'due')
  })

  test('edit is rejected when the new total is less than paid', async ({ client }) => {
    const { user, brick, customer } = await setup()
    const created = await client
      .post(`${API}/sales`)
      .loginAs(user)
      .json({
        type: 'instant',
        customer_id: customer.id,
        items: [{ product_id: brick.id, quantity: 1000 }],
        payment: { amount: 6000 },
      })
    const id = created.body().data.id

    const edit = await client
      .put(`${API}/sales/${id}`)
      .loginAs(user)
      .json({
        customer_id: customer.id,
        items: [{ product_id: brick.id, quantity: 100 }],
      })
    edit.assertStatus(400)
  })

  test('discount larger than subtotal + transport is rejected', async ({ client }) => {
    const { user, brick, customer } = await setup()
    const response = await client
      .post(`${API}/sales`)
      .loginAs(user)
      .json({
        type: 'instant',
        customer_id: customer.id,
        items: [{ product_id: brick.id, quantity: 10 }],
        discount: 1000,
      })
    response.assertStatus(400)
  })
})

test.group('Sales: bookings', (group) => {
  group.each.setup(() => testUtils.db().withGlobalTransaction())

  test('booking needs a delivery date', async ({ client }) => {
    const { user, brick, customer } = await setup()
    const response = await client
      .post(`${API}/sales`)
      .loginAs(user)
      .json({
        type: 'booking',
        customer_id: customer.id,
        items: [{ product_id: brick.id, quantity: 10 }],
      })
    response.assertStatus(422)
  })

  test('booked → upcoming, not in dues; delivered → counts in dues', async ({ client, assert }) => {
    const { user, brick, customer } = await setup()
    const created = await client
      .post(`${API}/sales`)
      .loginAs(user)
      .json({
        type: 'booking',
        customer_id: customer.id,
        delivery_date: '2099-01-01',
        items: [{ product_id: brick.id, quantity: 1000 }],
        payment: { amount: 2000, note: 'Advance' },
      })
    created.assertStatus(201)
    const sale = created.body().data
    assert.containsSubset(sale, { status: 'booked', delivered_date: null, due_amount: '4500.00' })

    const upcoming = await client.get(`${API}/sales/upcoming-deliveries`).loginAs(user)
    const row = upcoming.body().data.items.find((s: any) => s.id === sale.id)
    assert.isFalse(row.is_overdue)

    let cust = await client.get(`${API}/customers/${customer.id}`).loginAs(user)
    assert.equal(cust.body().data.total_due, '0.00')

    const cancel = await client.post(`${API}/sales/${sale.id}/cancel`).loginAs(user)
    cancel.assertStatus(400) // has payments

    const deliver = await client.post(`${API}/sales/${sale.id}/deliver`).loginAs(user).json({})
    assert.containsSubset(deliver.body().data, { status: 'delivered', delivered_date: today() })

    cust = await client.get(`${API}/customers/${customer.id}`).loginAs(user)
    assert.equal(cust.body().data.total_due, '4500.00')
  })

  test('a booking without payments can be cancelled', async ({ client }) => {
    const { user, brick, customer } = await setup()
    const created = await client
      .post(`${API}/sales`)
      .loginAs(user)
      .json({
        type: 'booking',
        customer_id: customer.id,
        delivery_date: today(),
        items: [{ product_id: brick.id, quantity: 10 }],
      })
    const cancel = await client.post(`${API}/sales/${created.body().data.id}/cancel`).loginAs(user)
    cancel.assertStatus(200)
    cancel.assertBodyContains({ data: { status: 'cancelled' } })
  })
})

test.group('Sales: customers, list and delete', (group) => {
  group.each.setup(() => testUtils.db().withGlobalTransaction())

  test('inline new customer; duplicate phone returns the existing id', async ({
    client,
    assert,
  }) => {
    const { user, brick, customer } = await setup()

    const ok = await client
      .post(`${API}/sales`)
      .loginAs(user)
      .json({
        type: 'instant',
        new_customer: { name: 'New Buyer', phone: '9811111111', address: 'Habra' },
        items: [{ product_id: brick.id, quantity: 10 }],
      })
    ok.assertStatus(201)
    assert.equal(ok.body().data.customer.name, 'New Buyer')

    const dup = await client
      .post(`${API}/sales`)
      .loginAs(user)
      .json({
        type: 'instant',
        new_customer: { name: 'Someone', phone: customer.phone },
        items: [{ product_id: brick.id, quantity: 10 }],
      })
    dup.assertStatus(422)
    assert.equal(dup.body().data.existing_customer_id, customer.id)
  })

  test('list filters and soft delete', async ({ client, assert }) => {
    const { user, brick, customer } = await setup()
    const created = await client
      .post(`${API}/sales`)
      .loginAs(user)
      .json({
        type: 'instant',
        customer_id: customer.id,
        items: [{ product_id: brick.id, quantity: 100 }],
        payment: { amount: 100 },
      })
    const id = created.body().data.id

    const partial = await client.get(`${API}/sales?status=partial&search=Rahim`).loginAs(user)
    assert.include(
      partial.body().data.items.map((s: any) => s.id),
      id
    )
    assert.equal(partial.body().data.items[0].customer.name, 'Rahim Traders')

    await client.delete(`${API}/sales/${id}`).loginAs(user)
    const list = await client.get(`${API}/sales`).loginAs(user)
    assert.notInclude(
      list.body().data.items.map((s: any) => s.id),
      id
    )
    const show = await client.get(`${API}/sales/${id}`).loginAs(user)
    show.assertStatus(404)
  })
})
