import { BaseCommand, flags } from '@adonisjs/core/ace'
import type { CommandOptions } from '@adonisjs/core/types/ace'

/**
 * Fills a TEST database with realistic fake data for the last N months
 * (products, customers, sales with payments / bookings / tax, labours with
 * daily attendance and monthly wage payments, expenses). Sales go through
 * SaleService, so totals, dues and invoice numbers are exactly as in real use.
 *
 *   DB_DATABASE=flyash_test node ace demo:seed --months=6
 *
 * Refuses to run unless the database name contains "test" (it is meant to
 * run on an emptied copy, never on the live database).
 */
export default class DemoSeed extends BaseCommand {
  static commandName = 'demo:seed'
  static description = 'Fill a test database with fake data for the last N months'
  static options: CommandOptions = { startApp: true }

  @flags.number({ description: 'How many months back (default 6)' })
  declare months?: number

  /** Deterministic random numbers: every run gives the same data */
  private seed = 20261116
  private random() {
    this.seed = (this.seed * 16807) % 2147483647
    return (this.seed - 1) / 2147483646
  }
  private pick<T>(items: readonly T[]): T {
    return items[Math.floor(this.random() * items.length)]
  }
  private int(min: number, max: number) {
    return Math.floor(this.random() * (max - min + 1)) + min
  }
  private chance(p: number) {
    return this.random() < p
  }

