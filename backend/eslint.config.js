import { configApp } from '@adonisjs/eslint-config'

export default configApp({
  files: ['tests/**/*.ts'],
  rules: {
    // `(await client.get(...)).body().data` keeps tests short and readable
    '@unicorn/no-await-expression-member': 'off',
  },
})
