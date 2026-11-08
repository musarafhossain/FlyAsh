/* eslint-disable prettier/prettier */
import type { AdonisEndpoint } from '@tuyau/core/types'
import type { Registry } from './schema.d.ts'
import type { ApiDefinition } from './tree.d.ts'

export type { Route, Path } from './schema.d.ts'

const placeholder: any = {}

const routes = {
  'uploads.show': {
    methods: ["GET","HEAD"],
    pattern: '/uploads/*',
    tokens: [[0,"uploads"],[2,"*"]],
    types: placeholder as Registry['uploads.show']['types'],
  },
  'settings.app_version': {
    methods: ["GET","HEAD"],
    pattern: '/api/v1/app/version',
    tokens: [[0,"api"],[0,"v1"],[0,"app"],[0,"version"]],
    types: placeholder as Registry['settings.app_version']['types'],
  },
  'auth.login': {
    methods: ["POST"],
    pattern: '/api/v1/auth/login',
    tokens: [[0,"api"],[0,"v1"],[0,"auth"],[0,"login"]],
    types: placeholder as Registry['auth.login']['types'],
  },
  'password_reset.forgot': {
    methods: ["POST"],
    pattern: '/api/v1/auth/forgot-password',
    tokens: [[0,"api"],[0,"v1"],[0,"auth"],[0,"forgot-password"]],
    types: placeholder as Registry['password_reset.forgot']['types'],
  },
  'password_reset.verify': {
    methods: ["POST"],
    pattern: '/api/v1/auth/verify-otp',
    tokens: [[0,"api"],[0,"v1"],[0,"auth"],[0,"verify-otp"]],
    types: placeholder as Registry['password_reset.verify']['types'],
  },
  'password_reset.reset': {
    methods: ["POST"],
    pattern: '/api/v1/auth/reset-password',
    tokens: [[0,"api"],[0,"v1"],[0,"auth"],[0,"reset-password"]],
    types: placeholder as Registry['password_reset.reset']['types'],
  },
  'auth.logout': {
    methods: ["POST"],
    pattern: '/api/v1/auth/logout',
    tokens: [[0,"api"],[0,"v1"],[0,"auth"],[0,"logout"]],
    types: placeholder as Registry['auth.logout']['types'],
  },
  'auth.me': {
    methods: ["GET","HEAD"],
    pattern: '/api/v1/auth/me',
    tokens: [[0,"api"],[0,"v1"],[0,"auth"],[0,"me"]],
    types: placeholder as Registry['auth.me']['types'],
  },
  'auth.update_me': {
    methods: ["PUT"],
    pattern: '/api/v1/auth/me',
    tokens: [[0,"api"],[0,"v1"],[0,"auth"],[0,"me"]],
    types: placeholder as Registry['auth.update_me']['types'],
  },
  'auth.change_password': {
    methods: ["PUT"],
    pattern: '/api/v1/auth/password',
    tokens: [[0,"api"],[0,"v1"],[0,"auth"],[0,"password"]],
    types: placeholder as Registry['auth.change_password']['types'],
  },
  'users.index': {
    methods: ["GET","HEAD"],
    pattern: '/api/v1/users',
    tokens: [[0,"api"],[0,"v1"],[0,"users"]],
    types: placeholder as Registry['users.index']['types'],
  },
  'users.store': {
    methods: ["POST"],
    pattern: '/api/v1/users',
    tokens: [[0,"api"],[0,"v1"],[0,"users"]],
    types: placeholder as Registry['users.store']['types'],
  },
  'users.show': {
    methods: ["GET","HEAD"],
    pattern: '/api/v1/users/:id',
    tokens: [[0,"api"],[0,"v1"],[0,"users"],[1,"id"]],
    types: placeholder as Registry['users.show']['types'],
  },
  'users.update': {
    methods: ["PUT"],
    pattern: '/api/v1/users/:id',
    tokens: [[0,"api"],[0,"v1"],[0,"users"],[1,"id"]],
    types: placeholder as Registry['users.update']['types'],
  },
  'users.status': {
    methods: ["PATCH"],
    pattern: '/api/v1/users/:id/status',
    tokens: [[0,"api"],[0,"v1"],[0,"users"],[1,"id"],[0,"status"]],
    types: placeholder as Registry['users.status']['types'],
  },
  'users.reset_password': {
    methods: ["PUT"],
    pattern: '/api/v1/users/:id/password',
    tokens: [[0,"api"],[0,"v1"],[0,"users"],[1,"id"],[0,"password"]],
    types: placeholder as Registry['users.reset_password']['types'],
  },
  'products.index': {
    methods: ["GET","HEAD"],
    pattern: '/api/v1/products',
    tokens: [[0,"api"],[0,"v1"],[0,"products"]],
    types: placeholder as Registry['products.index']['types'],
  },
  'products.store': {
    methods: ["POST"],
    pattern: '/api/v1/products',
    tokens: [[0,"api"],[0,"v1"],[0,"products"]],
    types: placeholder as Registry['products.store']['types'],
  },
  'products.show': {
    methods: ["GET","HEAD"],
    pattern: '/api/v1/products/:id',
    tokens: [[0,"api"],[0,"v1"],[0,"products"],[1,"id"]],
    types: placeholder as Registry['products.show']['types'],
  },
  'products.update': {
    methods: ["PUT"],
    pattern: '/api/v1/products/:id',
    tokens: [[0,"api"],[0,"v1"],[0,"products"],[1,"id"]],
    types: placeholder as Registry['products.update']['types'],
  },
  'products.status': {
    methods: ["PATCH"],
    pattern: '/api/v1/products/:id/status',
    tokens: [[0,"api"],[0,"v1"],[0,"products"],[1,"id"],[0,"status"]],
    types: placeholder as Registry['products.status']['types'],
  },
  'products.destroy': {
    methods: ["DELETE"],
    pattern: '/api/v1/products/:id',
    tokens: [[0,"api"],[0,"v1"],[0,"products"],[1,"id"]],
    types: placeholder as Registry['products.destroy']['types'],
  },
  'customers.index': {
    methods: ["GET","HEAD"],
    pattern: '/api/v1/customers',
    tokens: [[0,"api"],[0,"v1"],[0,"customers"]],
    types: placeholder as Registry['customers.index']['types'],
  },
  'customers.store': {
    methods: ["POST"],
    pattern: '/api/v1/customers',
    tokens: [[0,"api"],[0,"v1"],[0,"customers"]],
    types: placeholder as Registry['customers.store']['types'],
  },
  'customers.show': {
    methods: ["GET","HEAD"],
    pattern: '/api/v1/customers/:id',
    tokens: [[0,"api"],[0,"v1"],[0,"customers"],[1,"id"]],
    types: placeholder as Registry['customers.show']['types'],
  },
  'customers.update': {
    methods: ["PUT"],
    pattern: '/api/v1/customers/:id',
    tokens: [[0,"api"],[0,"v1"],[0,"customers"],[1,"id"]],
    types: placeholder as Registry['customers.update']['types'],
  },
  'customers.status': {
    methods: ["PATCH"],
    pattern: '/api/v1/customers/:id/status',
    tokens: [[0,"api"],[0,"v1"],[0,"customers"],[1,"id"],[0,"status"]],
    types: placeholder as Registry['customers.status']['types'],
  },
  'customers.destroy': {
    methods: ["DELETE"],
    pattern: '/api/v1/customers/:id',
    tokens: [[0,"api"],[0,"v1"],[0,"customers"],[1,"id"]],
    types: placeholder as Registry['customers.destroy']['types'],
  },
  'sales.by_customer': {
    methods: ["GET","HEAD"],
    pattern: '/api/v1/customers/:id/sales',
    tokens: [[0,"api"],[0,"v1"],[0,"customers"],[1,"id"],[0,"sales"]],
    types: placeholder as Registry['sales.by_customer']['types'],
  },
  'sales.index': {
    methods: ["GET","HEAD"],
    pattern: '/api/v1/sales',
    tokens: [[0,"api"],[0,"v1"],[0,"sales"]],
    types: placeholder as Registry['sales.index']['types'],
  },
  'sales.upcoming': {
    methods: ["GET","HEAD"],
    pattern: '/api/v1/sales/upcoming-deliveries',
    tokens: [[0,"api"],[0,"v1"],[0,"sales"],[0,"upcoming-deliveries"]],
    types: placeholder as Registry['sales.upcoming']['types'],
  },
  'sales.store': {
    methods: ["POST"],
    pattern: '/api/v1/sales',
    tokens: [[0,"api"],[0,"v1"],[0,"sales"]],
    types: placeholder as Registry['sales.store']['types'],
  },
  'sales.show': {
    methods: ["GET","HEAD"],
    pattern: '/api/v1/sales/:id',
    tokens: [[0,"api"],[0,"v1"],[0,"sales"],[1,"id"]],
    types: placeholder as Registry['sales.show']['types'],
  },
  'sales.update': {
    methods: ["PUT"],
    pattern: '/api/v1/sales/:id',
    tokens: [[0,"api"],[0,"v1"],[0,"sales"],[1,"id"]],
    types: placeholder as Registry['sales.update']['types'],
  },
  'sales.destroy': {
    methods: ["DELETE"],
    pattern: '/api/v1/sales/:id',
    tokens: [[0,"api"],[0,"v1"],[0,"sales"],[1,"id"]],
    types: placeholder as Registry['sales.destroy']['types'],
  },
  'sales.deliver': {
    methods: ["POST"],
    pattern: '/api/v1/sales/:id/deliver',
    tokens: [[0,"api"],[0,"v1"],[0,"sales"],[1,"id"],[0,"deliver"]],
    types: placeholder as Registry['sales.deliver']['types'],
  },
  'sales.cancel': {
    methods: ["POST"],
    pattern: '/api/v1/sales/:id/cancel',
    tokens: [[0,"api"],[0,"v1"],[0,"sales"],[1,"id"],[0,"cancel"]],
    types: placeholder as Registry['sales.cancel']['types'],
  },
  'sales.add_payment': {
    methods: ["POST"],
    pattern: '/api/v1/sales/:id/payments',
    tokens: [[0,"api"],[0,"v1"],[0,"sales"],[1,"id"],[0,"payments"]],
    types: placeholder as Registry['sales.add_payment']['types'],
  },
  'sales.delete_payment': {
    methods: ["DELETE"],
    pattern: '/api/v1/sales/:id/payments/:paymentId',
    tokens: [[0,"api"],[0,"v1"],[0,"sales"],[1,"id"],[0,"payments"],[1,"paymentId"]],
    types: placeholder as Registry['sales.delete_payment']['types'],
  },
  'labours.index': {
    methods: ["GET","HEAD"],
    pattern: '/api/v1/labours',
    tokens: [[0,"api"],[0,"v1"],[0,"labours"]],
    types: placeholder as Registry['labours.index']['types'],
  },
  'labours.store': {
    methods: ["POST"],
    pattern: '/api/v1/labours',
    tokens: [[0,"api"],[0,"v1"],[0,"labours"]],
    types: placeholder as Registry['labours.store']['types'],
  },
  'labours.show': {
    methods: ["GET","HEAD"],
    pattern: '/api/v1/labours/:id',
    tokens: [[0,"api"],[0,"v1"],[0,"labours"],[1,"id"]],
    types: placeholder as Registry['labours.show']['types'],
  },
  'labours.update': {
    methods: ["PUT"],
    pattern: '/api/v1/labours/:id',
    tokens: [[0,"api"],[0,"v1"],[0,"labours"],[1,"id"]],
    types: placeholder as Registry['labours.update']['types'],
  },
  'labours.status': {
    methods: ["PATCH"],
    pattern: '/api/v1/labours/:id/status',
    tokens: [[0,"api"],[0,"v1"],[0,"labours"],[1,"id"],[0,"status"]],
    types: placeholder as Registry['labours.status']['types'],
  },
  'attendance.show': {
    methods: ["GET","HEAD"],
    pattern: '/api/v1/attendance',
    tokens: [[0,"api"],[0,"v1"],[0,"attendance"]],
    types: placeholder as Registry['attendance.show']['types'],
  },
  'attendance.save': {
    methods: ["PUT"],
    pattern: '/api/v1/attendance',
    tokens: [[0,"api"],[0,"v1"],[0,"attendance"]],
    types: placeholder as Registry['attendance.save']['types'],
  },
  'attendance.labour_month': {
    methods: ["GET","HEAD"],
    pattern: '/api/v1/labours/:id/attendance',
    tokens: [[0,"api"],[0,"v1"],[0,"labours"],[1,"id"],[0,"attendance"]],
    types: placeholder as Registry['attendance.labour_month']['types'],
  },
  'wages.sheet': {
    methods: ["GET","HEAD"],
    pattern: '/api/v1/wages',
    tokens: [[0,"api"],[0,"v1"],[0,"wages"]],
    types: placeholder as Registry['wages.sheet']['types'],
  },
  'wages.labour': {
    methods: ["GET","HEAD"],
    pattern: '/api/v1/labours/:id/wages',
    tokens: [[0,"api"],[0,"v1"],[0,"labours"],[1,"id"],[0,"wages"]],
    types: placeholder as Registry['wages.labour']['types'],
  },
  'wages.advances': {
    methods: ["GET","HEAD"],
    pattern: '/api/v1/labours/:id/advances',
    tokens: [[0,"api"],[0,"v1"],[0,"labours"],[1,"id"],[0,"advances"]],
    types: placeholder as Registry['wages.advances']['types'],
  },
  'wages.store_advance': {
    methods: ["POST"],
    pattern: '/api/v1/labours/:id/advances',
    tokens: [[0,"api"],[0,"v1"],[0,"labours"],[1,"id"],[0,"advances"]],
    types: placeholder as Registry['wages.store_advance']['types'],
  },
  'wages.destroy_advance': {
    methods: ["DELETE"],
    pattern: '/api/v1/advances/:id',
    tokens: [[0,"api"],[0,"v1"],[0,"advances"],[1,"id"]],
    types: placeholder as Registry['wages.destroy_advance']['types'],
  },
  'wages.store_payment': {
    methods: ["POST"],
    pattern: '/api/v1/labours/:id/wage-payments',
    tokens: [[0,"api"],[0,"v1"],[0,"labours"],[1,"id"],[0,"wage-payments"]],
    types: placeholder as Registry['wages.store_payment']['types'],
  },
  'wages.destroy_payment': {
    methods: ["DELETE"],
    pattern: '/api/v1/wage-payments/:id',
    tokens: [[0,"api"],[0,"v1"],[0,"wage-payments"],[1,"id"]],
    types: placeholder as Registry['wages.destroy_payment']['types'],
  },
  'expenses.index': {
    methods: ["GET","HEAD"],
    pattern: '/api/v1/expenses',
    tokens: [[0,"api"],[0,"v1"],[0,"expenses"]],
    types: placeholder as Registry['expenses.index']['types'],
  },
  'expenses.store': {
    methods: ["POST"],
    pattern: '/api/v1/expenses',
    tokens: [[0,"api"],[0,"v1"],[0,"expenses"]],
    types: placeholder as Registry['expenses.store']['types'],
  },
  'expenses.show': {
    methods: ["GET","HEAD"],
    pattern: '/api/v1/expenses/:id',
    tokens: [[0,"api"],[0,"v1"],[0,"expenses"],[1,"id"]],
    types: placeholder as Registry['expenses.show']['types'],
  },
  'expenses.update': {
    methods: ["PUT"],
    pattern: '/api/v1/expenses/:id',
    tokens: [[0,"api"],[0,"v1"],[0,"expenses"],[1,"id"]],
    types: placeholder as Registry['expenses.update']['types'],
  },
  'expenses.destroy': {
    methods: ["DELETE"],
    pattern: '/api/v1/expenses/:id',
    tokens: [[0,"api"],[0,"v1"],[0,"expenses"],[1,"id"]],
    types: placeholder as Registry['expenses.destroy']['types'],
  },
  'expenses.categories': {
    methods: ["GET","HEAD"],
    pattern: '/api/v1/expense-categories',
    tokens: [[0,"api"],[0,"v1"],[0,"expense-categories"]],
    types: placeholder as Registry['expenses.categories']['types'],
  },
  'expenses.store_category': {
    methods: ["POST"],
    pattern: '/api/v1/expense-categories',
    tokens: [[0,"api"],[0,"v1"],[0,"expense-categories"]],
    types: placeholder as Registry['expenses.store_category']['types'],
  },
  'expenses.update_category': {
    methods: ["PUT"],
    pattern: '/api/v1/expense-categories/:id',
    tokens: [[0,"api"],[0,"v1"],[0,"expense-categories"],[1,"id"]],
    types: placeholder as Registry['expenses.update_category']['types'],
  },
  'uploads.store': {
    methods: ["POST"],
    pattern: '/api/v1/uploads',
    tokens: [[0,"api"],[0,"v1"],[0,"uploads"]],
    types: placeholder as Registry['uploads.store']['types'],
  },
  'reports.dashboard': {
    methods: ["GET","HEAD"],
    pattern: '/api/v1/dashboard',
    tokens: [[0,"api"],[0,"v1"],[0,"dashboard"]],
    types: placeholder as Registry['reports.dashboard']['types'],
  },
  'reports.sales': {
    methods: ["GET","HEAD"],
    pattern: '/api/v1/reports/sales',
    tokens: [[0,"api"],[0,"v1"],[0,"reports"],[0,"sales"]],
    types: placeholder as Registry['reports.sales']['types'],
  },
  'reports.dues': {
    methods: ["GET","HEAD"],
    pattern: '/api/v1/reports/dues',
    tokens: [[0,"api"],[0,"v1"],[0,"reports"],[0,"dues"]],
    types: placeholder as Registry['reports.dues']['types'],
  },
  'reports.expenses': {
    methods: ["GET","HEAD"],
    pattern: '/api/v1/reports/expenses',
    tokens: [[0,"api"],[0,"v1"],[0,"reports"],[0,"expenses"]],
    types: placeholder as Registry['reports.expenses']['types'],
  },
  'reports.wages': {
    methods: ["GET","HEAD"],
    pattern: '/api/v1/reports/wages',
    tokens: [[0,"api"],[0,"v1"],[0,"reports"],[0,"wages"]],
    types: placeholder as Registry['reports.wages']['types'],
  },
  'reports.net_profit': {
    methods: ["GET","HEAD"],
    pattern: '/api/v1/reports/net-profit',
    tokens: [[0,"api"],[0,"v1"],[0,"reports"],[0,"net-profit"]],
    types: placeholder as Registry['reports.net_profit']['types'],
  },
  'reports.collections': {
    methods: ["GET","HEAD"],
    pattern: '/api/v1/reports/collections',
    tokens: [[0,"api"],[0,"v1"],[0,"reports"],[0,"collections"]],
    types: placeholder as Registry['reports.collections']['types'],
  },
  'settings.factory': {
    methods: ["GET","HEAD"],
    pattern: '/api/v1/settings/factory',
    tokens: [[0,"api"],[0,"v1"],[0,"settings"],[0,"factory"]],
    types: placeholder as Registry['settings.factory']['types'],
  },
  'settings.update_factory': {
    methods: ["PUT"],
    pattern: '/api/v1/settings/factory',
    tokens: [[0,"api"],[0,"v1"],[0,"settings"],[0,"factory"]],
    types: placeholder as Registry['settings.update_factory']['types'],
  },
} as const satisfies Record<string, AdonisEndpoint>

export { routes }

export const registry = {
  routes,
  $tree: {} as ApiDefinition,
}

declare module '@tuyau/core/types' {
  export interface UserRegistry {
    routes: typeof routes
    $tree: ApiDefinition
  }
}
