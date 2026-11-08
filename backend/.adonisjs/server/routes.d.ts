import '@adonisjs/core/types/http'

type ParamValue = string | number | bigint | boolean

export type ScannedRoutes = {
  ALL: {
    'auth.login': { paramsTuple?: []; params?: {} }
    'password_reset.forgot': { paramsTuple?: []; params?: {} }
    'password_reset.verify': { paramsTuple?: []; params?: {} }
    'password_reset.reset': { paramsTuple?: []; params?: {} }
    'auth.logout': { paramsTuple?: []; params?: {} }
    'auth.me': { paramsTuple?: []; params?: {} }
    'auth.update_me': { paramsTuple?: []; params?: {} }
    'auth.change_password': { paramsTuple?: []; params?: {} }
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
  }
  GET: {
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
  }
  HEAD: {
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
  }
  PUT: {
    'auth.update_me': { paramsTuple?: []; params?: {} }
    'auth.change_password': { paramsTuple?: []; params?: {} }
    'users.update': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'users.reset_password': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'products.update': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'customers.update': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'sales.update': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
  }
  PATCH: {
    'users.status': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'products.status': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'customers.status': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
  }
  DELETE: {
    'products.destroy': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'customers.destroy': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'sales.destroy': { paramsTuple: [ParamValue]; params: {'id': ParamValue} }
    'sales.delete_payment': { paramsTuple: [ParamValue,ParamValue]; params: {'id': ParamValue,'paymentId': ParamValue} }
  }
}
declare module '@adonisjs/core/types/http' {
  export interface RoutesList extends ScannedRoutes {}
}