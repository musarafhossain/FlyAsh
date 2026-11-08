/*
|--------------------------------------------------------------------------
| Routes: all API routes live under /api/v1
|--------------------------------------------------------------------------
*/

import router from '@adonisjs/core/services/router'
import db from '@adonisjs/lucid/services/db'
import { middleware } from '#start/kernel'
import { forgotPasswordThrottle, otpThrottle } from '#start/limiter'
import { ok } from '#helpers/api_response'

const AuthController = () => import('#controllers/auth_controller')
const PasswordResetController = () => import('#controllers/password_reset_controller')
const UsersController = () => import('#controllers/users_controller')
const ProductsController = () => import('#controllers/products_controller')
const CustomersController = () => import('#controllers/customers_controller')
const SalesController = () => import('#controllers/sales_controller')
const LaboursController = () => import('#controllers/labours_controller')
const AttendanceController = () => import('#controllers/attendance_controller')
const WagesController = () => import('#controllers/wages_controller')

/** Every :id style param must be numeric. */
router.where('id', router.matchers.number())

router.get('/', ({ response }) => ok(response, { name: 'FlyAsh API' }))

router
  .group(() => {
    /*
    | Public
    */
    router.get('health', async ({ response }) => {
      await db.rawQuery('SELECT 1')
      return ok(response, { status: 'ok', db: 'ok', time: new Date().toISOString() }, 'Healthy')
    })

    router
      .group(() => {
        router.post('login', [AuthController, 'login'])
        router.post('forgot-password', [PasswordResetController, 'forgot']).use(forgotPasswordThrottle)
        router.post('verify-otp', [PasswordResetController, 'verify']).use(otpThrottle)
        router.post('reset-password', [PasswordResetController, 'reset']).use(otpThrottle)
      })
      .prefix('auth')

    /*
    | Authenticated
    */
    router
      .group(() => {
        // Auth & profile
        router.post('auth/logout', [AuthController, 'logout'])
        router.get('auth/me', [AuthController, 'me'])
        router.put('auth/me', [AuthController, 'updateMe'])
        router.put('auth/password', [AuthController, 'changePassword'])

        // Users (other users only)
        router.get('users', [UsersController, 'index'])
        router.post('users', [UsersController, 'store'])
        router.get('users/:id', [UsersController, 'show'])
        router.put('users/:id', [UsersController, 'update'])
        router.patch('users/:id/status', [UsersController, 'status'])
        router.put('users/:id/password', [UsersController, 'resetPassword'])

        // Products
        router.get('products', [ProductsController, 'index'])
        router.post('products', [ProductsController, 'store'])
        router.get('products/:id', [ProductsController, 'show'])
        router.put('products/:id', [ProductsController, 'update'])
        router.patch('products/:id/status', [ProductsController, 'status'])
        router.delete('products/:id', [ProductsController, 'destroy'])

        // Customers
        router.get('customers', [CustomersController, 'index'])
        router.post('customers', [CustomersController, 'store'])
        router.get('customers/:id', [CustomersController, 'show'])
        router.put('customers/:id', [CustomersController, 'update'])
        router.patch('customers/:id/status', [CustomersController, 'status'])
        router.delete('customers/:id', [CustomersController, 'destroy'])
        router.get('customers/:id/sales', [SalesController, 'byCustomer'])

        // Sales
        router.get('sales', [SalesController, 'index'])
        router.get('sales/upcoming-deliveries', [SalesController, 'upcoming'])
        router.post('sales', [SalesController, 'store'])
        router.get('sales/:id', [SalesController, 'show'])
        router.put('sales/:id', [SalesController, 'update'])
        router.delete('sales/:id', [SalesController, 'destroy'])
        router.post('sales/:id/deliver', [SalesController, 'deliver'])
        router.post('sales/:id/cancel', [SalesController, 'cancel'])
        router.post('sales/:id/payments', [SalesController, 'addPayment'])
        router
          .delete('sales/:id/payments/:paymentId', [SalesController, 'deletePayment'])
          .where('paymentId', router.matchers.number())

        // Labours
        router.get('labours', [LaboursController, 'index'])
        router.post('labours', [LaboursController, 'store'])
        router.get('labours/:id', [LaboursController, 'show'])
        router.put('labours/:id', [LaboursController, 'update'])
        router.patch('labours/:id/status', [LaboursController, 'status'])

        // Attendance
        router.get('attendance', [AttendanceController, 'show'])
        router.put('attendance', [AttendanceController, 'save'])
        router.get('labours/:id/attendance', [AttendanceController, 'labourMonth'])

        // Wages & advances
        router.get('wages', [WagesController, 'sheet'])
        router.get('labours/:id/wages', [WagesController, 'labour'])
        router.get('labours/:id/advances', [WagesController, 'advances'])
        router.post('labours/:id/advances', [WagesController, 'storeAdvance'])
        router.delete('advances/:id', [WagesController, 'destroyAdvance'])
        router.post('labours/:id/wage-payments', [WagesController, 'storePayment'])
        router.delete('wage-payments/:id', [WagesController, 'destroyPayment'])
      })
      .use(middleware.auth())
  })
  .prefix('/api/v1')
