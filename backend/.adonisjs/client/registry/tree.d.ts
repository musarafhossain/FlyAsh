/* eslint-disable prettier/prettier */
import type { routes } from './index.ts'

export interface ApiDefinition {
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
}
