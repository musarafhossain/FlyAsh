/* eslint-disable prettier/prettier */
import type { AdonisEndpoint } from '@tuyau/core/types'
import type { Registry } from './schema.d.ts'
import type { ApiDefinition } from './tree.d.ts'

export type { Route, Path } from './schema.d.ts'

const placeholder: any = {}

const routes = {
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
