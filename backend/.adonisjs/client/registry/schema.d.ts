/* eslint-disable prettier/prettier */
/// <reference path="../manifest.d.ts" />

import type { ExtractBody, ExtractErrorResponse, ExtractQuery, ExtractQueryForGet, ExtractRawResponse, ExtractResponse, Method, PathWithRegistry, PatternsByMethod, RouteWithRegistry } from '@tuyau/core/types'
import type { InferInput, SimpleError } from '@vinejs/vine/types'
import type { routes } from './index.ts'

export type ParamValue = string | number | bigint | boolean

export interface Registry {
  'uploads.show': {
    methods: ["GET","HEAD"]
    pattern: '/uploads/*'
    types: {
      body: {}
      paramsTuple: [ParamValue]
      params: { '*': ParamValue[] }
      query: {}
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/uploads_controller').default['show']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/uploads_controller').default['show']>>>
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/uploads_controller').default['show']>>>
    }
  }
  'auth.login': {
    methods: ["POST"]
    pattern: '/api/v1/auth/login'
    types: {
      body: ExtractBody<InferInput<(typeof import('#validators/auth').loginValidator)>>
      paramsTuple: []
      params: {}
      query: ExtractQuery<InferInput<(typeof import('#validators/auth').loginValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/auth_controller').default['login']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/auth_controller').default['login']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/auth_controller').default['login']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'password_reset.forgot': {
    methods: ["POST"]
    pattern: '/api/v1/auth/forgot-password'
    types: {
      body: ExtractBody<InferInput<(typeof import('#validators/auth').forgotPasswordValidator)>>
      paramsTuple: []
      params: {}
      query: ExtractQuery<InferInput<(typeof import('#validators/auth').forgotPasswordValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/password_reset_controller').default['forgot']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/password_reset_controller').default['forgot']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/password_reset_controller').default['forgot']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'password_reset.verify': {
    methods: ["POST"]
    pattern: '/api/v1/auth/verify-otp'
    types: {
      body: ExtractBody<InferInput<(typeof import('#validators/auth').verifyOtpValidator)>>
      paramsTuple: []
      params: {}
      query: ExtractQuery<InferInput<(typeof import('#validators/auth').verifyOtpValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/password_reset_controller').default['verify']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/password_reset_controller').default['verify']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/password_reset_controller').default['verify']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'password_reset.reset': {
    methods: ["POST"]
    pattern: '/api/v1/auth/reset-password'
    types: {
      body: ExtractBody<InferInput<(typeof import('#validators/auth').resetPasswordValidator)>>
      paramsTuple: []
      params: {}
      query: ExtractQuery<InferInput<(typeof import('#validators/auth').resetPasswordValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/password_reset_controller').default['reset']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/password_reset_controller').default['reset']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/password_reset_controller').default['reset']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'auth.logout': {
    methods: ["POST"]
    pattern: '/api/v1/auth/logout'
    types: {
      body: {}
      paramsTuple: []
      params: {}
      query: {}
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/auth_controller').default['logout']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/auth_controller').default['logout']>>>
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/auth_controller').default['logout']>>>
    }
  }
  'auth.me': {
    methods: ["GET","HEAD"]
    pattern: '/api/v1/auth/me'
    types: {
      body: {}
      paramsTuple: []
      params: {}
      query: {}
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/auth_controller').default['me']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/auth_controller').default['me']>>>
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/auth_controller').default['me']>>>
    }
  }
  'auth.update_me': {
    methods: ["PUT"]
    pattern: '/api/v1/auth/me'
    types: {
      body: ExtractBody<InferInput<(typeof import('#validators/auth').profileValidator)>>
      paramsTuple: []
      params: {}
      query: ExtractQuery<InferInput<(typeof import('#validators/auth').profileValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/auth_controller').default['updateMe']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/auth_controller').default['updateMe']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/auth_controller').default['updateMe']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'auth.change_password': {
    methods: ["PUT"]
    pattern: '/api/v1/auth/password'
    types: {
      body: ExtractBody<InferInput<(typeof import('#validators/auth').changePasswordValidator)>>
      paramsTuple: []
      params: {}
      query: ExtractQuery<InferInput<(typeof import('#validators/auth').changePasswordValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/auth_controller').default['changePassword']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/auth_controller').default['changePassword']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/auth_controller').default['changePassword']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'users.index': {
    methods: ["GET","HEAD"]
    pattern: '/api/v1/users'
    types: {
      body: {}
      paramsTuple: []
      params: {}
      query: ExtractQueryForGet<InferInput<(typeof import('#validators/user').listUsersValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/users_controller').default['index']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/users_controller').default['index']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/users_controller').default['index']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'users.store': {
    methods: ["POST"]
    pattern: '/api/v1/users'
    types: {
      body: ExtractBody<InferInput<(typeof import('#validators/user').createUserValidator)>>
      paramsTuple: []
      params: {}
      query: ExtractQuery<InferInput<(typeof import('#validators/user').createUserValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/users_controller').default['store']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/users_controller').default['store']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/users_controller').default['store']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'users.show': {
    methods: ["GET","HEAD"]
    pattern: '/api/v1/users/:id'
    types: {
      body: {}
      paramsTuple: [ParamValue]
      params: { id: ParamValue }
      query: {}
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/users_controller').default['show']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/users_controller').default['show']>>>
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/users_controller').default['show']>>>
    }
  }
  'users.update': {
    methods: ["PUT"]
    pattern: '/api/v1/users/:id'
    types: {
      body: ExtractBody<InferInput<(typeof import('#validators/user').updateUserValidator)>>
      paramsTuple: [ParamValue]
      params: { id: ParamValue }
      query: ExtractQuery<InferInput<(typeof import('#validators/user').updateUserValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/users_controller').default['update']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/users_controller').default['update']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/users_controller').default['update']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'users.status': {
    methods: ["PATCH"]
    pattern: '/api/v1/users/:id/status'
    types: {
      body: ExtractBody<InferInput<(typeof import('#validators/user').userStatusValidator)>>
      paramsTuple: [ParamValue]
      params: { id: ParamValue }
      query: ExtractQuery<InferInput<(typeof import('#validators/user').userStatusValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/users_controller').default['status']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/users_controller').default['status']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/users_controller').default['status']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'users.reset_password': {
    methods: ["PUT"]
    pattern: '/api/v1/users/:id/password'
    types: {
      body: ExtractBody<InferInput<(typeof import('#validators/user').resetUserPasswordValidator)>>
      paramsTuple: [ParamValue]
      params: { id: ParamValue }
      query: ExtractQuery<InferInput<(typeof import('#validators/user').resetUserPasswordValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/users_controller').default['resetPassword']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/users_controller').default['resetPassword']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/users_controller').default['resetPassword']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'products.index': {
    methods: ["GET","HEAD"]
    pattern: '/api/v1/products'
    types: {
      body: {}
      paramsTuple: []
      params: {}
      query: ExtractQueryForGet<InferInput<(typeof import('#validators/product').listProductsValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/products_controller').default['index']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/products_controller').default['index']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/products_controller').default['index']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'products.store': {
    methods: ["POST"]
    pattern: '/api/v1/products'
    types: {
      body: ExtractBody<InferInput<(typeof import('#validators/product').productValidator)>>
      paramsTuple: []
      params: {}
      query: ExtractQuery<InferInput<(typeof import('#validators/product').productValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/products_controller').default['store']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/products_controller').default['store']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/products_controller').default['store']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'products.show': {
    methods: ["GET","HEAD"]
    pattern: '/api/v1/products/:id'
    types: {
      body: {}
      paramsTuple: [ParamValue]
      params: { id: ParamValue }
      query: {}
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/products_controller').default['show']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/products_controller').default['show']>>>
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/products_controller').default['show']>>>
    }
  }
  'products.update': {
    methods: ["PUT"]
    pattern: '/api/v1/products/:id'
    types: {
      body: ExtractBody<InferInput<(typeof import('#validators/product').productValidator)>>
      paramsTuple: [ParamValue]
      params: { id: ParamValue }
      query: ExtractQuery<InferInput<(typeof import('#validators/product').productValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/products_controller').default['update']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/products_controller').default['update']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/products_controller').default['update']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'products.status': {
    methods: ["PATCH"]
    pattern: '/api/v1/products/:id/status'
    types: {
      body: ExtractBody<InferInput<(typeof import('#validators/product').productStatusValidator)>>
      paramsTuple: [ParamValue]
      params: { id: ParamValue }
      query: ExtractQuery<InferInput<(typeof import('#validators/product').productStatusValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/products_controller').default['status']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/products_controller').default['status']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/products_controller').default['status']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'products.destroy': {
    methods: ["DELETE"]
    pattern: '/api/v1/products/:id'
    types: {
      body: {}
      paramsTuple: [ParamValue]
      params: { id: ParamValue }
      query: {}
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/products_controller').default['destroy']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/products_controller').default['destroy']>>>
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/products_controller').default['destroy']>>>
    }
  }
  'customers.index': {
    methods: ["GET","HEAD"]
    pattern: '/api/v1/customers'
    types: {
      body: {}
      paramsTuple: []
      params: {}
      query: ExtractQueryForGet<InferInput<(typeof import('#validators/customer').listCustomersValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/customers_controller').default['index']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/customers_controller').default['index']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/customers_controller').default['index']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'customers.store': {
    methods: ["POST"]
    pattern: '/api/v1/customers'
    types: {
      body: ExtractBody<InferInput<(typeof import('#validators/customer').customerValidator)>>
      paramsTuple: []
      params: {}
      query: ExtractQuery<InferInput<(typeof import('#validators/customer').customerValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/customers_controller').default['store']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/customers_controller').default['store']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/customers_controller').default['store']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'customers.show': {
    methods: ["GET","HEAD"]
    pattern: '/api/v1/customers/:id'
    types: {
      body: {}
      paramsTuple: [ParamValue]
      params: { id: ParamValue }
      query: {}
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/customers_controller').default['show']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/customers_controller').default['show']>>>
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/customers_controller').default['show']>>>
    }
  }
  'customers.update': {
    methods: ["PUT"]
    pattern: '/api/v1/customers/:id'
    types: {
      body: ExtractBody<InferInput<(typeof import('#validators/customer').customerValidator)>>
      paramsTuple: [ParamValue]
      params: { id: ParamValue }
      query: ExtractQuery<InferInput<(typeof import('#validators/customer').customerValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/customers_controller').default['update']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/customers_controller').default['update']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/customers_controller').default['update']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'customers.status': {
    methods: ["PATCH"]
    pattern: '/api/v1/customers/:id/status'
    types: {
      body: ExtractBody<InferInput<(typeof import('#validators/customer').customerStatusValidator)>>
      paramsTuple: [ParamValue]
      params: { id: ParamValue }
      query: ExtractQuery<InferInput<(typeof import('#validators/customer').customerStatusValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/customers_controller').default['status']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/customers_controller').default['status']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/customers_controller').default['status']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'customers.destroy': {
    methods: ["DELETE"]
    pattern: '/api/v1/customers/:id'
    types: {
      body: {}
      paramsTuple: [ParamValue]
      params: { id: ParamValue }
      query: {}
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/customers_controller').default['destroy']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/customers_controller').default['destroy']>>>
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/customers_controller').default['destroy']>>>
    }
  }
  'sales.by_customer': {
    methods: ["GET","HEAD"]
    pattern: '/api/v1/customers/:id/sales'
    types: {
      body: {}
      paramsTuple: [ParamValue]
      params: { id: ParamValue }
      query: ExtractQueryForGet<InferInput<(typeof import('#validators/sale').paginationValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/sales_controller').default['byCustomer']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/sales_controller').default['byCustomer']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/sales_controller').default['byCustomer']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'sales.index': {
    methods: ["GET","HEAD"]
    pattern: '/api/v1/sales'
    types: {
      body: {}
      paramsTuple: []
      params: {}
      query: ExtractQueryForGet<InferInput<(typeof import('#validators/sale').listSalesValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/sales_controller').default['index']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/sales_controller').default['index']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/sales_controller').default['index']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'sales.upcoming': {
    methods: ["GET","HEAD"]
    pattern: '/api/v1/sales/upcoming-deliveries'
    types: {
      body: {}
      paramsTuple: []
      params: {}
      query: ExtractQueryForGet<InferInput<(typeof import('#validators/sale').paginationValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/sales_controller').default['upcoming']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/sales_controller').default['upcoming']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/sales_controller').default['upcoming']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'sales.store': {
    methods: ["POST"]
    pattern: '/api/v1/sales'
    types: {
      body: ExtractBody<InferInput<(typeof import('#validators/sale').createSaleValidator)>>
      paramsTuple: []
      params: {}
      query: ExtractQuery<InferInput<(typeof import('#validators/sale').createSaleValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/sales_controller').default['store']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/sales_controller').default['store']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/sales_controller').default['store']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'sales.show': {
    methods: ["GET","HEAD"]
    pattern: '/api/v1/sales/:id'
    types: {
      body: {}
      paramsTuple: [ParamValue]
      params: { id: ParamValue }
      query: {}
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/sales_controller').default['show']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/sales_controller').default['show']>>>
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/sales_controller').default['show']>>>
    }
  }
  'sales.update': {
    methods: ["PUT"]
    pattern: '/api/v1/sales/:id'
    types: {
      body: ExtractBody<InferInput<(typeof import('#validators/sale').updateSaleValidator)>>
      paramsTuple: [ParamValue]
      params: { id: ParamValue }
      query: ExtractQuery<InferInput<(typeof import('#validators/sale').updateSaleValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/sales_controller').default['update']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/sales_controller').default['update']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/sales_controller').default['update']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'sales.destroy': {
    methods: ["DELETE"]
    pattern: '/api/v1/sales/:id'
    types: {
      body: {}
      paramsTuple: [ParamValue]
      params: { id: ParamValue }
      query: {}
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/sales_controller').default['destroy']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/sales_controller').default['destroy']>>>
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/sales_controller').default['destroy']>>>
    }
  }
  'sales.deliver': {
    methods: ["POST"]
    pattern: '/api/v1/sales/:id/deliver'
    types: {
      body: ExtractBody<InferInput<(typeof import('#validators/sale').deliverSaleValidator)>>
      paramsTuple: [ParamValue]
      params: { id: ParamValue }
      query: ExtractQuery<InferInput<(typeof import('#validators/sale').deliverSaleValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/sales_controller').default['deliver']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/sales_controller').default['deliver']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/sales_controller').default['deliver']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'sales.cancel': {
    methods: ["POST"]
    pattern: '/api/v1/sales/:id/cancel'
    types: {
      body: {}
      paramsTuple: [ParamValue]
      params: { id: ParamValue }
      query: {}
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/sales_controller').default['cancel']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/sales_controller').default['cancel']>>>
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/sales_controller').default['cancel']>>>
    }
  }
  'sales.add_payment': {
    methods: ["POST"]
    pattern: '/api/v1/sales/:id/payments'
    types: {
      body: ExtractBody<InferInput<(typeof import('#validators/sale').salePaymentValidator)>>
      paramsTuple: [ParamValue]
      params: { id: ParamValue }
      query: ExtractQuery<InferInput<(typeof import('#validators/sale').salePaymentValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/sales_controller').default['addPayment']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/sales_controller').default['addPayment']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/sales_controller').default['addPayment']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'sales.delete_payment': {
    methods: ["DELETE"]
    pattern: '/api/v1/sales/:id/payments/:paymentId'
    types: {
      body: {}
      paramsTuple: [ParamValue, ParamValue]
      params: { id: ParamValue; paymentId: ParamValue }
      query: {}
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/sales_controller').default['deletePayment']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/sales_controller').default['deletePayment']>>>
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/sales_controller').default['deletePayment']>>>
    }
  }
  'labours.index': {
    methods: ["GET","HEAD"]
    pattern: '/api/v1/labours'
    types: {
      body: {}
      paramsTuple: []
      params: {}
      query: ExtractQueryForGet<InferInput<(typeof import('#validators/labour').listLaboursValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/labours_controller').default['index']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/labours_controller').default['index']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/labours_controller').default['index']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'labours.store': {
    methods: ["POST"]
    pattern: '/api/v1/labours'
    types: {
      body: ExtractBody<InferInput<(typeof import('#validators/labour').labourValidator)>>
      paramsTuple: []
      params: {}
      query: ExtractQuery<InferInput<(typeof import('#validators/labour').labourValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/labours_controller').default['store']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/labours_controller').default['store']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/labours_controller').default['store']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'labours.show': {
    methods: ["GET","HEAD"]
    pattern: '/api/v1/labours/:id'
    types: {
      body: {}
      paramsTuple: [ParamValue]
      params: { id: ParamValue }
      query: {}
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/labours_controller').default['show']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/labours_controller').default['show']>>>
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/labours_controller').default['show']>>>
    }
  }
  'labours.update': {
    methods: ["PUT"]
    pattern: '/api/v1/labours/:id'
    types: {
      body: ExtractBody<InferInput<(typeof import('#validators/labour').labourValidator)>>
      paramsTuple: [ParamValue]
      params: { id: ParamValue }
      query: ExtractQuery<InferInput<(typeof import('#validators/labour').labourValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/labours_controller').default['update']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/labours_controller').default['update']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/labours_controller').default['update']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'labours.status': {
    methods: ["PATCH"]
    pattern: '/api/v1/labours/:id/status'
    types: {
      body: ExtractBody<InferInput<(typeof import('#validators/labour').labourStatusValidator)>>
      paramsTuple: [ParamValue]
      params: { id: ParamValue }
      query: ExtractQuery<InferInput<(typeof import('#validators/labour').labourStatusValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/labours_controller').default['status']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/labours_controller').default['status']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/labours_controller').default['status']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'attendance.show': {
    methods: ["GET","HEAD"]
    pattern: '/api/v1/attendance'
    types: {
      body: {}
      paramsTuple: []
      params: {}
      query: ExtractQueryForGet<InferInput<(typeof import('#validators/labour').attendanceDayValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/attendance_controller').default['show']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/attendance_controller').default['show']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/attendance_controller').default['show']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'attendance.save': {
    methods: ["PUT"]
    pattern: '/api/v1/attendance'
    types: {
      body: ExtractBody<InferInput<(typeof import('#validators/labour').saveAttendanceValidator)>>
      paramsTuple: []
      params: {}
      query: ExtractQuery<InferInput<(typeof import('#validators/labour').saveAttendanceValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/attendance_controller').default['save']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/attendance_controller').default['save']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/attendance_controller').default['save']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'attendance.labour_month': {
    methods: ["GET","HEAD"]
    pattern: '/api/v1/labours/:id/attendance'
    types: {
      body: {}
      paramsTuple: [ParamValue]
      params: { id: ParamValue }
      query: ExtractQueryForGet<InferInput<(typeof import('#validators/labour').monthValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/attendance_controller').default['labourMonth']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/attendance_controller').default['labourMonth']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/attendance_controller').default['labourMonth']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'wages.sheet': {
    methods: ["GET","HEAD"]
    pattern: '/api/v1/wages'
    types: {
      body: {}
      paramsTuple: []
      params: {}
      query: ExtractQueryForGet<InferInput<(typeof import('#validators/labour').wageSheetValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/wages_controller').default['sheet']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/wages_controller').default['sheet']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/wages_controller').default['sheet']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'wages.labour': {
    methods: ["GET","HEAD"]
    pattern: '/api/v1/labours/:id/wages'
    types: {
      body: {}
      paramsTuple: [ParamValue]
      params: { id: ParamValue }
      query: ExtractQueryForGet<InferInput<(typeof import('#validators/labour').monthValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/wages_controller').default['labour']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/wages_controller').default['labour']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/wages_controller').default['labour']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'wages.advances': {
    methods: ["GET","HEAD"]
    pattern: '/api/v1/labours/:id/advances'
    types: {
      body: {}
      paramsTuple: [ParamValue]
      params: { id: ParamValue }
      query: ExtractQueryForGet<InferInput<(typeof import('#validators/sale').paginationValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/wages_controller').default['advances']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/wages_controller').default['advances']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/wages_controller').default['advances']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'wages.store_advance': {
    methods: ["POST"]
    pattern: '/api/v1/labours/:id/advances'
    types: {
      body: ExtractBody<InferInput<(typeof import('#validators/labour').advanceValidator)>>
      paramsTuple: [ParamValue]
      params: { id: ParamValue }
      query: ExtractQuery<InferInput<(typeof import('#validators/labour').advanceValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/wages_controller').default['storeAdvance']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/wages_controller').default['storeAdvance']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/wages_controller').default['storeAdvance']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'wages.destroy_advance': {
    methods: ["DELETE"]
    pattern: '/api/v1/advances/:id'
    types: {
      body: {}
      paramsTuple: [ParamValue]
      params: { id: ParamValue }
      query: {}
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/wages_controller').default['destroyAdvance']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/wages_controller').default['destroyAdvance']>>>
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/wages_controller').default['destroyAdvance']>>>
    }
  }
  'wages.store_payment': {
    methods: ["POST"]
    pattern: '/api/v1/labours/:id/wage-payments'
    types: {
      body: ExtractBody<InferInput<(typeof import('#validators/labour').wagePaymentValidator)>>
      paramsTuple: [ParamValue]
      params: { id: ParamValue }
      query: ExtractQuery<InferInput<(typeof import('#validators/labour').wagePaymentValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/wages_controller').default['storePayment']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/wages_controller').default['storePayment']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/wages_controller').default['storePayment']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'wages.destroy_payment': {
    methods: ["DELETE"]
    pattern: '/api/v1/wage-payments/:id'
    types: {
      body: {}
      paramsTuple: [ParamValue]
      params: { id: ParamValue }
      query: {}
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/wages_controller').default['destroyPayment']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/wages_controller').default['destroyPayment']>>>
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/wages_controller').default['destroyPayment']>>>
    }
  }
  'expenses.index': {
    methods: ["GET","HEAD"]
    pattern: '/api/v1/expenses'
    types: {
      body: {}
      paramsTuple: []
      params: {}
      query: ExtractQueryForGet<InferInput<(typeof import('#validators/expense').listExpensesValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/expenses_controller').default['index']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/expenses_controller').default['index']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/expenses_controller').default['index']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'expenses.store': {
    methods: ["POST"]
    pattern: '/api/v1/expenses'
    types: {
      body: ExtractBody<InferInput<(typeof import('#validators/expense').expenseValidator)>>
      paramsTuple: []
      params: {}
      query: ExtractQuery<InferInput<(typeof import('#validators/expense').expenseValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/expenses_controller').default['store']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/expenses_controller').default['store']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/expenses_controller').default['store']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'expenses.show': {
    methods: ["GET","HEAD"]
    pattern: '/api/v1/expenses/:id'
    types: {
      body: {}
      paramsTuple: [ParamValue]
      params: { id: ParamValue }
      query: {}
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/expenses_controller').default['show']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/expenses_controller').default['show']>>>
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/expenses_controller').default['show']>>>
    }
  }
  'expenses.update': {
    methods: ["PUT"]
    pattern: '/api/v1/expenses/:id'
    types: {
      body: ExtractBody<InferInput<(typeof import('#validators/expense').expenseValidator)>>
      paramsTuple: [ParamValue]
      params: { id: ParamValue }
      query: ExtractQuery<InferInput<(typeof import('#validators/expense').expenseValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/expenses_controller').default['update']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/expenses_controller').default['update']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/expenses_controller').default['update']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'expenses.destroy': {
    methods: ["DELETE"]
    pattern: '/api/v1/expenses/:id'
    types: {
      body: {}
      paramsTuple: [ParamValue]
      params: { id: ParamValue }
      query: {}
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/expenses_controller').default['destroy']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/expenses_controller').default['destroy']>>>
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/expenses_controller').default['destroy']>>>
    }
  }
  'expenses.categories': {
    methods: ["GET","HEAD"]
    pattern: '/api/v1/expense-categories'
    types: {
      body: {}
      paramsTuple: []
      params: {}
      query: ExtractQueryForGet<InferInput<(typeof import('#validators/expense').listCategoriesValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/expenses_controller').default['categories']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/expenses_controller').default['categories']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/expenses_controller').default['categories']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'expenses.store_category': {
    methods: ["POST"]
    pattern: '/api/v1/expense-categories'
    types: {
      body: ExtractBody<InferInput<(typeof import('#validators/expense').categoryValidator)>>
      paramsTuple: []
      params: {}
      query: ExtractQuery<InferInput<(typeof import('#validators/expense').categoryValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/expenses_controller').default['storeCategory']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/expenses_controller').default['storeCategory']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/expenses_controller').default['storeCategory']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'expenses.update_category': {
    methods: ["PUT"]
    pattern: '/api/v1/expense-categories/:id'
    types: {
      body: ExtractBody<InferInput<(typeof import('#validators/expense').categoryValidator)>>
      paramsTuple: [ParamValue]
      params: { id: ParamValue }
      query: ExtractQuery<InferInput<(typeof import('#validators/expense').categoryValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/expenses_controller').default['updateCategory']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/expenses_controller').default['updateCategory']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/expenses_controller').default['updateCategory']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'uploads.store': {
    methods: ["POST"]
    pattern: '/api/v1/uploads'
    types: {
      body: ExtractBody<InferInput<(typeof import('#validators/expense').uploadValidator)>>
      paramsTuple: []
      params: {}
      query: ExtractQuery<InferInput<(typeof import('#validators/expense').uploadValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/uploads_controller').default['store']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/uploads_controller').default['store']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/uploads_controller').default['store']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'reports.dashboard': {
    methods: ["GET","HEAD"]
    pattern: '/api/v1/dashboard'
    types: {
      body: {}
      paramsTuple: []
      params: {}
      query: {}
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/reports_controller').default['dashboard']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/reports_controller').default['dashboard']>>>
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/reports_controller').default['dashboard']>>>
    }
  }
  'reports.sales': {
    methods: ["GET","HEAD"]
    pattern: '/api/v1/reports/sales'
    types: {
      body: {}
      paramsTuple: []
      params: {}
      query: {}
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/reports_controller').default['sales']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/reports_controller').default['sales']>>>
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/reports_controller').default['sales']>>>
    }
  }
  'reports.dues': {
    methods: ["GET","HEAD"]
    pattern: '/api/v1/reports/dues'
    types: {
      body: {}
      paramsTuple: []
      params: {}
      query: ExtractQueryForGet<InferInput<(typeof import('#validators/report').duesReportValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/reports_controller').default['dues']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/reports_controller').default['dues']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/reports_controller').default['dues']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'reports.expenses': {
    methods: ["GET","HEAD"]
    pattern: '/api/v1/reports/expenses'
    types: {
      body: {}
      paramsTuple: []
      params: {}
      query: {}
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/reports_controller').default['expenses']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/reports_controller').default['expenses']>>>
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/reports_controller').default['expenses']>>>
    }
  }
  'reports.wages': {
    methods: ["GET","HEAD"]
    pattern: '/api/v1/reports/wages'
    types: {
      body: {}
      paramsTuple: []
      params: {}
      query: ExtractQueryForGet<InferInput<(typeof import('#validators/report').reportMonthValidator)>>
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/reports_controller').default['wages']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/reports_controller').default['wages']>>> | { status: 422; response: { errors: SimpleError[] } }
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/reports_controller').default['wages']>>> | { status: 422; response: { errors: SimpleError[] } }
    }
  }
  'reports.net_profit': {
    methods: ["GET","HEAD"]
    pattern: '/api/v1/reports/net-profit'
    types: {
      body: {}
      paramsTuple: []
      params: {}
      query: {}
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/reports_controller').default['netProfit']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/reports_controller').default['netProfit']>>>
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/reports_controller').default['netProfit']>>>
    }
  }
  'reports.collections': {
    methods: ["GET","HEAD"]
    pattern: '/api/v1/reports/collections'
    types: {
      body: {}
      paramsTuple: []
      params: {}
      query: {}
      response: ExtractResponse<Awaited<ReturnType<import('#controllers/reports_controller').default['collections']>>>
      errorResponse: ExtractErrorResponse<Awaited<ReturnType<import('#controllers/reports_controller').default['collections']>>>
      rawResponse: ExtractRawResponse<Awaited<ReturnType<import('#controllers/reports_controller').default['collections']>>>
    }
  }
}

export namespace Route {
  export type Request<Name extends keyof typeof routes> = RouteWithRegistry.Request<typeof routes, Name>
  export type Response<Name extends keyof typeof routes> = RouteWithRegistry.Response<typeof routes, Name>
  export type Params<Name extends keyof typeof routes> = RouteWithRegistry.Params<typeof routes, Name>
  export type Body<Name extends keyof typeof routes> = RouteWithRegistry.Body<typeof routes, Name>
  export type Query<Name extends keyof typeof routes> = RouteWithRegistry.Query<typeof routes, Name>
  export type Error<Name extends keyof typeof routes> = RouteWithRegistry.Error<typeof routes, Name>
}

export namespace Path {
  export type Request<M extends Method, P extends PatternsByMethod<typeof routes, M>> =
    PathWithRegistry.Request<typeof routes, M, P>
  export type Response<M extends Method, P extends PatternsByMethod<typeof routes, M>> =
    PathWithRegistry.Response<typeof routes, M, P>
  export type Params<M extends Method, P extends PatternsByMethod<typeof routes, M>> =
    PathWithRegistry.Params<typeof routes, M, P>
  export type Body<M extends Method, P extends PatternsByMethod<typeof routes, M>> =
    PathWithRegistry.Body<typeof routes, M, P>
  export type Query<M extends Method, P extends PatternsByMethod<typeof routes, M>> =
    PathWithRegistry.Query<typeof routes, M, P>
  export type Error<M extends Method, P extends PatternsByMethod<typeof routes, M>> =
    PathWithRegistry.Error<typeof routes, M, P>
}
