/* eslint-disable prettier/prettier */
import type { routes } from './index.ts'

export interface ApiDefinition {
  settings: {
    appVersion: typeof routes['settings.app_version']
    factory: typeof routes['settings.factory']
    updateFactory: typeof routes['settings.update_factory']
  }
  auth: {
    login: typeof routes['auth.login']
    logout: typeof routes['auth.logout']
    me: typeof routes['auth.me']
    updateMe: typeof routes['auth.update_me']
    changePassword: typeof routes['auth.change_password']
  }
  passwordReset: {
    forgot: typeof routes['password_reset.forgot']
    verify: typeof routes['password_reset.verify']
    reset: typeof routes['password_reset.reset']
  }
  users: {
    index: typeof routes['users.index']
    store: typeof routes['users.store']
    show: typeof routes['users.show']
    update: typeof routes['users.update']
    status: typeof routes['users.status']
    resetPassword: typeof routes['users.reset_password']
  }
  products: {
    index: typeof routes['products.index']
    store: typeof routes['products.store']
    show: typeof routes['products.show']
    update: typeof routes['products.update']
    status: typeof routes['products.status']
    destroy: typeof routes['products.destroy']
  }
  customers: {
    index: typeof routes['customers.index']
    store: typeof routes['customers.store']
    show: typeof routes['customers.show']
    update: typeof routes['customers.update']
    status: typeof routes['customers.status']
    destroy: typeof routes['customers.destroy']
  }
  sales: {
    byCustomer: typeof routes['sales.by_customer']
    index: typeof routes['sales.index']
    upcoming: typeof routes['sales.upcoming']
    store: typeof routes['sales.store']
    show: typeof routes['sales.show']
    update: typeof routes['sales.update']
    destroy: typeof routes['sales.destroy']
    deliver: typeof routes['sales.deliver']
    cancel: typeof routes['sales.cancel']
    addPayment: typeof routes['sales.add_payment']
    deletePayment: typeof routes['sales.delete_payment']
  }
  labours: {
    index: typeof routes['labours.index']
    store: typeof routes['labours.store']
    show: typeof routes['labours.show']
    update: typeof routes['labours.update']
    status: typeof routes['labours.status']
  }
  attendance: {
    show: typeof routes['attendance.show']
    save: typeof routes['attendance.save']
    labourMonth: typeof routes['attendance.labour_month']
  }
  wages: {
    sheet: typeof routes['wages.sheet']
    labour: typeof routes['wages.labour']
    advances: typeof routes['wages.advances']
    storeAdvance: typeof routes['wages.store_advance']
    destroyAdvance: typeof routes['wages.destroy_advance']
    storePayment: typeof routes['wages.store_payment']
    destroyPayment: typeof routes['wages.destroy_payment']
  }
  expenses: {
    index: typeof routes['expenses.index']
    store: typeof routes['expenses.store']
    show: typeof routes['expenses.show']
    update: typeof routes['expenses.update']
    destroy: typeof routes['expenses.destroy']
    categories: typeof routes['expenses.categories']
    storeCategory: typeof routes['expenses.store_category']
    updateCategory: typeof routes['expenses.update_category']
  }
  reports: {
    dashboard: typeof routes['reports.dashboard']
    sales: typeof routes['reports.sales']
    dues: typeof routes['reports.dues']
    expenses: typeof routes['reports.expenses']
    wages: typeof routes['reports.wages']
    netProfit: typeof routes['reports.net_profit']
    collections: typeof routes['reports.collections']
  }
}