  async run() {
    const { default: env } = await import('#start/env')
    const database = String(env.get('DB_DATABASE'))
    if (!database.includes('test')) {
      return this.fail(`Refusing to seed "${database}": the database name must contain "test"`)
    }

    const { DateTime } = await import('luxon')
    const { default: db } = await import('@adonisjs/lucid/services/db')
    const { default: User } = await import('#models/user')
    const { default: Product } = await import('#models/product')
    const { default: Customer } = await import('#models/customer')
    const { default: Labour } = await import('#models/labour')
    const { default: Attendance } = await import('#models/attendance')
    const { default: WagePayment } = await import('#models/wage_payment')
    const { default: Expense } = await import('#models/expense')
    const { default: Sale } = await import('#models/sale')
    const { default: SaleService } = await import('#services/sale_service')
    const { default: WageService } = await import('#services/wage_service')
    const { today } = await import('#helpers/dates')

    if (await Product.first()) {
      return this.fail('Products already exist: run this on an emptied database')
    }

    const months = this.months ?? 6
    const end = DateTime.fromISO(today())
    const start = end.minus({ months }).startOf('day')
    const iso = (d: ReturnType<typeof DateTime.fromISO>) => d.toISODate()!
    const users = await User.query().select('id')
    const userIds = users.map((u) => u.id)
    const by = () => (userIds.length ? this.pick(userIds) : null)

    this.logger.info(`Seeding "${database}" from ${iso(start)} to ${iso(end)}`)

    // Products
    const products = await Product.createMany([
      { name: 'Fly Ash Brick 9×4×3', defaultPrice: '6.50', isActive: true, createdBy: by() },
      { name: 'Fly Ash Brick 9×4×2.5', defaultPrice: '5.80', isActive: true, createdBy: by() },
      { name: 'Hollow Block 16×8×8', defaultPrice: '42.00', isActive: true, createdBy: by() },
      { name: 'Solid Block 12×8×6', defaultPrice: '34.00', isActive: true, createdBy: by() },
      { name: 'Paver Block', defaultPrice: '14.00', isActive: true, createdBy: by() },
      { name: 'Old Red Brick', defaultPrice: '5.00', isActive: false, createdBy: by() },
    ])
    const sellable = products.filter((p) => p.isActive)

    // Customers (a few without a phone)
    const first = [
      'Rahim',
      'Karim',
      'Sujit',
      'Amit',
      'Bikash',
      'Tapas',
      'Rafiq',
      'Subrata',
      'Anil',
      'Monirul',
      'Sahidul',
      'Prasenjit',
      'Gautam',
      'Imran',
      'Dipak',
      'Nazrul',
    ]
    const last = ['Sheikh', 'Mondal', 'Das', 'Ghosh', 'Biswas', 'Sarkar', 'Ali', 'Roy', 'Paul']
    const places = [
      'Barasat',
      'Habra',
      'Bongaon',
      'Madhyamgram',
      'Basirhat',
      'Ashoknagar',
      'Gobardanga',
      'Duttapukur',
    ]
    const customers = []
    for (let i = 0; i < 60; i++) {
      customers.push(
        await Customer.create({
          name: `${this.pick(first)} ${this.pick(last)}${i % 5 === 0 ? ' Traders' : i % 7 === 0 ? ' Constructions' : ''}`,
          phone: i % 9 === 4 ? null : `9${String(830000000 + i * 79193).padStart(9, '0')}`,
          address: `${this.pick(places)}, North 24 Parganas`,
          isActive: i % 23 !== 22,
          createdBy: by(),
        })
      )
    }
    const buyers = customers.filter((c) => c.isActive)
    // Regulars buy more often
    const regulars = buyers.slice(0, 15)

    // Sales: 1–3 a day (fewer on Sundays), ~₹10–15 lakh a month
    let saleCount = 0
    for (let d = start; d <= end; d = d.plus({ days: 1 })) {
      const perDay = d.weekday === 7 ? this.int(0, 1) : this.int(1, 3)
      for (let n = 0; n < perDay; n++) {
        const saleDate = iso(d)
        const isBooking = this.chance(0.25)
        const lines = Array.from({ length: this.int(1, 3) }, () => {
          const product = this.pick(sellable)
          const block = Number(product.defaultPrice) > 20
          return {
            product_id: product.id,
            quantity: block ? this.int(5, 30) * 10 : this.int(1, 6) * 1000,
            unit_price: this.chance(0.2)
              ? Number(product.defaultPrice) + this.pick([-0.3, -0.2, 0.2, 0.5])
              : undefined,
          }
        })
        const items = lines.filter(
          (item, index) => lines.findIndex((x) => x.product_id === item.product_id) === index
        )
        const deliveryDate = isBooking ? d.plus({ days: this.int(2, 12) }) : null

        const id = await SaleService.create(
          {
            type: isBooking ? 'booking' : 'instant',
            customer_id: this.pick(this.chance(0.6) ? regulars : buyers).id,
            sale_date: saleDate,
            delivery_date: deliveryDate ? iso(deliveryDate) : undefined,
            delivery_address: isBooking && this.chance(0.5) ? `Site at ${this.pick(places)}` : null,
            items,
            transport_charge: this.chance(0.55) ? this.pick([500, 800, 1000, 1200, 1500, 2000]) : 0,
            discount: this.chance(0.15) ? this.pick([100, 200, 300, 500]) : 0,
            tax_percent: this.chance(0.2) ? this.pick([5, 12, 18]) : 0,
            notes: this.chance(0.1)
              ? this.pick(['Deliver before noon', 'Call before coming', 'Unload at the back gate'])
              : null,
          },
          by()
        )
        saleCount++

        const sale = await Sale.findOrFail(id)
        const total = Number(sale.total)
        // Payments: full now, part now (+ maybe the rest later), or nothing yet
        const roll = this.random()
        const payDate = (offset: number) => {
          const p = d.plus({ days: offset })
          return iso(p > end ? end : p)
        }
        const method = () => this.pick(['cash', 'cash', 'cash', 'upi', 'upi', 'bank'] as const)
        if (roll < 0.65) {
          await SaleService.addPayment(
            sale,
            { amount: total, payment_date: saleDate, method: method() },
            by()
          )
        } else if (roll < 0.9) {
          const part = Math.round(total * this.pick([0.3, 0.4, 0.5, 0.6]))
          await SaleService.addPayment(
            sale,
            { amount: part, payment_date: saleDate, method: method() },
            by()
          )
          if (this.chance(0.75) && d.plus({ days: 7 }) <= end) {
            await sale.refresh()
            const rest = Number(sale.dueAmount)
            if (rest > 0) {
              await SaleService.addPayment(
                sale,
                {
                  amount: this.chance(0.7) ? rest : Math.round(rest / 2),
                  payment_date: payDate(this.int(7, 30)),
                  method: method(),
                },
                by()
              )
            }
          }
        }

        // Bookings: most past ones delivered; a few cancelled (only without payments)
        await sale.refresh()
        if (isBooking && deliveryDate && deliveryDate <= end) {
          if (Number(sale.paidAmount) === 0 && this.chance(0.08)) {
            await SaleService.cancel(sale)
          } else if (this.chance(0.9)) {
            await SaleService.deliver(sale, iso(deliveryDate))
          }
        }
      }
    }

    // Labours: 2 monthly, the rest daily; one left last month
    const names = [
      'Kartik Mondal',
      'Sujit Das',
      'Bablu Sheikh',
      'Rajesh Roy',
      'Habib Ali',
      'Gopal Ghosh',
      'Samir Biswas',
      'Nitai Sarkar',
      'Abdul Karim',
      'Pintu Das',
      'Ratan Mondal',
      'Asit Roy',
      'Mofizul Islam',
      'Tarun Paul',
      'Jahangir Sheikh',
      'Bapi Ghosh',
    ]
    const leftOn = iso(end.minus({ days: 40 }))
    const labours = []
    for (const [index, name] of names.entries()) {
      const monthly = index < 2
      const joinedLate = index >= 14 // two joined two months ago
      labours.push(
        await Labour.create({
          name,
          phone: index % 6 === 5 ? null : `7${String(600000000 + index * 104729).padStart(9, '0')}`,
          address: `${this.pick(places)}`,
          wageType: monthly ? 'monthly' : 'daily',
          wageAmount: monthly
            ? this.pick(['14000.00', '16000.00'])
            : this.pick(['450.00', '500.00', '550.00', '600.00']),
          joiningDate: iso(
            joinedLate ? end.minus({ months: 2 }).startOf('month') : start.minus({ days: 20 })
          ),
          isActive: index !== 9,
          leftDate: index === 9 ? leftOn : null,
          createdBy: by(),
        })
      )
    }

    // Attendance: every day up to yesterday, ~88 % present, Sundays mostly off
    let attendanceCount = 0
    for (let d = start; d < end; d = d.plus({ days: 1 })) {
      const date = iso(d)
      const rows = []
      for (const labour of labours) {
        if (labour.joiningDate > date) continue
        if (labour.leftDate && labour.leftDate < date) continue
        const p = d.weekday === 7 ? 0.15 : 0.88
        if (!this.chance(p)) continue
        rows.push({
          labourId: labour.id,
          date,
          wageType: labour.wageType,
          wageAmount: labour.wageAmount,
          createdBy: by(),
        })
      }
      if (rows.length) {
        await Attendance.createMany(rows)
        attendanceCount += rows.length
      }
    }

    // Wage payments: past months mostly paid in the first week of the next
    // month (some partly); this month a few early payments.
    let wageCount = 0
    for (let m = start.startOf('month'); m <= end; m = m.plus({ months: 1 })) {
      const month = m.toFormat('yyyy-MM')
      const current = month === end.toFormat('yyyy-MM')
      const rows = await WageService.sheet(month)
      for (const row of rows) {
        const earned = Number(row.earned)
        if (earned <= 0) continue
        if (current) {
          if (!this.chance(0.35)) continue
          const amount = Math.round(earned * this.pick([0.2, 0.3, 0.5]))
          if (amount <= 0) continue
          await WagePayment.create({
            labourId: row.labour_id,
            wageMonth: `${month}-01`, // stored as the month's first day
            amount: amount.toFixed(2),
            paymentDate: iso(end.minus({ days: this.int(0, Math.max(0, end.day - 1)) })),
            method: this.pick(['cash', 'cash', 'upi']),
            note: 'Advance for the month',
            createdBy: by(),
          })
          wageCount++
          continue
        }
        const share = this.chance(0.8) ? 1 : this.pick([0.5, 0.7, 0.9])
        const payOn = m.plus({ months: 1 }).set({ day: this.int(1, 7) })
        await WagePayment.create({
          labourId: row.labour_id,
          wageMonth: `${month}-01`, // stored as the month's first day
          amount: (Math.round(earned * share * 100) / 100).toFixed(2),
          paymentDate: iso(payOn > end ? end : payOn),
          method: this.pick(['cash', 'cash', 'upi', 'bank']),
          note: share < 1 ? 'Part payment' : null,
          createdBy: by(),
        })
        wageCount++
      }
    }

    // Expenses: daily small ones and monthly big ones
    const small: Record<string, [number, number, string[]]> = {
      'Labour Tiffin': [150, 600, ['Tiffin for labours', 'Tea and snacks']],
      'Diesel': [1500, 6000, ['Diesel for generator', 'Diesel for tractor', 'Diesel for JCB']],
      'Transport': [800, 4000, ['Truck hire for delivery', 'Fly ash transport']],
      'Machine Repair': [500, 7000, ['Mixer belt changed', 'Press machine repair', 'Welding work']],
      'Others': [100, 1500, ['Office supplies', 'Miscellaneous', 'Phone recharge']],
    }
    const big: Record<string, [number, number, string[]]> = {
      'Fly Ash': [40000, 90000, ['Fly ash from power plant']],
      'Cement': [25000, 60000, ['Cement bags']],
      'Stone Dust': [15000, 35000, ['Stone dust truck']],
      'Electricity Bill': [12000, 25000, ['Monthly electricity bill']],
    }
    let expenseCount = 0
    const addExpense = async (
      category: string,
      [min, max, notes]: [number, number, string[]],
      date: string
    ) => {
      await Expense.create({
        category,
        expenseDate: date,
        amount: (Math.round(this.int(min, max) / 50) * 50).toFixed(2),
        note: this.pick(notes),
        createdBy: by(),
      })
      expenseCount++
    }
    for (let d = start; d <= end; d = d.plus({ days: 1 })) {
      for (let n = this.int(0, 2); n > 0; n--) {
        const category = this.pick(Object.keys(small))
        await addExpense(category, small[category], iso(d))
      }
    }
    for (let m = start.startOf('month'); m <= end; m = m.plus({ months: 1 })) {
      for (const [category, spec] of Object.entries(big)) {
        const times = category === 'Electricity Bill' ? 1 : this.int(2, 3)
        for (let t = 0; t < times; t++) {
          const day = m.set({ day: this.int(1, m.daysInMonth!) })
          if (day < start || day > end) continue
          await addExpense(category, spec, iso(day))
        }
      }
    }

    const due = await db.from('sales').whereNull('deleted_at').sum('due_amount as due').first()
    this.logger.success(
      `Created ${products.length} products, ${customers.length} customers, ${saleCount} sales, ` +
        `${labours.length} labours, ${attendanceCount} attendance rows, ${wageCount} wage payments, ` +
        `${expenseCount} expenses (open dues ₹${Number(due?.due ?? 0).toFixed(2)})`
    )
  }

  private fail(message: string) {
    this.logger.error(message)
    this.exitCode = 1
  }
}
