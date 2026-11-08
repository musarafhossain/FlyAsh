/*
|--------------------------------------------------------------------------
| HTTP rate limiters
|--------------------------------------------------------------------------
*/

import limiter from '@adonisjs/limiter/services/main'

/** Forgot password: 3 OTP requests per 15 minutes per IP + email */
export const forgotPasswordThrottle = limiter.define('forgot_password', (ctx) => {
  const email = String(ctx.request.input('email', '')).trim().toLowerCase()
  return limiter
    .allowRequests(3)
    .every('15 mins')
    .usingKey(`${ctx.request.ip()}_${email}`)
})

/** Verify OTP / reset password: 10 requests per 15 minutes per IP */
export const otpThrottle = limiter.define('otp', (ctx) => {
  return limiter.allowRequests(10).every('15 mins').usingKey(ctx.request.ip())
})

/** Login: 5 failed attempts per 15 minutes per IP + login (used with penalize) */
export const loginLimiter = limiter.use({
  requests: 5,
  duration: '15 mins',
  blockDuration: '15 mins',
})
