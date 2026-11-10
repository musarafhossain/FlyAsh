import { BaseSeeder } from '@adonisjs/lucid/seeders'
import { DateTime } from 'luxon'
import User from '#models/user'
import Product from '#models/product'
import Customer from '#models/customer'
import Labour from '#models/labour'
import Attendance from '#models/attendance'
import LabourAdvance from '#models/labour_advance'
import Expense from '#models/expense'
import ExpenseCategory from '#models/expense_category'
import Sale from '#models/sale'
import SaleService from '#services/sale_service'
import { now, today } from '#helpers/dates'

/**
 * Sample data for building the app (development only).
 * Runs once: skipped when products already exist.
 */
export default class extends BaseSeeder {
  static environment = ['development']

  /** Small deterministic random generator so every run gives the same data */
  private seed = 42
  private random() {
    this.seed = (this.seed * 16807) % 2147483647
    return (this.seed - 1) / 2147483646
  }
  private pick<T>(items: T[]): T {
    return items[Math.floor(this.random() * items.length)]
  }
  private int(min: number, max: number) {
    return Math.floor(this.random() * (max - min + 1)) + min
  }

  async run() {
    if (await Product.first()) {
      console.log('Sample data already exists, skipping')
      return
    }

    const firstUser = await User.query().orderBy('id').first()
    const userId = firstUser?.id ?? null
    const days = (n: number) => now().minus({ days: n }).toISODate()!

    // Products
    const products = await Product.createMany([
      {
        name: 'Fly Ash Brick 9×4×3',
        unit: 'piece',
        defaultCost: '4.20',
        defaultPrice: '6.50',
        isActive: true,
        createdBy: userId,
      },
      {
        name: 'Fly Ash Brick 9×4×2.5',
        unit: 'piece',
        defaultCost: '3.80',
        defaultPrice: '5.80',
        isActive: true,
        createdBy: userId,
      },
      {
        name: 'Hollow Block 16×8×8',
        unit: 'piece',
        defaultCost: '28.00',
        defaultPrice: '42.00',
        isActive: true,
        createdBy: userId,
      },
      {
        name: 'Solid Block 12×8×6',
        unit: 'piece',
        defaultCost: '22.00',
        defaultPrice: '34.00',
        isActive: true,
        createdBy: userId,
      },
      {
        name: 'Paver Block',
        unit: 'piece',
        defaultCost: '9.00',
        defaultPrice: '14.00',
        isActive: false,
        createdBy: userId,
      },
    ])
    const sellable = products.filter((p) => p.isActive)

    // Customers
    const firstNames = [
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
    ]
    const lastNames = ['Sheikh', 'Mondal', 'Das', 'Ghosh', 'Biswas', 'Sarkar', 'Ali', 'Roy']
    const places = ['Barasat', 'Habra', 'Bongaon', 'Madhyamgram', 'Basirhat', 'Ashoknagar']
    const customers: Customer[] = []
    for (let i = 0; i < 30; i++) {
      customers.push(
        await Customer.create({
          name: `${this.pick(firstNames)} ${this.pick(lastNames)}${i % 4 === 0 ? ' Traders' : ''}`,
          phone: `98${String(30000000 + i * 7919).padStart(8, '0')}`,
          address: `${this.pick(places)}, North 24 Parganas`,
          isActive: true,
          createdBy: userId,
        })
      )
    }

    // Sales over the last 60 days
    for (let i = 0; i < 80; i++) {
      const saleDate = days(this.int(0, 60))
      const isBooking = this.random() < 0.25
      const items = Array.from({ length: this.int(1, 2) }, () => {
        const product = this.pick(sellable)
        return {
          product_id: product.id,
          quantity: Number(product.defaultPrice) > 20 ? this.int(50, 500) : this.int(1, 10) * 1000,
        }
      })
      const uniqueItems = items.filter(
        (item, index) => items.findIndex((x) => x.product_id === item.product_id) === index
      )

      const id = await SaleService.create(
        {
          type: isBooking ? 'booking' : 'instant',
          customer_id: this.pick(customers).id,
          sale_date: saleDate,
          delivery_date: isBooking
            ? DateTime.fromISO(saleDate)
                .plus({ days: this.int(2, 10) })
                .toISODate()!
            : undefined,
          items: uniqueItems,
          transport_charge: this.random() < 0.5 ? this.pick([500, 800, 1200, 1500]) : 0,
          discount: this.random() < 0.2 ? this.pick([100, 200, 500]) : 0,
        },
        userId
      )

      const sale = await Sale.findOrFail(id)
      const roll = this.random()
      const amount =
        roll < 0.5 ? Number(sale.total) : roll < 0.8 ? Math.floor(Number(sale.total) * 0.4) : 0
      if (amount > 0) {
        await SaleService.addPayment(
          sale,
          { amount, payment_date: saleDate, method: this.pick(['cash', 'cash', 'upi', 'bank']) },
          userId
        )
      }

      // Most past bookings have been delivered
      await sale.refresh()
      if (isBooking && sale.deliveryDate! <= today() && this.random() < 0.8) {
        await SaleService.deliver(sale, sale.deliveryDate!)
      }
    }

    // Labours with ~2 months of attendance
    const labourNames = [
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
    ]
    const labours: Labour[] = []
    for (const [index, name] of labourNames.entries()) {
      const monthly = index < 2
      labours.push(
        await Labour.create({
          name,
          phone: `91${String(20000000 + index * 104729).padStart(8, '0')}`,
          wageType: monthly ? 'monthly' : 'daily',
          wageAmount: monthly ? '15000.00' : this.pick(['450.00', '500.00', '550.00']),
          joiningDate: days(75),
          isActive: true,
          createdBy: userId,
        })
      )
    }
    for (let d = 60; d >= 1; d--) {
      const date = days(d)
      for (const labour of labours) {
        if (this.random() >= 0.88) continue // absent: no row
        await Attendance.create({
          labourId: labour.id,
          date,
          wageType: labour.wageType,
          wageAmount: labour.wageAmount,
          createdBy: userId,
        })
      }
    }
    for (let i = 0; i < 10; i++) {
      await LabourAdvance.create({
        labourId: this.pick(labours).id,
        amount: this.pick(['500.00', '1000.00', '2000.00']),
        advanceDate: days(this.int(1, 45)),
        note: 'Advance',
        createdBy: userId,
      })
    }

    // Expenses
    const categories = await ExpenseCategory.query().where('is_active', true)
    const notes: Record<string, string[]> = {
      'Labour Tiffin': ['Tiffin for labours', 'Tea and snacks'],
      'Machine Repair': ['Mixer belt changed', 'Press machine repair', 'Welding work'],
      'Diesel / Fuel': ['Diesel for generator', 'Diesel for tractor'],
      'Electricity Bill': ['Monthly electricity bill'],
      'Transport': ['Truck hire for delivery', 'Fly ash transport'],
      'Others': ['Office supplies', 'Miscellaneous'],
    }
    for (let i = 0; i < 50; i++) {
      const category = this.pick(categories)
      await Expense.create({
        expenseCategoryId: category.id,
        expenseDate: days(this.int(0, 60)),
        amount: String(this.int(2, 60) * 50) + '.00',
        note: this.pick(notes[category.name] ?? ['Expense']),
        createdBy: userId,
      })
    }

    console.log('Sample data created: 5 products, 30 customers, 80 sales, 12 labours, 50 expenses')
  }
}
