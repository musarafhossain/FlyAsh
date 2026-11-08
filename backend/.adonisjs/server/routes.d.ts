import '@adonisjs/core/types/http'

type ParamValue = string | number | bigint | boolean

export type ScannedRoutes = {
  ALL: {
    'settings.app_version': { paramsTuple?: []; params?: {} }
    'auth.login': { paramsTuple?: []; params?: {} }
    'password_reset.forgot': { paramsTuple?: []; params?: {} }
    'password_reset.verify': { paramsTuple?: []; params?: {} }
    'password_reset.reset': { paramsTuple?: []; params?: {} }
    'auth.logout': { paramsTuple?: []; params?: {} }
    'auth.me': { paramsTuple?: []; params?: {} }
    'auth.update_me': { paramsTuple?: []; params?: {} }
    'auth.change_password': { paramsTuple?: []; params?: {} }
    'auth.update_locale': { paramsTuple?: []; params?: {} }
    'users.index': { paramsTuple?: []; params?: {} }
    'users.store': { paramsTuple?: []; params?: {} }
    'users.show': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'users.update': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'users.status': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'users.reset_password': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'products.index': { paramsTuple?: []; params?: {} }
    'products.store': { paramsTuple?: []; params?: {} }
    'products.show': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'products.update': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'products.status': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'products.destroy': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'customers.index': { paramsTuple?: []; params?: {} }
    'customers.store': { paramsTuple?: []; params?: {} }
    'customers.show': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'customers.update': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'customers.status': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'customers.destroy': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'sales.by_customer': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'sales.index': { paramsTuple?: []; params?: {} }
    'sales.upcoming': { paramsTuple?: []; params?: {} }
    'sales.store': { paramsTuple?: []; params?: {} }
    'sales.show': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'sales.update': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'sales.destroy': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'sales.deliver': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'sales.cancel': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'sales.add_payment': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'sales.delete_payment': { paramsTuple: [ParamValue,ParamValue]; params: {'id': ParamValue,'paymentId': ParamValue} }
    'labours.index': { paramsTuple?: []; params?: {} }
    'labours.store': { paramsTuple?: []; params?: {} }
    'labours.show': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'labours.update': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'labours.status': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'attendance.show': { paramsTuple?: []; params?: {} }
    'attendance.save': { paramsTuple?: []; params?: {} }
    'attendance.labour_month': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'wages.sheet': { paramsTuple?: []; params?: {} }
    'wages.labour': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'wages.advances': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'wages.store_advance': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'wages.destroy_advance': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'wages.store_payment': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'wages.destroy_payment': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'expenses.index': { paramsTuple?: []; params?: {} }
    'expenses.store': { paramsTuple?: []; params?: {} }
    'expenses.show': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'expenses.update': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'expenses.destroy': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'expenses.categories': { paramsTuple?: []; params?: {} }
    'expenses.store_category': { paramsTuple?: []; params?: {} }
    'expenses.update_category': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'reports.dashboard': { paramsTuple?: []; params?: {} }
    'reports.sales': { paramsTuple?: []; params?: {} }
    'reports.dues': { paramsTuple?: []; params?: {} }
    'reports.expenses': { paramsTuple?: []; params?: {} }
    'reports.wages': { paramsTuple?: []; params?: {} }
    'reports.net_profit': { paramsTuple?: []; params?: {} }
    'reports.collections': { paramsTuple?: []; params?: {} }
    'settings.factory': { paramsTuple?: []; params?: {} }
    'settings.update_factory': { paramsTuple?: []; params?: {} }
  }
  GET: {
    'settings.app_version': { paramsTuple?: []; params?: {} }
    'auth.me': { paramsTuple?: []; params?: {} }
    'users.index': { paramsTuple?: []; params?: {} }
    'users.show': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'products.index': { paramsTuple?: []; params?: {} }
    'products.show': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'customers.index': { paramsTuple?: []; params?: {} }
    'customers.show': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'sales.by_customer': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'sales.index': { paramsTuple?: []; params?: {} }
    'sales.upcoming': { paramsTuple?: []; params?: {} }
    'sales.show': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'labours.index': { paramsTuple?: []; params?: {} }
    'labours.show': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'attendance.show': { paramsTuple?: []; params?: {} }
    'attendance.labour_month': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'wages.sheet': { paramsTuple?: []; params?: {} }
    'wages.labour': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'wages.advances': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'expenses.index': { paramsTuple?: []; params?: {} }
    'expenses.show': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'expenses.categories': { paramsTuple?: []; params?: {} }
    'reports.dashboard': { paramsTuple?: []; params?: {} }
    'reports.sales': { paramsTuple?: []; params?: {} }
    'reports.dues': { paramsTuple?: []; params?: {} }
    'reports.expenses': { paramsTuple?: []; params?: {} }
    'reports.wages': { paramsTuple?: []; params?: {} }
    'reports.net_profit': { paramsTuple?: []; params?: {} }
    'reports.collections': { paramsTuple?: []; params?: {} }
    'settings.factory': { paramsTuple?: []; params?: {} }
  }
  HEAD: {
    'settings.app_version': { paramsTuple?: []; params?: {} }
    'auth.me': { paramsTuple?: []; params?: {} }
    'users.index': { paramsTuple?: []; params?: {} }
    'users.show': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'products.index': { paramsTuple?: []; params?: {} }
    'products.show': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'customers.index': { paramsTuple?: []; params?: {} }
    'customers.show': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'sales.by_customer': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'sales.index': { paramsTuple?: []; params?: {} }
    'sales.upcoming': { paramsTuple?: []; params?: {} }
    'sales.show': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'labours.index': { paramsTuple?: []; params?: {} }
    'labours.show': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'attendance.show': { paramsTuple?: []; params?: {} }
    'attendance.labour_month': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'wages.sheet': { paramsTuple?: []; params?: {} }
    'wages.labour': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'wages.advances': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'expenses.index': { paramsTuple?: []; params?: {} }
    'expenses.show': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'expenses.categories': { paramsTuple?: []; params?: {} }
    'reports.dashboard': { paramsTuple?: []; params?: {} }
    'reports.sales': { paramsTuple?: []; params?: {} }
    'reports.dues': { paramsTuple?: []; params?: {} }
    'reports.expenses': { paramsTuple?: []; params?: {} }
    'reports.wages': { paramsTuple?: []; params?: {} }
    'reports.net_profit': { paramsTuple?: []; params?: {} }
    'reports.collections': { paramsTuple?: []; params?: {} }
    'settings.factory': { paramsTuple?: []; params?: {} }
  }
  POST: {
    'auth.login': { paramsTuple?: []; params?: {} }
    'password_reset.forgot': { paramsTuple?: []; params?: {} }
    'password_reset.verify': { paramsTuple?: []; params?: {} }
    'password_reset.reset': { paramsTuple?: []; params?: {} }
    'auth.logout': { paramsTuple?: []; params?: {} }
    'users.store': { paramsTuple?: []; params?: {} }
    'products.store': { paramsTuple?: []; params?: {} }
    'customers.store': { paramsTuple?: []; params?: {} }
    'sales.store': { paramsTuple?: []; params?: {} }
    'sales.deliver': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'sales.cancel': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'sales.add_payment': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'labours.store': { paramsTuple?: []; params?: {} }
    'wages.store_advance': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'wages.store_payment': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'expenses.store': { paramsTuple?: []; params?: {} }
    'expenses.store_category': { paramsTuple?: []; params?: {} }
  }
  PUT: {
    'auth.update_me': { paramsTuple?: []; params?: {} }
    'auth.change_password': { paramsTuple?: []; params?: {} }
    'auth.update_locale': { paramsTuple?: []; params?: {} }
    'users.update': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'users.reset_password': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'products.update': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'customers.update': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'sales.update': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'labours.update': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'attendance.save': { paramsTuple?: []; params?: {} }
    'expenses.update': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'expenses.update_category': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'settings.update_factory': { paramsTuple?: []; params?: {} }
  }
  PATCH: {
    'users.status': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'products.status': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'customers.status': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'labours.status': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
  }
  DELETE: {
    'products.destroy': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'customers.destroy': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'sales.destroy': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'sales.delete_payment': { paramsTuple: [ParamValue,ParamValue]; params: {'id': ParamValue,'paymentId': ParamValue} }
    'wages.destroy_advance': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'wages.destroy_payment': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'expenses.destroy': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
  }
}
declare module '@adonisjs/core/types/http' {
  export interface RoutesList extends ScannedRoutes {}
}