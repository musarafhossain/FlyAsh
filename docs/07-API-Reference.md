# 07 · API Reference: FlyAsh

| | |
|---|---|
| **Document** | Complete REST API reference (every endpoint, payload and response case) |
| **Version** | 1.4 (adds dates and time rules, factory date headers) |
| **Date** | 2026-11-08 |
| **Source** | Every response below was captured from the running API (`backend/`); long lists are shortened to 2 items |
| **Related docs** | 02-TRD §4 (API standards) · 05-Backend-Schema (tables, calculations) |

---

## 1. Basics

| Item | Value |
|---|---|
| Base URL | `http://localhost:3333/api/v1` (dev, Android emulator: `http://10.0.2.2:3333/api/v1`) · `https://api.<domain>/api/v1` (production) |
| Format | JSON request and response bodies, `Content-Type: application/json` |
| Auth | `Authorization: Bearer <token>` on every endpoint except those marked 🌐 |
| Language | `Accept-Language: en` (default) or `bn` (Bengali) on every request. See §1.6 |
| Keys | `snake_case` |
| Money | String with 2 decimals in responses (`"1500.00"`). Requests accept a number or a numeric string (`1500`, `"1500.50"`) |
| Business dates | `YYYY-MM-DD` (months `YYYY-MM`), no timezone. Show as is. See §1.7 |
| Timestamps | ISO-8601 in UTC (`2026-11-08T06:30:00.000Z`). Show in the device timezone. See §1.7 |
| Factory date headers | Every response: `X-Business-Date: 2026-11-08`, `X-Business-Timezone: Asia/Kolkata` |
| Booleans in query strings | `true` / `false` (also `1` / `0`) |
| IDs | Positive integers. A non-numeric `:id` returns `404 Route not found` |

### 1.1 Response envelope

Every response, success or error, has the same 4 keys:

```json
{
  "success": true,
  "status_code": 200,
  "message": "Customer fetched successfully",
  "data": {}
}
```

| Case | `data` |
|---|---|
| Single record | The object |
| Paginated list | `{ items, page, limit, total, last_page }` (+ extra keys on some lists, e.g. `period_total`, `totals`) |
| Action without a result (delete, logout) | `null` |
| Validation error (`422`) | `{ errors: [{ field, message }] }` (+ `existing_customer_id` for duplicate customer phones) |
| Other errors | `null` (or a small object, e.g. `{ tries_left }`) |

### 1.2 Pagination

List endpoints accept `page` (default `1`) and `limit` (default `20`, max `100`):

```json
{
  "success": true,
  "status_code": 200,
  "message": "Customers fetched successfully",
  "data": {
    "items": [
      "…"
    ],
    "page": 1,
    "limit": 20,
    "total": 134,
    "last_page": 7
  }
}
```

The app loads the next page while `page < last_page`.

### 1.3 Status codes

| Code | Meaning | `message` example |
|---|---|---|
| `200` | OK | `Sale fetched successfully` |
| `201` | Created | `Customer created successfully` |
| `400` | Business rule failed (show `message` to the user) | `Only a booked sale can be cancelled` |
| `401` | Missing/invalid token, or deactivated user → clear token, go to Login | `Unauthorized` · `Your account is deactivated` |
| `404` | Record or route not found | `Record not found` · `Route not found` |
| `409` | Conflict (record in use) | `Product is used in sales. Deactivate it instead` |
| `422` | Validation failed (show each error under its field) | `Validation failed` |
| `429` | Too many attempts (login, OTP) | `Too many attempts. Try again in 15 minute(s)` |
| `500` | Unexpected server error | `Something went wrong. Please try again` |

### 1.4 Common error responses

These apply to **every** authenticated endpoint and are not repeated below:

**401 · No token / invalid token**

```json
{
  "success": false,
  "status_code": 401,
  "message": "Unauthorized",
  "data": null
}
```

**404 · Record not found (any `:id`)**

```json
{
  "success": false,
  "status_code": 404,
  "message": "Record not found",
  "data": null
}
```

**404 · Unknown route**

```json
{
  "success": false,
  "status_code": 404,
  "message": "Route not found",
  "data": null
}
```

**500 · Server error** (in development the real error message is shown)

```json
{
  "success": false,
  "status_code": 500,
  "message": "Something went wrong. Please try again",
  "data": null
}
```

### 1.5 Rate limits

| Endpoint | Limit |
|---|---|
| `POST /auth/login` | 5 **failed** attempts per 15 min per IP + login, then blocked for 15 min |
| `POST /auth/forgot-password` | 3 requests per 15 min per IP + email |
| `POST /auth/verify-otp`, `POST /auth/reset-password` | 10 requests per 15 min per IP |

### 1.6 Localization (English / Bengali)

Send `Accept-Language: bn` to get every `message` (success, business errors, validation errors and field names) in Bengali, or `en` for English. Without the header, authenticated requests use the saved user language (`users.locale`, see `PUT /auth/preferences`) and public requests use English. Any other language falls back to English. The response has a `Content-Language: en|bn` header. Only the text changes: keys, `field` names in `errors`, numbers and amounts stay the same (Latin digits).

The examples in this document are in English. Bengali examples:

**400 · Wrong password**: `POST /api/v1/auth/login` with `Accept-Language: bn`

```json
{
  "success": false,
  "status_code": 400,
  "message": "ফোন/ইমেইল অথবা পাসওয়ার্ড ভুল",
  "data": null
}
```

**422 · Validation errors**: `POST /api/v1/users` with `Accept-Language: bn`

```json
{
  "success": false,
  "status_code": 422,
  "message": "তথ্যে ভুল আছে",
  "data": {
    "errors": [
      {
        "field": "phone",
        "message": "ফোন নম্বর সঠিক ফরম্যাটে নেই"
      },
      {
        "field": "password",
        "message": "পাসওয়ার্ড কমপক্ষে 6 অক্ষরের হতে হবে"
      }
    ]
  }
}
```

**400 · Business rule**: `POST /api/v1/sales` with `Accept-Language: bn`

```json
{
  "success": false,
  "status_code": 400,
  "message": "পেমেন্ট (₹1000.00) মোট দামের (₹65.00) বেশি হতে পারবে না",
  "data": null
}
```

**200 · Success (shortened)**: `GET /api/v1/products?limit=1` with `Accept-Language: bn`

```json
{
  "success": true,
  "status_code": 200,
  "message": "প্রোডাক্টের তালিকা পাওয়া গেছে",
  "data": {
    "items": [
      {
        "id": 2,
        "name": "Fly Ash Brick 9×4×2.5",
        "unit": "piece",
        "unit_label": null,
        "default_cost": "3.80",
        "default_price": "5.80",
        "notes": null,
        "is_active": true,
        "created_at": "2026-11-08T14:18:10.000Z",
        "updated_at": "2026-11-08T14:18:10.000Z",
        "margin": "2.00"
      }
    ],
    "page": 1,
    "limit": 1,
    "total": 5,
    "last_page": 5
  }
}
```

### 1.7 Dates and time

| Kind | Fields | Format | How the app shows it |
|---|---|---|---|
| **Timestamp** (when it happened) | `created_at`, `updated_at`, `last_login_at`, `cancelled_at` | `2026-11-08T14:22:18.000Z` (UTC) | Convert to the **device** timezone (`toLocal()`) |
| **Business date** (which day it counts for) | `sale_date`, `delivery_date`, `delivered_date`, `payment_date`, `date`, `expense_date`, `advance_date`, `joining_date`, `left_date`, `wage_month` | `2026-11-08` / `2026-11` | Show **as is**. Never convert to another timezone |

- **Today = the factory day** (`Asia/Kolkata`), which changes at midnight IST. All "today" defaults on the server (sale date, payment date, attendance date, expense date, report ranges) and all "cannot be a future date" checks use it.
- **Every response** has `X-Business-Date` (the factory date) and `X-Business-Timezone`. Use `X-Business-Date` as the app default "today" instead of the device clock, so a phone in another timezone never sends a date the server rejects as future.
- **Reports, the dashboard and wages are based on business dates**, so the numbers are the same for every viewer in every timezone.

```http
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
Content-Language: en
X-Business-Date: 2026-11-08
X-Business-Timezone: Asia/Kolkata
```

---

## 2. Endpoint index

| # | Method | Path | Auth | Purpose |
|---|---|---|---|---|
| 1 | `GET` | [`/health`](#get-health) | 🌐 | Health check |
| 2 | `GET` | [`/app/version`](#get-appversion) | 🌐 | Check for an app update |
| 3 | `POST` | [`/auth/login`](#post-authlogin) | 🌐 | Login |
| 4 | `POST` | [`/auth/logout`](#post-authlogout) | 🔒 | Logout |
| 5 | `GET` | [`/auth/me`](#get-authme) | 🔒 | My profile |
| 6 | `PUT` | [`/auth/me`](#put-authme) | 🔒 | Edit my profile |
| 7 | `PUT` | [`/auth/password`](#put-authpassword) | 🔒 | Change my password |
| 8 | `PUT` | [`/auth/preferences`](#put-authpreferences) | 🔒 | Save my language and theme |
| 9 | `POST` | [`/auth/forgot-password`](#post-authforgot-password) | 🌐 | ① Send OTP |
| 10 | `POST` | [`/auth/verify-otp`](#post-authverify-otp) | 🌐 | ② Verify OTP |
| 11 | `POST` | [`/auth/reset-password`](#post-authreset-password) | 🌐 | ③ Set new password |
| 12 | `GET` | [`/users`](#get-users) | 🔒 | List users |
| 13 | `POST` | [`/users`](#post-users) | 🔒 | Add a user |
| 14 | `GET` | [`/users/:id`](#get-usersid) | 🔒 | Get a user |
| 15 | `PUT` | [`/users/:id`](#put-usersid) | 🔒 | Edit a user |
| 16 | `PATCH` | [`/users/:id/status`](#patch-usersidstatus) | 🔒 | Activate / deactivate a user |
| 17 | `PUT` | [`/users/:id/password`](#put-usersidpassword) | 🔒 | Reset a user's password |
| 18 | `GET` | [`/products`](#get-products) | 🔒 | List products |
| 19 | `POST` | [`/products`](#post-products) | 🔒 | Add a product |
| 20 | `GET` | [`/products/:id`](#get-productsid) | 🔒 | Get a product |
| 21 | `PUT` | [`/products/:id`](#put-productsid) | 🔒 | Edit a product |
| 22 | `PATCH` | [`/products/:id/status`](#patch-productsidstatus) | 🔒 | Activate / deactivate |
| 23 | `DELETE` | [`/products/:id`](#delete-productsid) | 🔒 | Delete a product |
| 24 | `GET` | [`/customers`](#get-customers) | 🔒 | List customers |
| 25 | `POST` | [`/customers`](#post-customers) | 🔒 | Add a customer |
| 26 | `GET` | [`/customers/:id`](#get-customersid) | 🔒 | Get a customer |
| 27 | `PUT` | [`/customers/:id`](#put-customersid) | 🔒 | Edit a customer |
| 28 | `PATCH` | [`/customers/:id/status`](#patch-customersidstatus) | 🔒 | Activate / deactivate |
| 29 | `DELETE` | [`/customers/:id`](#delete-customersid) | 🔒 | Delete a customer |
| 30 | `GET` | [`/customers/:id/sales`](#get-customersidsales) | 🔒 | A customer's sales |
| 31 | `GET` | [`/sales`](#get-sales) | 🔒 | List sales |
| 32 | `POST` | [`/sales`](#post-sales) | 🔒 | Create a sale or booking |
| 33 | `GET` | [`/sales/:id`](#get-salesid) | 🔒 | Get a sale |
| 34 | `PUT` | [`/sales/:id`](#put-salesid) | 🔒 | Edit a sale |
| 35 | `DELETE` | [`/sales/:id`](#delete-salesid) | 🔒 | Delete a sale |
| 36 | `POST` | [`/sales/:id/deliver`](#post-salesiddeliver) | 🔒 | Mark a booking as delivered |
| 37 | `POST` | [`/sales/:id/cancel`](#post-salesidcancel) | 🔒 | Cancel a booking |
| 38 | `POST` | [`/sales/:id/payments`](#post-salesidpayments) | 🔒 | Add a payment |
| 39 | `DELETE` | [`/sales/:id/payments/:paymentId`](#delete-salesidpaymentspaymentid) | 🔒 | Remove a payment |
| 40 | `GET` | [`/sales/upcoming-deliveries`](#get-salesupcoming-deliveries) | 🔒 | Upcoming deliveries |
| 41 | `GET` | [`/labours`](#get-labours) | 🔒 | List labours |
| 42 | `POST` | [`/labours`](#post-labours) | 🔒 | Add a labour |
| 43 | `GET` | [`/labours/:id`](#get-laboursid) | 🔒 | Get a labour |
| 44 | `PUT` | [`/labours/:id`](#put-laboursid) | 🔒 | Edit a labour |
| 45 | `PATCH` | [`/labours/:id/status`](#patch-laboursidstatus) | 🔒 | Activate / deactivate |
| 46 | `GET` | [`/attendance`](#get-attendance) | 🔒 | Attendance for a day |
| 47 | `PUT` | [`/attendance`](#put-attendance) | 🔒 | Save attendance for a day |
| 48 | `GET` | [`/labours/:id/attendance`](#get-laboursidattendance) | 🔒 | A labour's month calendar |
| 49 | `GET` | [`/wages`](#get-wages) | 🔒 | Monthly wage sheet |
| 50 | `GET` | [`/labours/:id/wages`](#get-laboursidwages) | 🔒 | A labour's wage detail |
| 51 | `GET` | [`/labours/:id/advances`](#get-laboursidadvances) | 🔒 | A labour's advances |
| 52 | `POST` | [`/labours/:id/advances`](#post-laboursidadvances) | 🔒 | Give an advance |
| 53 | `DELETE` | [`/advances/:id`](#delete-advancesid) | 🔒 | Delete an advance |
| 54 | `POST` | [`/labours/:id/wage-payments`](#post-laboursidwage-payments) | 🔒 | Pay wages |
| 55 | `DELETE` | [`/wage-payments/:id`](#delete-wage-paymentsid) | 🔒 | Delete a wage payment |
| 56 | `GET` | [`/expenses`](#get-expenses) | 🔒 | List expenses |
| 57 | `POST` | [`/expenses`](#post-expenses) | 🔒 | Add an expense |
| 58 | `GET` | [`/expenses/:id`](#get-expensesid) | 🔒 | Get an expense |
| 59 | `PUT` | [`/expenses/:id`](#put-expensesid) | 🔒 | Edit an expense |
| 60 | `DELETE` | [`/expenses/:id`](#delete-expensesid) | 🔒 | Delete an expense |
| 61 | `GET` | [`/expense-categories`](#get-expense-categories) | 🔒 | List categories |
| 62 | `POST` | [`/expense-categories`](#post-expense-categories) | 🔒 | Add a category |
| 63 | `PUT` | [`/expense-categories/:id`](#put-expense-categoriesid) | 🔒 | Edit / deactivate a category |
| 64 | `GET` | [`/dashboard`](#get-dashboard) | 🔒 | Dashboard |
| 65 | `GET` | [`/reports/sales`](#get-reportssales) | 🔒 | Sales report |
| 66 | `GET` | [`/reports/dues`](#get-reportsdues) | 🔒 | Dues report |
| 67 | `GET` | [`/reports/expenses`](#get-reportsexpenses) | 🔒 | Expense report |
| 68 | `GET` | [`/reports/wages`](#get-reportswages) | 🔒 | Wage report |
| 69 | `GET` | [`/reports/net-profit`](#get-reportsnet-profit) | 🔒 | Net profit report |
| 70 | `GET` | [`/reports/collections`](#get-reportscollections) | 🔒 | Collection report |
| 71 | `GET` | [`/settings/factory`](#get-settingsfactory) | 🔒 | Factory profile |
| 72 | `PUT` | [`/settings/factory`](#put-settingsfactory) | 🔒 | Edit factory profile |

**72 endpoints.** 🔒 = needs a Bearer token · 🌐 = public

---

## 3. Health & App version

Public endpoints (no token).

### GET /health

**Health check** · 🌐 Public

Returns `200` when the API and the database are reachable.

**Responses**

✅ **200 OK** · Healthy

```json
{
  "success": true,
  "status_code": 200,
  "message": "Healthy",
  "data": {
    "status": "ok",
    "db": "ok",
    "time": "2026-11-08T14:55:47.920Z"
  }
}
```

---

### GET /app/version

**Check for an app update** · 🌐 Public

Called on app launch and from Settings → About. `force_update` is `true` when the installed build is older than the minimum supported build.

**Query parameters**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `platform` | enum | yes | `android` · `windows` · `web` |
| `build` | integer | no | Installed build number (the `+N` in pubspec). Omit to just read the latest |

**Example request**

```http
GET /api/v1/app/version?platform=android&build=1
```

**Responses**

✅ **200 OK** · No release published yet

```json
{
  "success": true,
  "status_code": 200,
  "message": "No release published yet",
  "data": {
    "latest_version": null,
    "latest_build": null,
    "update_available": false,
    "force_update": false,
    "download_url": null,
    "release_notes": null
  }
}
```

❌ **422 Validation failed** · Invalid platform

```json
{
  "success": false,
  "status_code": 422,
  "message": "Validation failed",
  "data": {
    "errors": [
      {
        "field": "platform",
        "message": "The selected platform is invalid"
      }
    ]
  }
}
```

✅ **200 · Update available (example once a release is published)**

```json
{
  "success": true,
  "status_code": 200,
  "message": "Version info fetched",
  "data": {
    "latest_version": "1.2.0",
    "latest_build": 12,
    "update_available": true,
    "force_update": false,
    "download_url": "https://api.example.com/downloads/flyash-1.2.0.apk",
    "release_notes": "Sales report export added"
  }
}
```

---

## 4. Auth

Login returns an opaque token with **no expiry**. Send it as `Authorization: Bearer <token>`. It is revoked on logout, deactivation, or a password change/reset.

### POST /auth/login

**Login** · 🌐 Public

Log in with phone **or** email. 5 failed attempts per 15 minutes (per IP + login) block further tries with `429`.

**Request body**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `login` | string | yes | Phone (10 digits) or email |
| `password` | string | yes | — |
| `device_name` | string | no | Shown as the token name, e.g. "Android" |

**Example request**

```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "login": "9876543210",
  "password": "secret123",
  "device_name": "Android"
}
```

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Login successful",
  "data": {
    "token": "oat_MTI.ZE9BM3J5azhpVDJ6RHRKOUVyeEpBaVdOVzhMUTZiZWswMzJNTnowNTE0MjYwMTg1ODQ",
    "user": {
      "id": 1,
      "name": "Test Owner",
      "phone": "9876543210",
      "email": "owner@test.com",
      "locale": "en",
      "theme_mode": "system",
      "accent_color": "blue",
      "is_active": true,
      "last_login_at": "2026-11-08T14:55:46.446Z",
      "created_at": "2026-11-08T14:18:17.000Z",
      "updated_at": "2026-11-08T14:55:46.447Z"
    }
  }
}
```

❌ **400 Bad Request** · Wrong phone/email or password

<details><summary>Request body</summary>

```json
{
  "login": "9876543210",
  "password": "wrong"
}
```

</details>

```json
{
  "success": false,
  "status_code": 400,
  "message": "Invalid phone/email or password",
  "data": null
}
```

❌ **422 Validation failed** · Missing fields

<details><summary>Request body</summary>

```json
{}
```

</details>

```json
{
  "success": false,
  "status_code": 422,
  "message": "Validation failed",
  "data": {
    "errors": [
      {
        "field": "login",
        "message": "The phone or email field is required"
      },
      {
        "field": "password",
        "message": "The password field is required"
      }
    ]
  }
}
```

❌ **429 · Too many failed attempts**

```json
{
  "success": false,
  "status_code": 429,
  "message": "Too many attempts. Try again in 15 minute(s)",
  "data": null
}
```

---

### POST /auth/logout

**Logout** · 🔒 Bearer token

Revokes the current token only (other devices stay logged in).

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Logged out successfully",
  "data": null
}
```

❌ **401 Unauthorized** · Using the token after logout

```json
{
  "success": false,
  "status_code": 401,
  "message": "Unauthorized",
  "data": null
}
```

---

### GET /auth/me

**My profile** · 🔒 Bearer token

> A deactivated user gets `401` with message `Your account is deactivated`.

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Profile fetched successfully",
  "data": {
    "id": 1,
    "name": "Test Owner",
    "phone": "9876543210",
    "email": "owner@test.com",
    "locale": "en",
    "theme_mode": "system",
    "accent_color": "blue",
    "is_active": true,
    "last_login_at": "2026-11-08T14:55:46.000Z",
    "created_at": "2026-11-08T14:18:17.000Z",
    "updated_at": "2026-11-08T14:55:46.000Z"
  }
}
```

❌ **401 Unauthorized** · No token

```json
{
  "success": false,
  "status_code": 401,
  "message": "Unauthorized",
  "data": null
}
```

❌ **401 Unauthorized** · Invalid token

```json
{
  "success": false,
  "status_code": 401,
  "message": "Unauthorized",
  "data": null
}
```

---

### PUT /auth/me

**Edit my profile** · 🔒 Bearer token

**Request body**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `name` | string | yes | 1–100 chars |
| `phone` | string | yes | 10 digits, starts with 6–9, unique |
| `email` | string \| null | no | Valid email, unique. `null` clears it |

**Example request**

```http
PUT /api/v1/auth/me
Content-Type: application/json

{
  "name": "Test Owner",
  "phone": "9876543210",
  "email": "owner@test.com"
}
```

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Profile updated successfully",
  "data": {
    "id": 1,
    "name": "Test Owner",
    "phone": "9876543210",
    "email": "owner@test.com",
    "locale": "en",
    "theme_mode": "system",
    "accent_color": "blue",
    "is_active": true,
    "last_login_at": "2026-11-08T14:55:46.000Z",
    "created_at": "2026-11-08T14:18:17.000Z",
    "updated_at": "2026-11-08T14:55:46.000Z"
  }
}
```

❌ **422 Validation failed** · Validation errors

<details><summary>Request body</summary>

```json
{
  "name": "",
  "phone": "12345",
  "email": "not-an-email"
}
```

</details>

```json
{
  "success": false,
  "status_code": 422,
  "message": "Validation failed",
  "data": {
    "errors": [
      {
        "field": "name",
        "message": "The name field is required"
      },
      {
        "field": "phone",
        "message": "The phone field format is invalid"
      },
      {
        "field": "email",
        "message": "The email field must be a valid email address"
      }
    ]
  }
}
```

---

### PUT /auth/password

**Change my password** · 🔒 Bearer token

Logs out all **other** devices; the current device stays logged in.

**Request body**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `current_password` | string | yes | — |
| `password` | string | yes | 6–64 chars |
| `password_confirmation` | string | yes | Must equal `password` |

**Example request**

```http
PUT /api/v1/auth/password
Content-Type: application/json

{
  "current_password": "secret123",
  "password": "secret123",
  "password_confirmation": "secret123"
}
```

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Password changed. Other devices were logged out",
  "data": null
}
```

❌ **422 Validation failed** · Wrong current password

<details><summary>Request body</summary>

```json
{
  "current_password": "nope",
  "password": "secret123",
  "password_confirmation": "secret123"
}
```

</details>

```json
{
  "success": false,
  "status_code": 422,
  "message": "Validation failed",
  "data": {
    "errors": [
      {
        "field": "current_password",
        "message": "Current password is incorrect"
      }
    ]
  }
}
```

❌ **422 Validation failed** · Confirmation does not match

<details><summary>Request body</summary>

```json
{
  "current_password": "secret123",
  "password": "abcdef",
  "password_confirmation": "abcdeg"
}
```

</details>

```json
{
  "success": false,
  "status_code": 422,
  "message": "Validation failed",
  "data": {
    "errors": [
      {
        "field": "password_confirmation",
        "message": "The password and password confirmation fields must match"
      }
    ]
  }
}
```

---

### PUT /auth/preferences

**Save my language and theme** · 🔒 Bearer token

Saves the language and appearance to the account (`users.locale`, `users.theme_mode`, `users.accent_color`), so they follow the user to every device. Only the fields sent are changed. The locale is also used for emails and for API messages when a request has no `Accept-Language` header; when `locale` changes, the response is already in the new language.

**Request body**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `locale` | enum | no | `en` · `bn` |
| `theme_mode` | enum | no | `system` · `light` · `dark` |
| `accent_color` | enum | no | `blue` · `brick` · `emerald` · `violet` · `slate` |

**Example request**

```http
PUT /api/v1/auth/preferences
Content-Type: application/json

{
  "theme_mode": "dark",
  "accent_color": "emerald"
}
```

**Responses**

✅ **200 OK** · Theme mode and color saved

```json
{
  "success": true,
  "status_code": 200,
  "message": "Preferences saved",
  "data": {
    "id": 1,
    "name": "Test Owner",
    "phone": "9876543210",
    "email": "owner@test.com",
    "locale": "en",
    "theme_mode": "dark",
    "accent_color": "emerald",
    "is_active": true,
    "last_login_at": "2026-11-08T14:55:46.000Z",
    "created_at": "2026-11-08T14:18:17.000Z",
    "updated_at": "2026-11-08T14:55:46.537Z"
  }
}
```

✅ **200 OK** · Language saved (answer in Bengali)

```json
{
  "success": true,
  "status_code": 200,
  "message": "পছন্দ সেভ হয়েছে",
  "data": {
    "id": 1,
    "name": "Test Owner",
    "phone": "9876543210",
    "email": "owner@test.com",
    "locale": "bn",
    "theme_mode": "dark",
    "accent_color": "emerald",
    "is_active": true,
    "last_login_at": "2026-11-08T14:55:46.000Z",
    "created_at": "2026-11-08T14:18:17.000Z",
    "updated_at": "2026-11-08T14:55:46.543Z"
  }
}
```

❌ **422 Validation failed** · Invalid values

<details><summary>Request body</summary>

```json
{
  "locale": "fr",
  "theme_mode": "blue",
  "accent_color": "pink"
}
```

</details>

```json
{
  "success": false,
  "status_code": 422,
  "message": "Validation failed",
  "data": {
    "errors": [
      {
        "field": "locale",
        "message": "The selected language is invalid"
      },
      {
        "field": "theme_mode",
        "message": "The selected theme mode is invalid"
      },
      {
        "field": "accent_color",
        "message": "The selected theme color is invalid"
      }
    ]
  }
}
```

---

## 5. Forgot password (email OTP)

3 steps, 3 screens: **send OTP → verify OTP (get `reset_token`) → set new password**. The OTP is valid for 10 minutes and 5 tries; the `reset_token` is signed, valid for 10 minutes and single use. In development the OTP is printed in the API console.

### POST /auth/forgot-password

**① Send OTP** · 🌐 Public

Always returns the same `200` message (even for unknown emails). Limit: 3 requests per 15 minutes per IP + email.

**Request body**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `email` | string | yes | Valid email |

**Example request**

```http
POST /api/v1/auth/forgot-password
Content-Type: application/json

{
  "email": "owner@test.com"
}
```

**Responses**

✅ **200 OK** · Success (same for unknown emails)

```json
{
  "success": true,
  "status_code": 200,
  "message": "If this email is registered, an OTP has been sent",
  "data": null
}
```

❌ **422 Validation failed** · Invalid email

<details><summary>Request body</summary>

```json
{
  "email": "bad"
}
```

</details>

```json
{
  "success": false,
  "status_code": 422,
  "message": "Validation failed",
  "data": {
    "errors": [
      {
        "field": "email",
        "message": "The email field must be a valid email address"
      }
    ]
  }
}
```

---

### POST /auth/verify-otp

**② Verify OTP** · 🌐 Public

Returns a `reset_token` for step ③. After 5 wrong OTPs the OTP is deleted and a new one must be requested. Limit: 10 requests per 15 minutes per IP.

**Request body**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `email` | string | yes | — |
| `otp` | string | yes | Exactly 6 digits |

**Example request**

```http
POST /api/v1/auth/verify-otp
Content-Type: application/json

{
  "email": "owner@test.com",
  "otp": "485493"
}
```

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "OTP verified",
  "data": {
    "reset_token": "eyJtZXNzYWdlIjp7InVzZXJfaWQiOjEsIm90cF9pZCI6N30sInB1cnBvc2UiOiJwYXNzd29yZF9yZXNldCIsImV4cGlyeURhdGUiOiIyMDI2LTExLTA4VDE1OjA1OjQ2Ljc3OVoifQ.NCoKEyfV5cyEd2WBTIp3DOwN-1XWutKYv7gybOizeRs"
  }
}
```

❌ **400 Bad Request** · Wrong OTP (`data.tries_left`)

<details><summary>Request body</summary>

```json
{
  "email": "owner@test.com",
  "otp": "000000"
}
```

</details>

```json
{
  "success": false,
  "status_code": 400,
  "message": "Wrong OTP. 4 tries left",
  "data": {
    "tries_left": 4
  }
}
```

❌ **400 Bad Request** · No valid OTP for this email / expired

<details><summary>Request body</summary>

```json
{
  "email": "nobody@test.com",
  "otp": "123456"
}
```

</details>

```json
{
  "success": false,
  "status_code": 400,
  "message": "OTP is invalid or expired. Please request a new OTP",
  "data": null
}
```

❌ **422 Validation failed** · OTP not 6 digits

<details><summary>Request body</summary>

```json
{
  "email": "owner@test.com",
  "otp": "12"
}
```

</details>

```json
{
  "success": false,
  "status_code": 422,
  "message": "Validation failed",
  "data": {
    "errors": [
      {
        "field": "otp",
        "message": "The OTP field format is invalid"
      }
    ]
  }
}
```

❌ **400 · 5th wrong OTP**

```json
{
  "success": false,
  "status_code": 400,
  "message": "Too many wrong attempts. Please request a new OTP",
  "data": null
}
```

---

### POST /auth/reset-password

**③ Set new password** · 🌐 Public

Sets the password and logs the user out of **all** devices. The app then opens Login.

**Request body**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `reset_token` | string | yes | From step ② |
| `password` | string | yes | 6–64 chars |
| `password_confirmation` | string | yes | Must equal `password` |

**Example request**

```http
POST /api/v1/auth/reset-password
Content-Type: application/json

{
  "reset_token": "eyJtZXNzYWdlIjp7InVzZXJfaWQiOjEsIm90cF9pZCI6N30sInB1cnBvc2UiOiJwYXNzd29yZF9yZXNldCIsImV4cGlyeURhdGUiOiIyMDI2LTExLTA4VDE1OjA1OjQ2Ljc3OVoifQ.NCoKEyfV5cyEd2WBTIp3DOwN-1XWutKYv7gybOizeRs",
  "password": "secret123",
  "password_confirmation": "secret123"
}
```

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Password changed. Please log in",
  "data": null
}
```

❌ **400 Bad Request** · Invalid, expired or already used token

<details><summary>Request body</summary>

```json
{
  "reset_token": "abc.def",
  "password": "secret123",
  "password_confirmation": "secret123"
}
```

</details>

```json
{
  "success": false,
  "status_code": 400,
  "message": "Reset session expired. Please start again",
  "data": null
}
```

---

## 6. Users

All users are equal (no roles). These endpoints manage **other** users only: the logged-in user is never listed, and any `/users/:id` call with your own id returns `400`.

### GET /users

**List users** · 🔒 Bearer token

**Query parameters**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `page` | integer | no | ≥ 1, default `1` |
| `limit` | integer | no | 1–100, default `20` |
| `search` | string | no | Name or phone |
| `active` | boolean | no | `true` / `false` |

**Example request**

```http
GET /api/v1/users?page=1&limit=20&search=Mun
```

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Users fetched successfully",
  "data": {
    "items": [
      {
        "id": 6,
        "name": "Munshi Kalam",
        "phone": "9000074686",
        "email": "munshi746864@test.com",
        "locale": "bn",
        "theme_mode": "system",
        "accent_color": "blue",
        "is_active": true,
        "last_login_at": null,
        "created_at": "2026-11-08T14:55:46.000Z",
        "updated_at": "2026-11-08T14:55:46.000Z"
      },
      {
        "id": 2,
        "name": "Munshi Kalam Sheikh",
        "phone": "9000069860",
        "email": null,
        "locale": "en",
        "theme_mode": "system",
        "accent_color": "blue",
        "is_active": true,
        "last_login_at": null,
        "created_at": "2026-11-08T14:21:38.000Z",
        "updated_at": "2026-11-08T14:21:38.000Z"
      }
    ],
    "page": 1,
    "limit": 20,
    "total": 5,
    "last_page": 1
  }
}
```

---

### POST /users

**Add a user** · 🔒 Bearer token

**Request body**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `name` | string | yes | 1–100 chars |
| `phone` | string | yes | 10 digits, unique |
| `email` | string \| null | no | Unique. Needed for forgot-password |
| `password` | string | yes | 6–64 chars |

**Example request**

```http
POST /api/v1/users
Content-Type: application/json

{
  "name": "Munshi Kalam",
  "phone": "9000074686",
  "email": "munshi746864@test.com",
  "password": "secret123",
  "locale": "bn"
}
```

**Responses**

✅ **201 Created** · Created

```json
{
  "success": true,
  "status_code": 201,
  "message": "User created successfully",
  "data": {
    "id": 6,
    "name": "Munshi Kalam",
    "phone": "9000074686",
    "email": "munshi746864@test.com",
    "locale": "bn",
    "theme_mode": "system",
    "accent_color": "blue",
    "is_active": true,
    "last_login_at": null,
    "created_at": "2026-11-08T14:55:46.000Z",
    "updated_at": "2026-11-08T14:55:46.000Z"
  }
}
```

❌ **422 Validation failed** · Validation errors

<details><summary>Request body</summary>

```json
{
  "name": "X",
  "phone": "9876543210",
  "password": "123"
}
```

</details>

```json
{
  "success": false,
  "status_code": 422,
  "message": "Validation failed",
  "data": {
    "errors": [
      {
        "field": "phone",
        "message": "This phone is already taken"
      },
      {
        "field": "password",
        "message": "The password field must have at least 6 characters"
      }
    ]
  }
}
```

---

### GET /users/:id

**Get a user** · 🔒 Bearer token

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "User fetched successfully",
  "data": {
    "id": 6,
    "name": "Munshi Kalam",
    "phone": "9000074686",
    "email": "munshi746864@test.com",
    "locale": "bn",
    "theme_mode": "system",
    "accent_color": "blue",
    "is_active": true,
    "last_login_at": null,
    "created_at": "2026-11-08T14:55:46.000Z",
    "updated_at": "2026-11-08T14:55:46.000Z"
  }
}
```

❌ **400 Bad Request** · Your own id

```json
{
  "success": false,
  "status_code": 400,
  "message": "Use My Profile to change your own details",
  "data": null
}
```

❌ **404 Not Found** · Not found

```json
{
  "success": false,
  "status_code": 404,
  "message": "Record not found",
  "data": null
}
```

---

### PUT /users/:id

**Edit a user** · 🔒 Bearer token

**Request body**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `name` | string | yes | — |
| `phone` | string | yes | Unique |
| `email` | string \| null | no | Unique |

**Example request**

```http
PUT /api/v1/users/6
Content-Type: application/json

{
  "name": "Munshi Kalam Sheikh",
  "phone": "9000074686",
  "email": null
}
```

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "User updated successfully",
  "data": {
    "id": 6,
    "name": "Munshi Kalam Sheikh",
    "phone": "9000074686",
    "email": null,
    "locale": "bn",
    "theme_mode": "system",
    "accent_color": "blue",
    "is_active": true,
    "last_login_at": null,
    "created_at": "2026-11-08T14:55:46.000Z",
    "updated_at": "2026-11-08T14:55:46.947Z"
  }
}
```

---

### PATCH /users/:id/status

**Activate / deactivate a user** · 🔒 Bearer token

Deactivating logs the user out of all devices.

**Request body**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `is_active` | boolean | yes | — |

**Example request**

```http
PATCH /api/v1/users/6/status
Content-Type: application/json

{
  "is_active": false
}
```

**Responses**

✅ **200 OK** · Deactivated

```json
{
  "success": true,
  "status_code": 200,
  "message": "User deactivated",
  "data": {
    "id": 6,
    "name": "Munshi Kalam Sheikh",
    "phone": "9000074686",
    "email": null,
    "locale": "bn",
    "theme_mode": "system",
    "accent_color": "blue",
    "is_active": false,
    "last_login_at": null,
    "created_at": "2026-11-08T14:55:46.000Z",
    "updated_at": "2026-11-08T14:55:46.955Z"
  }
}
```

✅ **200 OK** · Activated

```json
{
  "success": true,
  "status_code": 200,
  "message": "User activated",
  "data": {
    "id": 6,
    "name": "Munshi Kalam Sheikh",
    "phone": "9000074686",
    "email": null,
    "locale": "bn",
    "theme_mode": "system",
    "accent_color": "blue",
    "is_active": true,
    "last_login_at": null,
    "created_at": "2026-11-08T14:55:46.000Z",
    "updated_at": "2026-11-08T14:55:46.961Z"
  }
}
```

---

### PUT /users/:id/password

**Reset a user's password** · 🔒 Bearer token

Logs that user out of all devices.

**Request body**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `password` | string | yes | 6–64 chars |
| `password_confirmation` | string | yes | — |

**Example request**

```http
PUT /api/v1/users/6/password
Content-Type: application/json

{
  "password": "newpass1",
  "password_confirmation": "newpass1"
}
```

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Password reset. The user was logged out of all devices",
  "data": null
}
```

---

## 7. Products

### GET /products

**List products** · 🔒 Bearer token

Active products first, then by name.

**Query parameters**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `page` | integer | no | ≥ 1, default `1` |
| `limit` | integer | no | 1–100, default `20` |
| `search` | string | no | Name |
| `active` | boolean | no | — |

**Example request**

```http
GET /api/v1/products?page=1&limit=20&search=Brick&active=true
```

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Products fetched successfully",
  "data": {
    "items": [
      {
        "id": 10,
        "name": "Fly Ash Brick 10x5x3 746864",
        "unit": "piece",
        "unit_label": null,
        "default_cost": "4.50",
        "default_price": "7.00",
        "notes": "Premium size",
        "is_active": true,
        "created_at": "2026-11-08T14:55:47.000Z",
        "updated_at": "2026-11-08T14:55:47.000Z",
        "margin": "2.50"
      },
      {
        "id": 2,
        "name": "Fly Ash Brick 9×4×2.5",
        "unit": "piece",
        "unit_label": null,
        "default_cost": "3.80",
        "default_price": "5.80",
        "notes": null,
        "is_active": true,
        "created_at": "2026-11-08T14:18:10.000Z",
        "updated_at": "2026-11-08T14:18:10.000Z",
        "margin": "2.00"
      }
    ],
    "page": 1,
    "limit": 20,
    "total": 3,
    "last_page": 1
  }
}
```

---

### POST /products

**Add a product** · 🔒 Bearer token

**Request body**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `name` | string | yes | 1–100 chars, unique |
| `unit` | enum | yes | `piece` · `thousand` · `truck` · `other` |
| `unit_label` | string | when unit = other | max 30, e.g. "cft" |
| `default_cost` | money | yes | ≥ 0, 2 decimals |
| `default_price` | money | yes | ≥ 0, 2 decimals |
| `notes` | string \| null | no | max 500 |

**Example request**

```http
POST /api/v1/products
Content-Type: application/json

{
  "name": "Fly Ash Brick 10x5x3 746864",
  "unit": "piece",
  "default_cost": 4.5,
  "default_price": "7.00",
  "notes": "Premium size"
}
```

**Responses**

✅ **201 Created** · Created (`margin` = price − cost)

```json
{
  "success": true,
  "status_code": 201,
  "message": "Product created successfully",
  "data": {
    "id": 10,
    "name": "Fly Ash Brick 10x5x3 746864",
    "unit": "piece",
    "unit_label": null,
    "default_cost": "4.50",
    "default_price": "7.00",
    "notes": "Premium size",
    "is_active": true,
    "created_at": "2026-11-08T14:55:47.000Z",
    "updated_at": "2026-11-08T14:55:47.000Z",
    "margin": "2.50"
  }
}
```

❌ **422 Validation failed** · Validation errors

<details><summary>Request body</summary>

```json
{
  "name": "Fly Ash Brick 9×4×3",
  "unit": "other",
  "default_cost": -1,
  "default_price": "abc"
}
```

</details>

```json
{
  "success": false,
  "status_code": 422,
  "message": "Validation failed",
  "data": {
    "errors": [
      {
        "field": "name",
        "message": "This name is already taken"
      },
      {
        "field": "unit_label",
        "message": "The unit label field is required"
      },
      {
        "field": "default_cost",
        "message": "The default cost field must be at least 0"
      },
      {
        "field": "default_price",
        "message": "The default price field must be a number"
      }
    ]
  }
}
```

---

### GET /products/:id

**Get a product** · 🔒 Bearer token

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Product fetched successfully",
  "data": {
    "id": 10,
    "name": "Fly Ash Brick 10x5x3 746864",
    "unit": "piece",
    "unit_label": null,
    "default_cost": "4.50",
    "default_price": "7.00",
    "notes": "Premium size",
    "is_active": true,
    "created_at": "2026-11-08T14:55:47.000Z",
    "updated_at": "2026-11-08T14:55:47.000Z",
    "margin": "2.50"
  }
}
```

---

### PUT /products/:id

**Edit a product** · 🔒 Bearer token

Same body as create. Old sales keep their price snapshot.

**Example request**

```http
PUT /api/v1/products/10
Content-Type: application/json

{
  "name": "Fly Ash Brick 10x5x3 746864",
  "unit": "thousand",
  "default_cost": 4500,
  "default_price": 7000
}
```

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Product updated successfully",
  "data": {
    "id": 10,
    "name": "Fly Ash Brick 10x5x3 746864",
    "unit": "thousand",
    "unit_label": null,
    "default_cost": "4500.00",
    "default_price": "7000.00",
    "notes": null,
    "is_active": true,
    "created_at": "2026-11-08T14:55:47.000Z",
    "updated_at": "2026-11-08T14:55:47.000Z",
    "margin": "2500.00"
  }
}
```

---

### PATCH /products/:id/status

**Activate / deactivate** · 🔒 Bearer token

Inactive products are hidden from the sale form but stay in old sales.

**Request body**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `is_active` | boolean | yes | — |

**Example request**

```http
PATCH /api/v1/products/10/status
Content-Type: application/json

{
  "is_active": false
}
```

**Responses**

✅ **200 OK** · Deactivated

```json
{
  "success": true,
  "status_code": 200,
  "message": "Product deactivated",
  "data": {
    "id": 10,
    "name": "Fly Ash Brick 10x5x3 746864",
    "unit": "thousand",
    "unit_label": null,
    "default_cost": "4500.00",
    "default_price": "7000.00",
    "notes": null,
    "is_active": false,
    "created_at": "2026-11-08T14:55:47.000Z",
    "updated_at": "2026-11-08T14:55:47.073Z",
    "margin": "2500.00"
  }
}
```

---

### DELETE /products/:id

**Delete a product** · 🔒 Bearer token

Only if the product was never used in a sale.

**Responses**

✅ **200 OK** · Deleted

```json
{
  "success": true,
  "status_code": 200,
  "message": "Product deleted successfully",
  "data": null
}
```

❌ **409 Conflict** · Used in sales

```json
{
  "success": false,
  "status_code": 409,
  "message": "Product is used in sales. Deactivate it instead",
  "data": null
}
```

---

## 8. Customers

Every customer response includes `total_sales`, `total_paid` and `total_due` (delivered, not deleted sales).

### GET /customers

**List customers** · 🔒 Bearer token

Newest first; with `has_due=true` sorted by highest due.

**Query parameters**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `page` | integer | no | ≥ 1, default `1` |
| `limit` | integer | no | 1–100, default `20` |
| `search` | string | no | Name or phone |
| `has_due` | boolean | no | Only customers with dues |
| `active` | boolean | no | — |

**Example request**

```http
GET /api/v1/customers?page=1&limit=20&search=Traders
```

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Customers fetched successfully",
  "data": {
    "items": [
      {
        "id": 1,
        "name": "Rahim Biswas Traders",
        "phone": "9830000000",
        "address": "Basirhat, North 24 Parganas",
        "is_active": true,
        "created_at": "2026-11-08T14:18:10.000Z",
        "updated_at": "2026-11-08T14:18:10.000Z",
        "total_sales": "222000.00",
        "total_paid": "100000.00",
        "total_due": "122000.00"
      },
      {
        "id": 5,
        "name": "Monirul Ghosh Traders",
        "phone": "9830031676",
        "address": "Habra, North 24 Parganas",
        "is_active": true,
        "created_at": "2026-11-08T14:18:10.000Z",
        "updated_at": "2026-11-08T14:18:10.000Z",
        "total_sales": "33098.00",
        "total_paid": "0.00",
        "total_due": "33098.00"
      }
    ],
    "page": 1,
    "limit": 20,
    "total": 8,
    "last_page": 1
  }
}
```

✅ **200 OK** · Customers with dues

```json
{
  "success": true,
  "status_code": 200,
  "message": "Customers fetched successfully",
  "data": {
    "items": [
      {
        "id": 1,
        "name": "Rahim Biswas Traders",
        "phone": "9830000000",
        "address": "Basirhat, North 24 Parganas",
        "is_active": true,
        "created_at": "2026-11-08T14:18:10.000Z",
        "updated_at": "2026-11-08T14:18:10.000Z",
        "total_sales": "222000.00",
        "total_paid": "100000.00",
        "total_due": "122000.00"
      },
      {
        "id": 29,
        "name": "Bikash Ghosh Traders",
        "phone": "9830221732",
        "address": "Ashoknagar, North 24 Parganas",
        "is_active": true,
        "created_at": "2026-11-08T14:18:10.000Z",
        "updated_at": "2026-11-08T14:18:10.000Z",
        "total_sales": "196634.00",
        "total_paid": "131669.00",
        "total_due": "64965.00"
      }
    ],
    "page": 1,
    "limit": 2,
    "total": 28,
    "last_page": 14
  }
}
```

---

### POST /customers

**Add a customer** · 🔒 Bearer token

**Request body**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `name` | string | yes | 1–100 chars |
| `phone` | string | yes | 10 digits, starts with 6–9, unique |
| `address` | string \| null | no | max 500 |

**Example request**

```http
POST /api/v1/customers
Content-Type: application/json

{
  "name": "Habib Enterprise",
  "phone": "9774686411",
  "address": "Barasat, North 24 Pgs"
}
```

**Responses**

✅ **201 Created** · Created

```json
{
  "success": true,
  "status_code": 201,
  "message": "Customer created successfully",
  "data": {
    "id": 43,
    "name": "Habib Enterprise",
    "phone": "9774686411",
    "address": "Barasat, North 24 Pgs",
    "is_active": true,
    "created_at": "2026-11-08T14:55:47.000Z",
    "updated_at": "2026-11-08T14:55:47.000Z",
    "total_sales": "0.00",
    "total_paid": "0.00",
    "total_due": "0.00"
  }
}
```

❌ **422 Validation failed** · Phone already used → `data.existing_customer_id`

<details><summary>Request body</summary>

```json
{
  "name": "Someone",
  "phone": "9774686411"
}
```

</details>

```json
{
  "success": false,
  "status_code": 422,
  "message": "Validation failed",
  "data": {
    "errors": [
      {
        "field": "phone",
        "message": "This phone belongs to Habib Enterprise"
      }
    ],
    "existing_customer_id": 43
  }
}
```

❌ **422 Validation failed** · Validation errors

<details><summary>Request body</summary>

```json
{
  "name": "",
  "phone": "123"
}
```

</details>

```json
{
  "success": false,
  "status_code": 422,
  "message": "Validation failed",
  "data": {
    "errors": [
      {
        "field": "name",
        "message": "The name field is required"
      },
      {
        "field": "phone",
        "message": "The phone field format is invalid"
      }
    ]
  }
}
```

---

### GET /customers/:id

**Get a customer** · 🔒 Bearer token

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Customer fetched successfully",
  "data": {
    "id": 1,
    "name": "Rahim Biswas Traders",
    "phone": "9830000000",
    "address": "Basirhat, North 24 Parganas",
    "is_active": true,
    "created_at": "2026-11-08T14:18:10.000Z",
    "updated_at": "2026-11-08T14:18:10.000Z",
    "total_sales": "222000.00",
    "total_paid": "100000.00",
    "total_due": "122000.00"
  }
}
```

---

### PUT /customers/:id

**Edit a customer** · 🔒 Bearer token

Same body as create.

**Example request**

```http
PUT /api/v1/customers/43
Content-Type: application/json

{
  "name": "Habib Enterprise",
  "phone": "9774686411",
  "address": "Habra"
}
```

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Customer updated successfully",
  "data": {
    "id": 43,
    "name": "Habib Enterprise",
    "phone": "9774686411",
    "address": "Habra",
    "is_active": true,
    "created_at": "2026-11-08T14:55:47.000Z",
    "updated_at": "2026-11-08T14:55:47.000Z",
    "total_sales": "0.00",
    "total_paid": "0.00",
    "total_due": "0.00"
  }
}
```

---

### PATCH /customers/:id/status

**Activate / deactivate** · 🔒 Bearer token

**Request body**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `is_active` | boolean | yes | — |

**Example request**

```http
PATCH /api/v1/customers/43/status
Content-Type: application/json

{
  "is_active": false
}
```

**Responses**

✅ **200 OK** · Deactivated

```json
{
  "success": true,
  "status_code": 200,
  "message": "Customer deactivated",
  "data": {
    "id": 43,
    "name": "Habib Enterprise",
    "phone": "9774686411",
    "address": "Habra",
    "is_active": false,
    "created_at": "2026-11-08T14:55:47.000Z",
    "updated_at": "2026-11-08T14:55:47.000Z",
    "total_sales": "0.00",
    "total_paid": "0.00",
    "total_due": "0.00"
  }
}
```

---

### DELETE /customers/:id

**Delete a customer** · 🔒 Bearer token

Only if the customer has no sales.

**Responses**

✅ **200 OK** · Deleted

```json
{
  "success": true,
  "status_code": 200,
  "message": "Customer deleted successfully",
  "data": null
}
```

❌ **409 Conflict** · Has sales

```json
{
  "success": false,
  "status_code": 409,
  "message": "Customer has sales. Deactivate them instead",
  "data": null
}
```

---

### GET /customers/:id/sales

**A customer's sales** · 🔒 Bearer token

**Query parameters**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `page` | integer | no | ≥ 1, default `1` |
| `limit` | integer | no | 1–100, default `20` |

**Example request**

```http
GET /api/v1/customers/1/sales?page=1&limit=2
```

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Customer sales fetched successfully",
  "data": {
    "items": [
      {
        "id": 98,
        "invoice_no": "INV-000098",
        "type": "instant",
        "status": "delivered",
        "customer_id": 1,
        "sale_date": "2026-11-08",
        "delivery_date": null,
        "delivered_date": "2026-11-08",
        "delivery_address": null,
        "subtotal": "39000.00",
        "transport_charge": "1500.00",
        "discount": "0.00",
        "total": "40500.00",
        "total_cost": "25200.00",
        "profit": "15300.00",
        "paid_amount": "10000.00",
        "due_amount": "30500.00",
        "payment_status": "partial",
        "notes": "Quantity increased",
        "cancelled_at": null,
        "created_at": "2026-11-08T14:52:23.000Z",
        "updated_at": "2026-11-08T14:52:23.000Z",
        "customer": {
          "id": 1,
          "name": "Rahim Biswas Traders",
          "phone": "9830000000"
        }
      },
      {
        "id": 92,
        "invoice_no": "INV-000092",
        "type": "instant",
        "status": "delivered",
        "customer_id": 1,
        "sale_date": "2026-11-08",
        "delivery_date": null,
        "delivered_date": "2026-11-08",
        "delivery_address": null,
        "subtotal": "39000.00",
        "transport_charge": "1500.00",
        "discount": "0.00",
        "total": "40500.00",
        "total_cost": "25200.00",
        "profit": "15300.00",
        "paid_amount": "10000.00",
        "due_amount": "30500.00",
        "payment_status": "partial",
        "notes": "Quantity increased",
        "cancelled_at": null,
        "created_at": "2026-11-08T14:47:49.000Z",
        "updated_at": "2026-11-08T14:47:50.000Z",
        "customer": {
          "id": 1,
          "name": "Rahim Biswas Traders",
          "phone": "9830000000"
        }
      }
    ],
    "page": 1,
    "limit": 2,
    "total": 5,
    "last_page": 3
  }
}
```

---

## 9. Sales

Types: **instant** (delivered now) and **booking** (delivered later). Status: `booked` → `delivered` or `cancelled`. Payment status: `due` · `partial` · `paid`.

All totals are calculated by the server: `subtotal = Σ qty × unit_price`, `total = subtotal + transport_charge − discount`, `profit = total − Σ qty × unit_cost`, `due_amount = total − paid_amount`. Unit cost/price are **snapshots** saved on each line.

### GET /sales

**List sales** · 🔒 Bearer token

Newest sale date first. Each item includes `customer { id, name, phone }`.

**Query parameters**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `page` | integer | no | ≥ 1, default `1` |
| `limit` | integer | no | 1–100, default `20` |
| `search` | string | no | Invoice no., customer name or phone |
| `type` | enum | no | `instant` · `booking` |
| `status` | enum | no | `paid` · `partial` · `due` (delivered sales by payment) · `booked` · `delivered` · `cancelled` |
| `from` | date | no | Sale date from |
| `to` | date | no | Sale date to |

**Example request**

```http
GET /api/v1/sales?page=1&limit=2
```

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Sales fetched successfully",
  "data": {
    "items": [
      {
        "id": 105,
        "invoice_no": "INV-000105",
        "type": "booking",
        "status": "booked",
        "customer_id": 45,
        "sale_date": "2026-11-08",
        "delivery_date": "2026-11-15",
        "delivered_date": null,
        "delivery_address": "Bongaon station road",
        "subtotal": "19500.00",
        "transport_charge": "0.00",
        "discount": "0.00",
        "total": "19500.00",
        "total_cost": "12600.00",
        "profit": "6900.00",
        "paid_amount": "5000.00",
        "due_amount": "14500.00",
        "payment_status": "partial",
        "notes": null,
        "cancelled_at": null,
        "created_at": "2026-11-08T14:55:47.000Z",
        "updated_at": "2026-11-08T14:55:47.000Z",
        "customer": {
          "id": 45,
          "name": "Nazrul Islam",
          "phone": "9574686433"
        }
      },
      {
        "id": 104,
        "invoice_no": "INV-000104",
        "type": "instant",
        "status": "delivered",
        "customer_id": 1,
        "sale_date": "2026-11-08",
        "delivery_date": null,
        "delivered_date": "2026-11-08",
        "delivery_address": null,
        "subtotal": "37000.00",
        "transport_charge": "1500.00",
        "discount": "500.00",
        "total": "38000.00",
        "total_cost": "23800.00",
        "profit": "14200.00",
        "paid_amount": "10000.00",
        "due_amount": "28000.00",
        "payment_status": "partial",
        "notes": "Deliver before noon",
        "cancelled_at": null,
        "created_at": "2026-11-08T14:55:47.000Z",
        "updated_at": "2026-11-08T14:55:47.000Z",
        "customer": {
          "id": 1,
          "name": "Rahim Biswas Traders",
          "phone": "9830000000"
        }
      }
    ],
    "page": 1,
    "limit": 2,
    "total": 90,
    "last_page": 45
  }
}
```

✅ **200 OK** · With filters

```json
{
  "success": true,
  "status_code": 200,
  "message": "Sales fetched successfully",
  "data": {
    "items": [
      {
        "id": 104,
        "invoice_no": "INV-000104",
        "type": "instant",
        "status": "delivered",
        "customer_id": 1,
        "sale_date": "2026-11-08",
        "delivery_date": null,
        "delivered_date": "2026-11-08",
        "delivery_address": null,
        "subtotal": "37000.00",
        "transport_charge": "1500.00",
        "discount": "500.00",
        "total": "38000.00",
        "total_cost": "23800.00",
        "profit": "14200.00",
        "paid_amount": "10000.00",
        "due_amount": "28000.00",
        "payment_status": "partial",
        "notes": "Deliver before noon",
        "cancelled_at": null,
        "created_at": "2026-11-08T14:55:47.000Z",
        "updated_at": "2026-11-08T14:55:47.000Z",
        "customer": {
          "id": 1,
          "name": "Rahim Biswas Traders",
          "phone": "9830000000"
        }
      },
      {
        "id": 98,
        "invoice_no": "INV-000098",
        "type": "instant",
        "status": "delivered",
        "customer_id": 1,
        "sale_date": "2026-11-08",
        "delivery_date": null,
        "delivered_date": "2026-11-08",
        "delivery_address": null,
        "subtotal": "39000.00",
        "transport_charge": "1500.00",
        "discount": "0.00",
        "total": "40500.00",
        "total_cost": "25200.00",
        "profit": "15300.00",
        "paid_amount": "10000.00",
        "due_amount": "30500.00",
        "payment_status": "partial",
        "notes": "Quantity increased",
        "cancelled_at": null,
        "created_at": "2026-11-08T14:52:23.000Z",
        "updated_at": "2026-11-08T14:52:23.000Z",
        "customer": {
          "id": 1,
          "name": "Rahim Biswas Traders",
          "phone": "9830000000"
        }
      }
    ],
    "page": 1,
    "limit": 2,
    "total": 5,
    "last_page": 3
  }
}
```

---

### POST /sales

**Create a sale or booking** · 🔒 Bearer token

**Request body**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `type` | enum | yes | `instant` · `booking` |
| `customer_id` | integer | one of | Existing customer |
| `new_customer` | object | one of | `{ name, phone, address? }`: creates the customer inline |
| `sale_date` | date | no | Default today, not in the future |
| `delivery_date` | date | booking | Required for bookings, ≥ sale_date |
| `delivery_address` | string \| null | no | max 500 |
| `items` | array | yes | 1–50 items |
| `items[].product_id` | integer | yes | Existing product |
| `items[].quantity` | number | yes | > 0, 2 decimals |
| `items[].unit_cost` | money | no | Default: product default cost |
| `items[].unit_price` | money | no | Default: product default price |
| `transport_charge` | money | no | Default 0 |
| `discount` | money | no | Default 0, ≤ subtotal + transport |
| `payment` | object | no | `{ amount, method?, note? }`: money received now (the advance for bookings), ≤ total |
| `notes` | string \| null | no | max 1000 |

**Example request**

```http
POST /api/v1/sales
Content-Type: application/json

{
  "type": "instant",
  "customer_id": 1,
  "items": [
    {
      "product_id": 1,
      "quantity": 5000
    },
    {
      "product_id": 3,
      "quantity": 100,
      "unit_price": "45.00"
    }
  ],
  "transport_charge": 1500,
  "discount": 500,
  "payment": {
    "amount": 10000,
    "method": "upi",
    "note": "Paid on spot"
  },
  "notes": "Deliver before noon"
}
```

**Responses**

✅ **201 Created** · Instant sale (full response)

```json
{
  "success": true,
  "status_code": 201,
  "message": "Sale saved successfully",
  "data": {
    "id": 104,
    "invoice_no": "INV-000104",
    "type": "instant",
    "status": "delivered",
    "customer_id": 1,
    "sale_date": "2026-11-08",
    "delivery_date": null,
    "delivered_date": "2026-11-08",
    "delivery_address": null,
    "subtotal": "37000.00",
    "transport_charge": "1500.00",
    "discount": "500.00",
    "total": "38000.00",
    "total_cost": "23800.00",
    "profit": "14200.00",
    "paid_amount": "10000.00",
    "due_amount": "28000.00",
    "payment_status": "partial",
    "notes": "Deliver before noon",
    "cancelled_at": null,
    "created_at": "2026-11-08T14:55:47.000Z",
    "updated_at": "2026-11-08T14:55:47.000Z",
    "customer": {
      "id": 1,
      "name": "Rahim Biswas Traders",
      "phone": "9830000000",
      "address": "Basirhat, North 24 Parganas"
    },
    "items": [
      {
        "id": 142,
        "sale_id": 104,
        "product_id": 1,
        "product_name": "Fly Ash Brick 9×4×3",
        "unit": "piece",
        "quantity": "5000.00",
        "unit_cost": "4.20",
        "unit_price": "6.50",
        "line_cost": "21000.00",
        "line_total": "32500.00",
        "created_at": "2026-11-08T14:55:47.000Z",
        "updated_at": "2026-11-08T14:55:47.000Z"
      },
      {
        "id": 143,
        "sale_id": 104,
        "product_id": 3,
        "product_name": "Hollow Block 16×8×8",
        "unit": "piece",
        "quantity": "100.00",
        "unit_cost": "28.00",
        "unit_price": "45.00",
        "line_cost": "2800.00",
        "line_total": "4500.00",
        "created_at": "2026-11-08T14:55:47.000Z",
        "updated_at": "2026-11-08T14:55:47.000Z"
      }
    ],
    "created_by": {
      "id": 1,
      "name": "Test Owner"
    },
    "payments": [
      {
        "id": 90,
        "sale_id": 104,
        "amount": "10000.00",
        "payment_date": "2026-11-08",
        "method": "upi",
        "note": "Paid on spot",
        "created_at": "2026-11-08T14:55:47.000Z",
        "updated_at": "2026-11-08T14:55:47.000Z",
        "created_by": {
          "id": 1,
          "name": "Test Owner"
        }
      }
    ]
  }
}
```

✅ **201 Created** · Booking with a new customer and an advance

```json
{
  "success": true,
  "status_code": 201,
  "message": "Sale saved successfully",
  "data": {
    "id": 105,
    "invoice_no": "INV-000105",
    "type": "booking",
    "status": "booked",
    "customer_id": 45,
    "sale_date": "2026-11-08",
    "delivery_date": "2026-11-15",
    "delivered_date": null,
    "delivery_address": "Bongaon station road",
    "subtotal": "19500.00",
    "transport_charge": "0.00",
    "discount": "0.00",
    "total": "19500.00",
    "total_cost": "12600.00",
    "profit": "6900.00",
    "paid_amount": "5000.00",
    "due_amount": "14500.00",
    "payment_status": "partial",
    "notes": null,
    "cancelled_at": null,
    "created_at": "2026-11-08T14:55:47.000Z",
    "updated_at": "2026-11-08T14:55:47.000Z",
    "customer": {
      "id": 45,
      "name": "Nazrul Islam",
      "phone": "9574686433",
      "address": "Bongaon"
    },
    "items": [
      {
        "id": 144,
        "sale_id": 105,
        "product_id": 1,
        "product_name": "Fly Ash Brick 9×4×3",
        "unit": "piece",
        "quantity": "3000.00",
        "unit_cost": "4.20",
        "unit_price": "6.50",
        "line_cost": "12600.00",
        "line_total": "19500.00",
        "created_at": "2026-11-08T14:55:47.000Z",
        "updated_at": "2026-11-08T14:55:47.000Z"
      }
    ],
    "created_by": {
      "id": 1,
      "name": "Test Owner"
    },
    "payments": [
      {
        "id": 91,
        "sale_id": 105,
        "amount": "5000.00",
        "payment_date": "2026-11-08",
        "method": "cash",
        "note": "Advance",
        "created_at": "2026-11-08T14:55:47.000Z",
        "updated_at": "2026-11-08T14:55:47.000Z",
        "created_by": {
          "id": 1,
          "name": "Test Owner"
        }
      }
    ]
  }
}
```

❌ **422 Validation failed** · Validation errors

<details><summary>Request body</summary>

```json
{
  "type": "gift",
  "items": [],
  "sale_date": "2099-01-01"
}
```

</details>

```json
{
  "success": false,
  "status_code": 422,
  "message": "Validation failed",
  "data": {
    "errors": [
      {
        "field": "type",
        "message": "The selected type is invalid"
      },
      {
        "field": "sale_date",
        "message": "The sale date field cannot be a future date"
      },
      {
        "field": "items",
        "message": "The items field must have at least 1 item(s)"
      }
    ]
  }
}
```

❌ **422 Validation failed** · Neither customer_id nor new_customer

<details><summary>Request body</summary>

```json
{
  "type": "instant",
  "items": [
    {
      "product_id": 1,
      "quantity": 10
    }
  ]
}
```

</details>

```json
{
  "success": false,
  "status_code": 422,
  "message": "Validation failed",
  "data": {
    "errors": [
      {
        "field": "customer_id",
        "message": "Select a customer or add a new one"
      }
    ]
  }
}
```

❌ **422 Validation failed** · new_customer phone already exists → `existing_customer_id`

<details><summary>Request body</summary>

```json
{
  "type": "instant",
  "new_customer": {
    "name": "X",
    "phone": "9774686411"
  },
  "items": [
    {
      "product_id": 1,
      "quantity": 10
    }
  ]
}
```

</details>

```json
{
  "success": false,
  "status_code": 422,
  "message": "Validation failed",
  "data": {
    "errors": [
      {
        "field": "new_customer.phone",
        "message": "This phone belongs to Habib Enterprise"
      }
    ],
    "existing_customer_id": 43
  }
}
```

❌ **422 Validation failed** · Booking without delivery_date

<details><summary>Request body</summary>

```json
{
  "type": "booking",
  "customer_id": 1,
  "items": [
    {
      "product_id": 1,
      "quantity": 10
    }
  ]
}
```

</details>

```json
{
  "success": false,
  "status_code": 422,
  "message": "Validation failed",
  "data": {
    "errors": [
      {
        "field": "delivery_date",
        "message": "Delivery date is required for a booking"
      }
    ]
  }
}
```

❌ **400 Bad Request** · Payment more than total

<details><summary>Request body</summary>

```json
{
  "type": "instant",
  "customer_id": 1,
  "items": [
    {
      "product_id": 1,
      "quantity": 10
    }
  ],
  "payment": {
    "amount": 1000
  }
}
```

</details>

```json
{
  "success": false,
  "status_code": 400,
  "message": "Payments (₹1000.00) cannot be more than the total (₹65.00)",
  "data": null
}
```

❌ **400 Bad Request** · Discount more than subtotal + transport

<details><summary>Request body</summary>

```json
{
  "type": "instant",
  "customer_id": 1,
  "items": [
    {
      "product_id": 1,
      "quantity": 10
    }
  ],
  "discount": 500
}
```

</details>

```json
{
  "success": false,
  "status_code": 400,
  "message": "Discount cannot be more than subtotal + transport charge",
  "data": null
}
```

---

### GET /sales/:id

**Get a sale** · 🔒 Bearer token

Full sale with `customer`, `items`, `payments` (each with `created_by`) and `created_by`.

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Sale fetched successfully",
  "data": {
    "id": 104,
    "invoice_no": "INV-000104",
    "type": "instant",
    "status": "delivered",
    "customer_id": 1,
    "sale_date": "2026-11-08",
    "delivery_date": null,
    "delivered_date": "2026-11-08",
    "delivery_address": null,
    "subtotal": "37000.00",
    "transport_charge": "1500.00",
    "discount": "500.00",
    "total": "38000.00",
    "total_cost": "23800.00",
    "profit": "14200.00",
    "paid_amount": "10000.00",
    "due_amount": "28000.00",
    "payment_status": "partial",
    "notes": "Deliver before noon",
    "cancelled_at": null,
    "created_at": "2026-11-08T14:55:47.000Z",
    "updated_at": "2026-11-08T14:55:47.000Z",
    "customer": {
      "id": 1,
      "name": "Rahim Biswas Traders",
      "phone": "9830000000",
      "address": "Basirhat, North 24 Parganas"
    },
    "items": [
      {
        "id": 142,
        "sale_id": 104,
        "product_id": 1,
        "product_name": "Fly Ash Brick 9×4×3",
        "unit": "piece",
        "quantity": "5000.00",
        "unit_cost": "4.20",
        "unit_price": "6.50",
        "line_cost": "21000.00",
        "line_total": "32500.00",
        "created_at": "2026-11-08T14:55:47.000Z",
        "updated_at": "2026-11-08T14:55:47.000Z"
      },
      {
        "id": 143,
        "sale_id": 104,
        "product_id": 3,
        "product_name": "Hollow Block 16×8×8",
        "unit": "piece",
        "quantity": "100.00",
        "unit_cost": "28.00",
        "unit_price": "45.00",
        "line_cost": "2800.00",
        "line_total": "4500.00",
        "created_at": "2026-11-08T14:55:47.000Z",
        "updated_at": "2026-11-08T14:55:47.000Z"
      }
    ],
    "created_by": {
      "id": 1,
      "name": "Test Owner"
    },
    "payments": [
      {
        "id": 90,
        "sale_id": 104,
        "amount": "10000.00",
        "payment_date": "2026-11-08",
        "method": "upi",
        "note": "Paid on spot",
        "created_at": "2026-11-08T14:55:47.000Z",
        "updated_at": "2026-11-08T14:55:47.000Z",
        "created_by": {
          "id": 1,
          "name": "Test Owner"
        }
      }
    ]
  }
}
```

❌ **404 Not Found** · Not found or deleted

```json
{
  "success": false,
  "status_code": 404,
  "message": "Record not found",
  "data": null
}
```

---

### PUT /sales/:id

**Edit a sale** · 🔒 Bearer token

Same body as create **without** `type` and `payment`. Items are replaced and totals recalculated. Rejected if the new total is less than what was already paid, or if the sale is cancelled.

**Example request**

```http
PUT /api/v1/sales/104
Content-Type: application/json

{
  "customer_id": 1,
  "items": [
    {
      "product_id": 1,
      "quantity": 6000
    }
  ],
  "transport_charge": 1500,
  "discount": 0,
  "notes": "Quantity increased"
}
```

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Sale updated successfully",
  "data": {
    "id": 104,
    "invoice_no": "INV-000104",
    "type": "instant",
    "status": "delivered",
    "customer_id": 1,
    "sale_date": "2026-11-08",
    "delivery_date": null,
    "delivered_date": "2026-11-08",
    "delivery_address": null,
    "subtotal": "39000.00",
    "transport_charge": "1500.00",
    "discount": "0.00",
    "total": "40500.00",
    "total_cost": "25200.00",
    "profit": "15300.00",
    "paid_amount": "10000.00",
    "due_amount": "30500.00",
    "payment_status": "partial",
    "notes": "Quantity increased",
    "cancelled_at": null,
    "created_at": "2026-11-08T14:55:47.000Z",
    "updated_at": "2026-11-08T14:55:47.000Z",
    "customer": {
      "id": 1,
      "name": "Rahim Biswas Traders",
      "phone": "9830000000",
      "address": "Basirhat, North 24 Parganas"
    },
    "items": [
      {
        "id": 147,
        "sale_id": 104,
        "product_id": 1,
        "product_name": "Fly Ash Brick 9×4×3",
        "unit": "piece",
        "quantity": "6000.00",
        "unit_cost": "4.20",
        "unit_price": "6.50",
        "line_cost": "25200.00",
        "line_total": "39000.00",
        "created_at": "2026-11-08T14:55:47.000Z",
        "updated_at": "2026-11-08T14:55:47.000Z"
      }
    ],
    "created_by": {
      "id": 1,
      "name": "Test Owner"
    },
    "payments": [
      {
        "id": 90,
        "sale_id": 104,
        "amount": "10000.00",
        "payment_date": "2026-11-08",
        "method": "upi",
        "note": "Paid on spot",
        "created_at": "2026-11-08T14:55:47.000Z",
        "updated_at": "2026-11-08T14:55:47.000Z",
        "created_by": {
          "id": 1,
          "name": "Test Owner"
        }
      }
    ]
  }
}
```

❌ **400 Bad Request** · New total below paid amount

<details><summary>Request body</summary>

```json
{
  "customer_id": 1,
  "items": [
    {
      "product_id": 1,
      "quantity": 10
    }
  ]
}
```

</details>

```json
{
  "success": false,
  "status_code": 400,
  "message": "Payments (₹10000.00) cannot be more than the total (₹65.00)",
  "data": null
}
```

❌ **400 Bad Request** · Cancelled sale

<details><summary>Request body</summary>

```json
{
  "customer_id": 1,
  "items": [
    {
      "product_id": 1,
      "quantity": 10
    }
  ]
}
```

</details>

```json
{
  "success": false,
  "status_code": 400,
  "message": "A cancelled sale cannot be edited",
  "data": null
}
```

---

### DELETE /sales/:id

**Delete a sale** · 🔒 Bearer token

Soft delete: removed from lists, totals and reports.

**Responses**

✅ **200 OK** · Deleted

```json
{
  "success": true,
  "status_code": 200,
  "message": "Sale deleted successfully",
  "data": null
}
```

---

### POST /sales/:id/deliver

**Mark a booking as delivered** · 🔒 Bearer token

**Request body**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `delivered_date` | date | no | Default today, ≥ sale date, not future |

**Example request**

```http
POST /api/v1/sales/105/deliver
Content-Type: application/json

{
  "delivered_date": "2026-11-08"
}
```

**Responses**

✅ **200 OK** · Delivered

```json
{
  "success": true,
  "status_code": 200,
  "message": "Marked as delivered",
  "data": {
    "id": 105,
    "invoice_no": "INV-000105",
    "type": "booking",
    "status": "delivered",
    "customer_id": 45,
    "sale_date": "2026-11-08",
    "delivery_date": "2026-11-15",
    "delivered_date": "2026-11-08",
    "delivery_address": "Bongaon station road",
    "subtotal": "19500.00",
    "transport_charge": "0.00",
    "discount": "0.00",
    "total": "19500.00",
    "total_cost": "12600.00",
    "profit": "6900.00",
    "paid_amount": "5000.00",
    "due_amount": "14500.00",
    "payment_status": "partial",
    "notes": null,
    "cancelled_at": null,
    "created_at": "2026-11-08T14:55:47.000Z",
    "updated_at": "2026-11-08T14:55:47.000Z",
    "customer": {
      "id": 45,
      "name": "Nazrul Islam",
      "phone": "9574686433",
      "address": "Bongaon"
    },
    "items": [
      {
        "id": 144,
        "sale_id": 105,
        "product_id": 1,
        "product_name": "Fly Ash Brick 9×4×3",
        "unit": "piece",
        "quantity": "3000.00",
        "unit_cost": "4.20",
        "unit_price": "6.50",
        "line_cost": "12600.00",
        "line_total": "19500.00",
        "created_at": "2026-11-08T14:55:47.000Z",
        "updated_at": "2026-11-08T14:55:47.000Z"
      }
    ],
    "created_by": {
      "id": 1,
      "name": "Test Owner"
    },
    "payments": [
      {
        "id": 91,
        "sale_id": 105,
        "amount": "5000.00",
        "payment_date": "2026-11-08",
        "method": "cash",
        "note": "Advance",
        "created_at": "2026-11-08T14:55:47.000Z",
        "updated_at": "2026-11-08T14:55:47.000Z",
        "created_by": {
          "id": 1,
          "name": "Test Owner"
        }
      }
    ]
  }
}
```

❌ **400 Bad Request** · Not a booked sale

<details><summary>Request body</summary>

```json
{}
```

</details>

```json
{
  "success": false,
  "status_code": 400,
  "message": "Only a booked sale can be marked as delivered",
  "data": null
}
```

---

### POST /sales/:id/cancel

**Cancel a booking** · 🔒 Bearer token

Only `booked` sales without payments.

**Responses**

✅ **200 OK** · Cancelled

```json
{
  "success": true,
  "status_code": 200,
  "message": "Booking cancelled",
  "data": {
    "id": 108,
    "invoice_no": "INV-000108",
    "type": "booking",
    "status": "cancelled",
    "customer_id": 1,
    "sale_date": "2026-11-08",
    "delivery_date": "2026-11-20",
    "delivered_date": null,
    "delivery_address": null,
    "subtotal": "650.00",
    "transport_charge": "0.00",
    "discount": "0.00",
    "total": "650.00",
    "total_cost": "420.00",
    "profit": "230.00",
    "paid_amount": "0.00",
    "due_amount": "650.00",
    "payment_status": "due",
    "notes": null,
    "cancelled_at": "2026-11-08T14:55:47.000Z",
    "created_at": "2026-11-08T14:55:47.000Z",
    "updated_at": "2026-11-08T14:55:47.000Z",
    "customer": {
      "id": 1,
      "name": "Rahim Biswas Traders",
      "phone": "9830000000",
      "address": "Basirhat, North 24 Parganas"
    },
    "items": [
      {
        "id": 149,
        "sale_id": 108,
        "product_id": 1,
        "product_name": "Fly Ash Brick 9×4×3",
        "unit": "piece",
        "quantity": "100.00",
        "unit_cost": "4.20",
        "unit_price": "6.50",
        "line_cost": "420.00",
        "line_total": "650.00",
        "created_at": "2026-11-08T14:55:47.000Z",
        "updated_at": "2026-11-08T14:55:47.000Z"
      }
    ],
    "payments": [],
    "created_by": {
      "id": 1,
      "name": "Test Owner"
    }
  }
}
```

❌ **400 Bad Request** · Booking has payments

```json
{
  "success": false,
  "status_code": 400,
  "message": "This booking has payments. Remove them first (refund), then cancel",
  "data": null
}
```

---

### POST /sales/:id/payments

**Add a payment** · 🔒 Bearer token

Returns the updated sale.

**Request body**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `amount` | money | yes | > 0, ≤ due amount |
| `payment_date` | date | no | Default today, ≥ sale date, not future |
| `method` | enum | no | `cash` (default) · `upi` · `bank` · `other` |
| `note` | string \| null | no | max 500 |

**Example request**

```http
POST /api/v1/sales/104/payments
Content-Type: application/json

{
  "amount": 5000,
  "payment_date": "2026-11-08",
  "method": "cash",
  "note": "2nd instalment"
}
```

**Responses**

✅ **200 OK** · Payment added

```json
{
  "success": true,
  "status_code": 200,
  "message": "Payment added",
  "data": {
    "id": 104,
    "invoice_no": "INV-000104",
    "type": "instant",
    "status": "delivered",
    "customer_id": 1,
    "sale_date": "2026-11-08",
    "delivery_date": null,
    "delivered_date": "2026-11-08",
    "delivery_address": null,
    "subtotal": "39000.00",
    "transport_charge": "1500.00",
    "discount": "0.00",
    "total": "40500.00",
    "total_cost": "25200.00",
    "profit": "15300.00",
    "paid_amount": "15000.00",
    "due_amount": "25500.00",
    "payment_status": "partial",
    "notes": "Quantity increased",
    "cancelled_at": null,
    "created_at": "2026-11-08T14:55:47.000Z",
    "updated_at": "2026-11-08T14:55:47.000Z",
    "customer": {
      "id": 1,
      "name": "Rahim Biswas Traders",
      "phone": "9830000000",
      "address": "Basirhat, North 24 Parganas"
    },
    "items": [
      {
        "id": 147,
        "sale_id": 104,
        "product_id": 1,
        "product_name": "Fly Ash Brick 9×4×3",
        "unit": "piece",
        "quantity": "6000.00",
        "unit_cost": "4.20",
        "unit_price": "6.50",
        "line_cost": "25200.00",
        "line_total": "39000.00",
        "created_at": "2026-11-08T14:55:47.000Z",
        "updated_at": "2026-11-08T14:55:47.000Z"
      }
    ],
    "created_by": {
      "id": 1,
      "name": "Test Owner"
    },
    "payments": [
      {
        "id": 90,
        "sale_id": 104,
        "amount": "10000.00",
        "payment_date": "2026-11-08",
        "method": "upi",
        "note": "Paid on spot",
        "created_at": "2026-11-08T14:55:47.000Z",
        "updated_at": "2026-11-08T14:55:47.000Z",
        "created_by": {
          "id": 1,
          "name": "Test Owner"
        }
      },
      {
        "id": 93,
        "sale_id": 104,
        "amount": "5000.00",
        "payment_date": "2026-11-08",
        "method": "cash",
        "note": "2nd instalment",
        "created_at": "2026-11-08T14:55:47.000Z",
        "updated_at": "2026-11-08T14:55:47.000Z",
        "created_by": {
          "id": 1,
          "name": "Test Owner"
        }
      }
    ]
  }
}
```

❌ **400 Bad Request** · More than the due amount

<details><summary>Request body</summary>

```json
{
  "amount": 99999999
}
```

</details>

```json
{
  "success": false,
  "status_code": 400,
  "message": "Payment cannot be more than the due amount (₹25500.00)",
  "data": null
}
```

---

### DELETE /sales/:id/payments/:paymentId

**Remove a payment** · 🔒 Bearer token

Returns the updated sale.

**Responses**

✅ **200 OK** · Removed

```json
{
  "success": true,
  "status_code": 200,
  "message": "Payment removed",
  "data": {
    "id": 104,
    "invoice_no": "INV-000104",
    "type": "instant",
    "status": "delivered",
    "customer_id": 1,
    "sale_date": "2026-11-08",
    "delivery_date": null,
    "delivered_date": "2026-11-08",
    "delivery_address": null,
    "subtotal": "39000.00",
    "transport_charge": "1500.00",
    "discount": "0.00",
    "total": "40500.00",
    "total_cost": "25200.00",
    "profit": "15300.00",
    "paid_amount": "10000.00",
    "due_amount": "30500.00",
    "payment_status": "partial",
    "notes": "Quantity increased",
    "cancelled_at": null,
    "created_at": "2026-11-08T14:55:47.000Z",
    "updated_at": "2026-11-08T14:55:47.000Z",
    "customer": {
      "id": 1,
      "name": "Rahim Biswas Traders",
      "phone": "9830000000",
      "address": "Basirhat, North 24 Parganas"
    },
    "items": [
      {
        "id": 147,
        "sale_id": 104,
        "product_id": 1,
        "product_name": "Fly Ash Brick 9×4×3",
        "unit": "piece",
        "quantity": "6000.00",
        "unit_cost": "4.20",
        "unit_price": "6.50",
        "line_cost": "25200.00",
        "line_total": "39000.00",
        "created_at": "2026-11-08T14:55:47.000Z",
        "updated_at": "2026-11-08T14:55:47.000Z"
      }
    ],
    "created_by": {
      "id": 1,
      "name": "Test Owner"
    },
    "payments": [
      {
        "id": 90,
        "sale_id": 104,
        "amount": "10000.00",
        "payment_date": "2026-11-08",
        "method": "upi",
        "note": "Paid on spot",
        "created_at": "2026-11-08T14:55:47.000Z",
        "updated_at": "2026-11-08T14:55:47.000Z",
        "created_by": {
          "id": 1,
          "name": "Test Owner"
        }
      }
    ]
  }
}
```

---

### GET /sales/upcoming-deliveries

**Upcoming deliveries** · 🔒 Bearer token

`booked` sales by delivery date (overdue first). Each item has `is_overdue`.

**Query parameters**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `page` | integer | no | ≥ 1, default `1` |
| `limit` | integer | no | 1–100, default `20` |

**Example request**

```http
GET /api/v1/sales/upcoming-deliveries?page=1&limit=2
```

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Upcoming deliveries fetched successfully",
  "data": {
    "items": [
      {
        "id": 63,
        "invoice_no": "INV-000063",
        "type": "booking",
        "status": "booked",
        "customer_id": 19,
        "sale_date": "2026-09-13",
        "delivery_date": "2026-09-16",
        "delivered_date": null,
        "delivery_address": null,
        "subtotal": "35418.00",
        "transport_charge": "0.00",
        "discount": "0.00",
        "total": "35418.00",
        "total_cost": "22894.00",
        "profit": "12524.00",
        "paid_amount": "14167.00",
        "due_amount": "21251.00",
        "payment_status": "partial",
        "notes": null,
        "cancelled_at": null,
        "created_at": "2026-11-08T14:18:12.000Z",
        "updated_at": "2026-11-08T14:18:12.000Z",
        "customer": {
          "id": 19,
          "name": "Rahim Roy",
          "phone": "9830142542"
        },
        "is_overdue": true
      },
      {
        "id": 58,
        "invoice_no": "INV-000058",
        "type": "booking",
        "status": "booked",
        "customer_id": 27,
        "sale_date": "2026-10-29",
        "delivery_date": "2026-11-03",
        "delivered_date": null,
        "delivery_address": null,
        "subtotal": "34032.00",
        "transport_charge": "800.00",
        "discount": "0.00",
        "total": "34832.00",
        "total_cost": "22256.00",
        "profit": "12576.00",
        "paid_amount": "0.00",
        "due_amount": "34832.00",
        "payment_status": "due",
        "notes": null,
        "cancelled_at": null,
        "created_at": "2026-11-08T14:18:12.000Z",
        "updated_at": "2026-11-08T14:18:12.000Z",
        "customer": {
          "id": 27,
          "name": "Monirul Das",
          "phone": "9830205894"
        },
        "is_overdue": true
      }
    ],
    "page": 1,
    "limit": 2,
    "total": 4,
    "last_page": 2
  }
}
```

---

## 10. Labours

### GET /labours

**List labours** · 🔒 Bearer token

Each item includes `today_status` (`present` · `half_day` · `absent` · `null`).

**Query parameters**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `page` | integer | no | ≥ 1, default `1` |
| `limit` | integer | no | 1–100, default `20` |
| `search` | string | no | Name or phone |
| `active` | boolean | no | — |

**Example request**

```http
GET /api/v1/labours?page=1&limit=2&active=true
```

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Labours fetched successfully",
  "data": {
    "items": [
      {
        "id": 9,
        "name": "Abdul Karim",
        "phone": "9120837832",
        "address": null,
        "wage_type": "daily",
        "wage_amount": "450.00",
        "joining_date": "2026-08-25",
        "left_date": null,
        "is_active": true,
        "created_at": "2026-11-08T14:18:12.000Z",
        "updated_at": "2026-11-08T14:18:12.000Z",
        "today_status": null
      },
      {
        "id": 12,
        "name": "Asit Roy",
        "phone": "9121152019",
        "address": null,
        "wage_type": "daily",
        "wage_amount": "550.00",
        "joining_date": "2026-08-25",
        "left_date": null,
        "is_active": true,
        "created_at": "2026-11-08T14:18:12.000Z",
        "updated_at": "2026-11-08T14:18:12.000Z",
        "today_status": null
      }
    ],
    "page": 1,
    "limit": 2,
    "total": 17,
    "last_page": 9
  }
}
```

---

### POST /labours

**Add a labour** · 🔒 Bearer token

**Request body**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `name` | string | yes | 1–100 chars |
| `phone` | string \| null | no | 10 digits |
| `address` | string \| null | no | — |
| `wage_type` | enum | yes | `daily` · `monthly` |
| `wage_amount` | money | yes | > 0 (₹ per day or per month) |
| `joining_date` | date | no | Default today |

**Example request**

```http
POST /api/v1/labours
Content-Type: application/json

{
  "name": "Motiur Rahaman",
  "phone": "9374686444",
  "address": "Habra",
  "wage_type": "daily",
  "wage_amount": 500,
  "joining_date": "2026-10-01"
}
```

**Responses**

✅ **201 Created** · Created

```json
{
  "success": true,
  "status_code": 201,
  "message": "Labour added successfully",
  "data": {
    "id": 17,
    "name": "Motiur Rahaman",
    "phone": "9374686444",
    "address": "Habra",
    "wage_type": "daily",
    "wage_amount": "500.00",
    "joining_date": "2026-10-01",
    "left_date": null,
    "is_active": true,
    "created_at": "2026-11-08T14:55:47.000Z",
    "updated_at": "2026-11-08T14:55:47.000Z",
    "today_status": null
  }
}
```

❌ **422 Validation failed** · Validation errors

<details><summary>Request body</summary>

```json
{
  "name": "",
  "wage_type": "weekly",
  "wage_amount": 0
}
```

</details>

```json
{
  "success": false,
  "status_code": 422,
  "message": "Validation failed",
  "data": {
    "errors": [
      {
        "field": "name",
        "message": "The name field is required"
      },
      {
        "field": "wage_type",
        "message": "The selected wage type is invalid"
      },
      {
        "field": "wage_amount",
        "message": "The wage amount field must be at least 0.01"
      }
    ]
  }
}
```

---

### GET /labours/:id

**Get a labour** · 🔒 Bearer token

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Labour fetched successfully",
  "data": {
    "id": 17,
    "name": "Motiur Rahaman",
    "phone": "9374686444",
    "address": "Habra",
    "wage_type": "daily",
    "wage_amount": "500.00",
    "joining_date": "2026-10-01",
    "left_date": null,
    "is_active": true,
    "created_at": "2026-11-08T14:55:47.000Z",
    "updated_at": "2026-11-08T14:55:47.000Z",
    "today_status": null
  }
}
```

---

### PUT /labours/:id

**Edit a labour** · 🔒 Bearer token

Same body as create. A new wage applies to attendance saved from now on; past days keep their wage snapshot.

**Example request**

```http
PUT /api/v1/labours/17
Content-Type: application/json

{
  "name": "Motiur Rahaman",
  "wage_type": "daily",
  "wage_amount": 550,
  "joining_date": "2026-10-01"
}
```

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Labour updated successfully",
  "data": {
    "id": 17,
    "name": "Motiur Rahaman",
    "phone": null,
    "address": null,
    "wage_type": "daily",
    "wage_amount": "550.00",
    "joining_date": "2026-10-01",
    "left_date": null,
    "is_active": true,
    "created_at": "2026-11-08T14:55:47.000Z",
    "updated_at": "2026-11-08T14:55:47.000Z",
    "today_status": null
  }
}
```

---

### PATCH /labours/:id/status

**Activate / deactivate** · 🔒 Bearer token

Deactivating sets `left_date`; the labour disappears from attendance after that date.

**Request body**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `is_active` | boolean | yes | — |
| `left_date` | date | no | When deactivating. Default today, ≥ joining date |

**Example request**

```http
PATCH /api/v1/labours/17/status
Content-Type: application/json

{
  "is_active": false,
  "left_date": "2026-11-08"
}
```

**Responses**

✅ **200 OK** · Deactivated

```json
{
  "success": true,
  "status_code": 200,
  "message": "Labour deactivated",
  "data": {
    "id": 17,
    "name": "Motiur Rahaman",
    "phone": null,
    "address": null,
    "wage_type": "daily",
    "wage_amount": "550.00",
    "joining_date": "2026-10-01",
    "left_date": "2026-11-08",
    "is_active": false,
    "created_at": "2026-11-08T14:55:47.000Z",
    "updated_at": "2026-11-08T14:55:47.000Z",
    "today_status": null
  }
}
```

✅ **200 OK** · Activated

```json
{
  "success": true,
  "status_code": 200,
  "message": "Labour activated",
  "data": {
    "id": 17,
    "name": "Motiur Rahaman",
    "phone": null,
    "address": null,
    "wage_type": "daily",
    "wage_amount": "550.00",
    "joining_date": "2026-10-01",
    "left_date": null,
    "is_active": true,
    "created_at": "2026-11-08T14:55:47.000Z",
    "updated_at": "2026-11-08T14:55:47.000Z",
    "today_status": null
  }
}
```

❌ **400 Bad Request** · Leaving date before joining date

<details><summary>Request body</summary>

```json
{
  "is_active": false,
  "left_date": "2026-09-01"
}
```

</details>

```json
{
  "success": false,
  "status_code": 400,
  "message": "Leaving date cannot be before the joining date",
  "data": null
}
```

---

## 11. Attendance

### GET /attendance

**Attendance for a day** · 🔒 Bearer token

All labours employed on that date with their saved status (`null` = not marked).

**Query parameters**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `date` | date | no | Default today, not future |

**Example request**

```http
GET /api/v1/attendance?date=2026-11-07
```

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Attendance fetched successfully",
  "data": {
    "date": "2026-11-07",
    "summary": {
      "total": 17,
      "present": 14,
      "half_day": 1,
      "absent": 0,
      "not_marked": 2
    },
    "items": [
      {
        "labour_id": 9,
        "name": "Abdul Karim",
        "wage_type": "daily",
        "wage_amount": "450.00",
        "status": "present"
      },
      {
        "labour_id": 12,
        "name": "Asit Roy",
        "wage_type": "daily",
        "wage_amount": "550.00",
        "status": "present"
      }
    ]
  }
}
```

---

### PUT /attendance

**Save attendance for a day** · 🔒 Bearer token

Saves many labours at once. A new row stores the labour's current wage as a snapshot; re-saving only changes the status. `status: null` clears the day ("not marked").

**Request body**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `date` | date | yes | Not future |
| `records` | array | yes | max 500 |
| `records[].labour_id` | integer | yes | Must be employed on that date |
| `records[].status` | enum \| null | yes | `present` · `half_day` · `absent` · `null` |

**Example request**

```http
PUT /api/v1/attendance
Content-Type: application/json

{
  "date": "2026-11-07",
  "records": [
    {
      "labour_id": 17,
      "status": "present"
    },
    {
      "labour_id": 1,
      "status": "half_day"
    },
    {
      "labour_id": 2,
      "status": null
    }
  ]
}
```

**Responses**

✅ **200 OK** · Saved (returns the day)

```json
{
  "success": true,
  "status_code": 200,
  "message": "Attendance saved for 2026-11-07",
  "data": {
    "date": "2026-11-07",
    "summary": {
      "total": 17,
      "present": 15,
      "half_day": 1,
      "absent": 0,
      "not_marked": 1
    },
    "items": [
      {
        "labour_id": 9,
        "name": "Abdul Karim",
        "wage_type": "daily",
        "wage_amount": "450.00",
        "status": "present"
      },
      {
        "labour_id": 12,
        "name": "Asit Roy",
        "wage_type": "daily",
        "wage_amount": "550.00",
        "status": "present"
      }
    ]
  }
}
```

❌ **422 Validation failed** · Future date

<details><summary>Request body</summary>

```json
{
  "date": "2099-01-01",
  "records": []
}
```

</details>

```json
{
  "success": false,
  "status_code": 422,
  "message": "Validation failed",
  "data": {
    "errors": [
      {
        "field": "date",
        "message": "The date field cannot be a future date"
      }
    ]
  }
}
```

❌ **400 Bad Request** · Labour not employed on that date

<details><summary>Request body</summary>

```json
{
  "date": "2026-09-01",
  "records": [
    {
      "labour_id": 17,
      "status": "present"
    }
  ]
}
```

</details>

```json
{
  "success": false,
  "status_code": 400,
  "message": "Labour(s) 17 were not employed on 2026-09-01",
  "data": null
}
```

---

### GET /labours/:id/attendance

**A labour's month calendar** · 🔒 Bearer token

**Query parameters**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `month` | YYYY-MM | no | Default current month |

**Example request**

```http
GET /api/v1/labours/17/attendance?month=2026-11
```

**Responses**

✅ **200 OK** · Success (days shortened here)

```json
{
  "success": true,
  "status_code": 200,
  "message": "Attendance fetched successfully",
  "data": {
    "labour_id": 17,
    "month": "2026-11",
    "days": [
      {
        "date": "2026-11-01",
        "status": null
      },
      {
        "date": "2026-11-02",
        "status": null
      }
    ],
    "summary": {
      "present": 1,
      "half_day": 0,
      "absent": 0
    }
  }
}
```

---

## 12. Wages & advances

Daily wage: `earned = worked_days × daily wage`. Monthly wage: `per day = monthly wage ÷ days in month`. Present = 1, half day = 0.5. `balance = earned − advances (given in the month) − paid (for the month)`. Status: `due` · `partial` · `paid`.

### GET /wages

**Monthly wage sheet** · 🔒 Bearer token

Every labour employed during the month, plus `month` and `totals` for the whole month.

**Query parameters**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `month` | YYYY-MM | no | Default current month |
| `page` | integer | no | ≥ 1, default `1` |
| `limit` | integer | no | 1–100, default `20` |
| `search` | string | no | Labour name |

**Example request**

```http
GET /api/v1/wages?month=2026-10&page=1&limit=2
```

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Wage sheet fetched successfully",
  "data": {
    "items": [
      {
        "labour_id": 9,
        "name": "Abdul Karim",
        "wage_type": "daily",
        "wage_amount": "450.00",
        "is_active": true,
        "present_days": 25,
        "half_days": 4,
        "absent_days": 2,
        "not_marked_days": 0,
        "worked_days": "27.00",
        "earned": "12150.00",
        "advances": "0.00",
        "paid": "0.00",
        "balance": "12150.00",
        "status": "due"
      },
      {
        "labour_id": 12,
        "name": "Asit Roy",
        "wage_type": "daily",
        "wage_amount": "550.00",
        "is_active": true,
        "present_days": 24,
        "half_days": 4,
        "absent_days": 3,
        "not_marked_days": 0,
        "worked_days": "26.00",
        "earned": "14300.00",
        "advances": "0.00",
        "paid": "0.00",
        "balance": "14300.00",
        "status": "due"
      }
    ],
    "page": 1,
    "limit": 2,
    "total": 17,
    "last_page": 9,
    "month": "2026-10",
    "totals": {
      "earned": "155062.91",
      "advances": "6000.00",
      "paid": "0.00",
      "balance": "149062.91"
    }
  }
}
```

---

### GET /labours/:id/wages

**A labour's wage detail** · 🔒 Bearer token

Wage row + `days` (each with `earned`), `advances` and `payments` of the month.

**Query parameters**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `month` | YYYY-MM | no | Default current month |

**Example request**

```http
GET /api/v1/labours/1/wages?month=2026-10
```

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Wage detail fetched successfully",
  "data": {
    "labour_id": 1,
    "name": "Kartik Mondal",
    "wage_type": "monthly",
    "wage_amount": "15000.00",
    "is_active": true,
    "present_days": 23,
    "half_days": 6,
    "absent_days": 2,
    "not_marked_days": 0,
    "worked_days": "26.00",
    "earned": "12580.65",
    "advances": [
      {
        "id": 2,
        "labour_id": 1,
        "amount": "500.00",
        "advance_date": "2026-10-31",
        "note": "Advance",
        "created_at": "2026-11-08T14:18:15.000Z",
        "updated_at": "2026-11-08T14:18:15.000Z",
        "created_by": null
      }
    ],
    "paid": "5000.00",
    "balance": "7080.65",
    "status": "partial",
    "month": "2026-10",
    "days": [
      {
        "date": "2026-10-01",
        "status": "present",
        "earned": "483.87"
      },
      {
        "date": "2026-10-02",
        "status": "present",
        "earned": "483.87"
      }
    ],
    "payments": [
      {
        "id": 5,
        "labour_id": 1,
        "wage_month": "2026-10-01",
        "amount": "5000.00",
        "payment_date": "2026-11-01",
        "method": "cash",
        "note": "October wages",
        "created_at": "2026-11-08T14:55:47.000Z",
        "updated_at": "2026-11-08T14:55:47.000Z",
        "created_by": {
          "id": 1,
          "name": "Test Owner"
        }
      }
    ]
  }
}
```

---

### GET /labours/:id/advances

**A labour's advances** · 🔒 Bearer token

**Query parameters**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `page` | integer | no | ≥ 1, default `1` |
| `limit` | integer | no | 1–100, default `20` |

**Example request**

```http
GET /api/v1/labours/1/advances?page=1&limit=2
```

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Advances fetched successfully",
  "data": {
    "items": [
      {
        "id": 15,
        "labour_id": 1,
        "amount": "1000.00",
        "advance_date": "2026-11-05",
        "note": "Medical",
        "created_at": "2026-11-08T14:55:47.000Z",
        "updated_at": "2026-11-08T14:55:47.000Z",
        "created_by": {
          "id": 1,
          "name": "Test Owner"
        }
      },
      {
        "id": 2,
        "labour_id": 1,
        "amount": "500.00",
        "advance_date": "2026-10-31",
        "note": "Advance",
        "created_at": "2026-11-08T14:18:15.000Z",
        "updated_at": "2026-11-08T14:18:15.000Z",
        "created_by": null
      }
    ],
    "page": 1,
    "limit": 2,
    "total": 2,
    "last_page": 1
  }
}
```

---

### POST /labours/:id/advances

**Give an advance** · 🔒 Bearer token

**Request body**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `amount` | money | yes | > 0 |
| `advance_date` | date | no | Default today, not future. Deducted in this month |
| `note` | string \| null | no | — |

**Example request**

```http
POST /api/v1/labours/1/advances
Content-Type: application/json

{
  "amount": 1000,
  "advance_date": "2026-11-05",
  "note": "Medical"
}
```

**Responses**

✅ **201 Created** · Created

```json
{
  "success": true,
  "status_code": 201,
  "message": "Advance recorded",
  "data": {
    "labour_id": 1,
    "amount": "1000.00",
    "advance_date": "2026-11-05",
    "note": "Medical",
    "created_at": "2026-11-08T14:55:47.603Z",
    "updated_at": "2026-11-08T14:55:47.603Z",
    "id": 15,
    "created_by": {
      "id": 1,
      "name": "Test Owner"
    }
  }
}
```

❌ **422 Validation failed** · Validation errors

<details><summary>Request body</summary>

```json
{
  "amount": 0,
  "advance_date": "2099-01-01"
}
```

</details>

```json
{
  "success": false,
  "status_code": 422,
  "message": "Validation failed",
  "data": {
    "errors": [
      {
        "field": "amount",
        "message": "The amount field must be at least 0.01"
      },
      {
        "field": "advance_date",
        "message": "The advance date field cannot be a future date"
      }
    ]
  }
}
```

---

### DELETE /advances/:id

**Delete an advance** · 🔒 Bearer token

**Responses**

✅ **200 OK** · Deleted

```json
{
  "success": true,
  "status_code": 200,
  "message": "Advance deleted",
  "data": null
}
```

---

### POST /labours/:id/wage-payments

**Pay wages** · 🔒 Bearer token

Partial payments are allowed.

**Request body**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `wage_month` | YYYY-MM | yes | Month being paid |
| `amount` | money | yes | > 0 |
| `payment_date` | date | no | Default today, not future |
| `method` | enum | no | `cash` (default) · `upi` · `bank` · `other` |
| `note` | string \| null | no | — |

**Example request**

```http
POST /api/v1/labours/1/wage-payments
Content-Type: application/json

{
  "wage_month": "2026-10",
  "amount": 5000,
  "payment_date": "2026-11-01",
  "method": "cash",
  "note": "October wages"
}
```

**Responses**

✅ **201 Created** · Created

```json
{
  "success": true,
  "status_code": 201,
  "message": "Wage payment recorded",
  "data": {
    "labour_id": 1,
    "wage_month": "2026-10-01",
    "amount": "5000.00",
    "payment_date": "2026-11-01",
    "method": "cash",
    "note": "October wages",
    "created_at": "2026-11-08T14:55:47.620Z",
    "updated_at": "2026-11-08T14:55:47.620Z",
    "id": 5,
    "created_by": {
      "id": 1,
      "name": "Test Owner"
    }
  }
}
```

❌ **422 Validation failed** · Validation errors

<details><summary>Request body</summary>

```json
{
  "wage_month": "2026-13",
  "amount": -5
}
```

</details>

```json
{
  "success": false,
  "status_code": 422,
  "message": "Validation failed",
  "data": {
    "errors": [
      {
        "field": "wage_month",
        "message": "The wage month field format is invalid"
      },
      {
        "field": "amount",
        "message": "The amount field must be at least 0.01"
      }
    ]
  }
}
```

---

### DELETE /wage-payments/:id

**Delete a wage payment** · 🔒 Bearer token

**Responses**

✅ **200 OK** · Deleted

```json
{
  "success": true,
  "status_code": 200,
  "message": "Wage payment deleted",
  "data": null
}
```

---

## 13. Expenses

### GET /expenses

**List expenses** · 🔒 Bearer token

Newest first, plus `period_total` for the filtered range (all pages).

**Query parameters**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `page` | integer | no | ≥ 1, default `1` |
| `limit` | integer | no | 1–100, default `20` |
| `from` | date | no | — |
| `to` | date | no | — |
| `category_id` | integer | no | — |
| `search` | string | no | Note |

**Example request**

```http
GET /api/v1/expenses?from=2026-11-01&to=2026-11-30&page=1&limit=2
```

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Expenses fetched successfully",
  "data": {
    "items": [
      {
        "id": 55,
        "expense_category_id": 1,
        "expense_date": "2026-11-08",
        "amount": "850.00",
        "note": "Tiffin for 15 labours",
        "created_at": "2026-11-08T14:55:47.000Z",
        "updated_at": "2026-11-08T14:55:47.000Z",
        "category": {
          "id": 1,
          "name": "Labour Tiffin",
          "icon": "utensils"
        },
        "created_by": {
          "id": 1,
          "name": "Test Owner"
        }
      },
      {
        "id": 35,
        "expense_category_id": 1,
        "expense_date": "2026-11-07",
        "amount": "2300.00",
        "note": "Tea and snacks",
        "created_at": "2026-11-08T14:18:15.000Z",
        "updated_at": "2026-11-08T14:18:15.000Z",
        "category": {
          "id": 1,
          "name": "Labour Tiffin",
          "icon": "utensils"
        },
        "created_by": null
      }
    ],
    "page": 1,
    "limit": 2,
    "total": 8,
    "last_page": 4,
    "period_total": "13750.00"
  }
}
```

---

### POST /expenses

**Add an expense** · 🔒 Bearer token

**Request body**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `expense_category_id` | integer | yes | Existing category |
| `expense_date` | date | no | Default today, not future |
| `amount` | money | yes | > 0 |
| `note` | string \| null | no | max 500 |

**Example request**

```http
POST /api/v1/expenses
Content-Type: application/json

{
  "expense_category_id": 1,
  "expense_date": "2026-11-08",
  "amount": 850,
  "note": "Tiffin for 15 labours"
}
```

**Responses**

✅ **201 Created** · Created

```json
{
  "success": true,
  "status_code": 201,
  "message": "Expense added",
  "data": {
    "id": 55,
    "expense_category_id": 1,
    "expense_date": "2026-11-08",
    "amount": "850.00",
    "note": "Tiffin for 15 labours",
    "created_at": "2026-11-08T14:55:47.000Z",
    "updated_at": "2026-11-08T14:55:47.000Z",
    "category": {
      "id": 1,
      "name": "Labour Tiffin",
      "icon": "utensils"
    },
    "created_by": {
      "id": 1,
      "name": "Test Owner"
    }
  }
}
```

❌ **422 Validation failed** · Validation errors

<details><summary>Request body</summary>

```json
{
  "expense_category_id": 999,
  "amount": 0,
  "expense_date": "2099-01-01"
}
```

</details>

```json
{
  "success": false,
  "status_code": 422,
  "message": "Validation failed",
  "data": {
    "errors": [
      {
        "field": "expense_category_id",
        "message": "The selected category does not exist"
      },
      {
        "field": "expense_date",
        "message": "The expense date field cannot be a future date"
      },
      {
        "field": "amount",
        "message": "The amount field must be at least 0.01"
      }
    ]
  }
}
```

---

### GET /expenses/:id

**Get an expense** · 🔒 Bearer token

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Expense fetched successfully",
  "data": {
    "id": 55,
    "expense_category_id": 1,
    "expense_date": "2026-11-08",
    "amount": "850.00",
    "note": "Tiffin for 15 labours",
    "created_at": "2026-11-08T14:55:47.000Z",
    "updated_at": "2026-11-08T14:55:47.000Z",
    "category": {
      "id": 1,
      "name": "Labour Tiffin",
      "icon": "utensils"
    },
    "created_by": {
      "id": 1,
      "name": "Test Owner"
    }
  }
}
```

---

### PUT /expenses/:id

**Edit an expense** · 🔒 Bearer token

Same body as create (`expense_date` keeps its value when omitted).

**Example request**

```http
PUT /api/v1/expenses/55
Content-Type: application/json

{
  "expense_category_id": 1,
  "amount": 900,
  "note": "Tiffin + tea"
}
```

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Expense updated",
  "data": {
    "id": 55,
    "expense_category_id": 1,
    "expense_date": "2026-11-08",
    "amount": "900.00",
    "note": "Tiffin + tea",
    "created_at": "2026-11-08T14:55:47.000Z",
    "updated_at": "2026-11-08T14:55:47.000Z",
    "category": {
      "id": 1,
      "name": "Labour Tiffin",
      "icon": "utensils"
    },
    "created_by": {
      "id": 1,
      "name": "Test Owner"
    }
  }
}
```

---

### DELETE /expenses/:id

**Delete an expense** · 🔒 Bearer token

**Responses**

✅ **200 OK** · Deleted

```json
{
  "success": true,
  "status_code": 200,
  "message": "Expense deleted",
  "data": null
}
```

---

### GET /expense-categories

**List categories** · 🔒 Bearer token

Small list, not paginated. Sorted by `sort_order`.

**Query parameters**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `active` | boolean | no | — |

**Example request**

```http
GET /api/v1/expense-categories?active=true
```

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Categories fetched successfully",
  "data": [
    {
      "id": 1,
      "name": "Labour Tiffin",
      "icon": "utensils",
      "is_active": true,
      "sort_order": 1,
      "created_at": "2026-11-08T14:18:10.000Z",
      "updated_at": "2026-11-08T14:18:10.000Z"
    },
    {
      "id": 2,
      "name": "Machine Repair",
      "icon": "wrench",
      "is_active": true,
      "sort_order": 2,
      "created_at": "2026-11-08T14:18:10.000Z",
      "updated_at": "2026-11-08T14:18:10.000Z"
    }
  ]
}
```

---

### POST /expense-categories

**Add a category** · 🔒 Bearer token

**Request body**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `name` | string | yes | 1–50 chars, unique |
| `icon` | string \| null | no | Icon key, e.g. `wrench` |
| `is_active` | boolean | no | Default true |
| `sort_order` | integer | no | Default: last |

**Example request**

```http
POST /api/v1/expense-categories
Content-Type: application/json

{
  "name": "Gate Pass 746864",
  "icon": "ticket"
}
```

**Responses**

✅ **201 Created** · Created

```json
{
  "success": true,
  "status_code": 201,
  "message": "Category created",
  "data": {
    "id": 11,
    "name": "Gate Pass 746864",
    "icon": "ticket",
    "is_active": true,
    "sort_order": 11,
    "created_at": "2026-11-08T14:55:47.000Z",
    "updated_at": "2026-11-08T14:55:47.000Z"
  }
}
```

❌ **422 Validation failed** · Name already exists

<details><summary>Request body</summary>

```json
{
  "name": "Labour Tiffin"
}
```

</details>

```json
{
  "success": false,
  "status_code": 422,
  "message": "Validation failed",
  "data": {
    "errors": [
      {
        "field": "name",
        "message": "This name is already taken"
      }
    ]
  }
}
```

---

### PUT /expense-categories/:id

**Edit / deactivate a category** · 🔒 Bearer token

Same body as create. Categories are never deleted; deactivate instead.

**Example request**

```http
PUT /api/v1/expense-categories/11
Content-Type: application/json

{
  "name": "Gate Pass 746864",
  "is_active": false
}
```

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Category updated",
  "data": {
    "id": 11,
    "name": "Gate Pass 746864",
    "icon": "ticket",
    "is_active": false,
    "sort_order": 11,
    "created_at": "2026-11-08T14:55:47.000Z",
    "updated_at": "2026-11-08T14:55:47.687Z"
  }
}
```

---

## 14. Dashboard & reports

Sales and profit count on the **delivered date**; collections on the **payment date**. `from`/`to` default to the 1st of the current month → today.

### GET /dashboard

**Dashboard** · 🔒 Bearer token

Every home-screen number in one call. `recent_sales` = last 5 sales.

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Dashboard fetched successfully",
  "data": {
    "date": "2026-11-08",
    "today_sales": {
      "amount": "313800.00",
      "count": 11
    },
    "today_profit": "116400.00",
    "total_due": "828316.00",
    "deliveries_today": 0,
    "overdue_deliveries": 2,
    "present_today": 0,
    "labours_total": 17,
    "month_expenses": "12900.00",
    "recent_sales": [
      {
        "id": 105,
        "invoice_no": "INV-000105",
        "type": "booking",
        "status": "delivered",
        "customer_id": 45,
        "sale_date": "2026-11-08",
        "delivery_date": "2026-11-15",
        "delivered_date": "2026-11-08",
        "delivery_address": "Bongaon station road",
        "subtotal": "19500.00",
        "transport_charge": "0.00",
        "discount": "0.00",
        "total": "19500.00",
        "total_cost": "12600.00",
        "profit": "6900.00",
        "paid_amount": "5000.00",
        "due_amount": "14500.00",
        "payment_status": "partial",
        "notes": null,
        "cancelled_at": null,
        "created_at": "2026-11-08T14:55:47.000Z",
        "updated_at": "2026-11-08T14:55:47.000Z",
        "customer": {
          "id": 45,
          "name": "Nazrul Islam",
          "phone": "9574686433"
        }
      },
      {
        "id": 104,
        "invoice_no": "INV-000104",
        "type": "instant",
        "status": "delivered",
        "customer_id": 1,
        "sale_date": "2026-11-08",
        "delivery_date": null,
        "delivered_date": "2026-11-08",
        "delivery_address": null,
        "subtotal": "39000.00",
        "transport_charge": "1500.00",
        "discount": "0.00",
        "total": "40500.00",
        "total_cost": "25200.00",
        "profit": "15300.00",
        "paid_amount": "10000.00",
        "due_amount": "30500.00",
        "payment_status": "partial",
        "notes": "Quantity increased",
        "cancelled_at": null,
        "created_at": "2026-11-08T14:55:47.000Z",
        "updated_at": "2026-11-08T14:55:47.000Z",
        "customer": {
          "id": 1,
          "name": "Rahim Biswas Traders",
          "phone": "9830000000"
        }
      }
    ]
  }
}
```

---

### GET /reports/sales

**Sales report** · 🔒 Bearer token

**Query parameters**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `from` | date | no | — |
| `to` | date | no | ≥ from |

**Example request**

```http
GET /api/v1/reports/sales?from=2026-11-01&to=2026-11-08
```

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Sales report fetched successfully",
  "data": {
    "from": "2026-11-01",
    "to": "2026-11-08",
    "count": 19,
    "amount": "595660.00",
    "cost": "376752.00",
    "profit": "218908.00",
    "by_product": [
      {
        "product_id": 1,
        "product_name": "Fly Ash Brick 9×4×3",
        "quantity": "62000.00",
        "amount": "403000.00",
        "profit": "142600.00"
      },
      {
        "product_id": 2,
        "product_name": "Fly Ash Brick 9×4×2.5",
        "quantity": "26000.00",
        "amount": "150800.00",
        "profit": "52000.00"
      }
    ],
    "daily": [
      {
        "date": "2026-11-01",
        "amount": "66076.00",
        "profit": "24492.00"
      },
      {
        "date": "2026-11-03",
        "amount": "65800.00",
        "profit": "23800.00"
      }
    ]
  }
}
```

❌ **422 Validation failed** · from after to (same for every range report)

```json
{
  "success": false,
  "status_code": 422,
  "message": "Validation failed",
  "data": {
    "errors": [
      {
        "field": "from",
        "message": "From date must be on or before the to date"
      }
    ]
  }
}
```

---

### GET /reports/dues

**Dues report** · 🔒 Bearer token

Customers with dues on delivered sales, highest first, plus `grand_total`.

**Query parameters**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `page` | integer | no | ≥ 1, default `1` |
| `limit` | integer | no | 1–100, default `20` |

**Example request**

```http
GET /api/v1/reports/dues?page=1&limit=2
```

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Dues report fetched successfully",
  "data": {
    "items": [
      {
        "customer_id": 1,
        "name": "Rahim Biswas Traders",
        "phone": "9830000000",
        "total_due": "152500.00",
        "oldest_due_date": "2026-11-08",
        "sales_count": 5
      },
      {
        "customer_id": 29,
        "name": "Bikash Ghosh Traders",
        "phone": "9830221732",
        "total_due": "64965.00",
        "oldest_due_date": "2026-10-09",
        "sales_count": 2
      }
    ],
    "page": 1,
    "limit": 2,
    "total": 29,
    "last_page": 15,
    "grand_total": "828316.00"
  }
}
```

---

### GET /reports/expenses

**Expense report** · 🔒 Bearer token

**Query parameters**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `from` | date | no | — |
| `to` | date | no | — |

**Example request**

```http
GET /api/v1/reports/expenses?from=2026-11-01&to=2026-11-08
```

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Expense report fetched successfully",
  "data": {
    "from": "2026-11-01",
    "to": "2026-11-08",
    "total": "12900.00",
    "by_category": [
      {
        "category_id": 1,
        "name": "Labour Tiffin",
        "icon": "utensils",
        "amount": "10600.00",
        "percent": 82.2
      },
      {
        "category_id": 6,
        "name": "Others",
        "icon": "circle-dot",
        "amount": "1450.00",
        "percent": 11.2
      }
    ]
  }
}
```

---

### GET /reports/wages

**Wage report** · 🔒 Bearer token

**Query parameters**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `month` | YYYY-MM | no | Default current month |

**Example request**

```http
GET /api/v1/reports/wages?month=2026-10
```

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Wage report fetched successfully",
  "data": {
    "month": "2026-10",
    "earned": "155062.91",
    "advances": "6000.00",
    "paid": "0.00",
    "balance": "149062.91",
    "rows": [
      {
        "labour_id": 9,
        "name": "Abdul Karim",
        "wage_type": "daily",
        "wage_amount": "450.00",
        "is_active": true,
        "present_days": 25,
        "half_days": 4,
        "absent_days": 2,
        "not_marked_days": 0,
        "worked_days": "27.00",
        "earned": "12150.00",
        "advances": "0.00",
        "paid": "0.00",
        "balance": "12150.00",
        "status": "due"
      },
      {
        "labour_id": 12,
        "name": "Asit Roy",
        "wage_type": "daily",
        "wage_amount": "550.00",
        "is_active": true,
        "present_days": 24,
        "half_days": 4,
        "absent_days": 3,
        "not_marked_days": 0,
        "worked_days": "26.00",
        "earned": "14300.00",
        "advances": "0.00",
        "paid": "0.00",
        "balance": "14300.00",
        "status": "due"
      }
    ]
  }
}
```

---

### GET /reports/net-profit

**Net profit report** · 🔒 Bearer token

`net_profit = sales_profit − expenses − wages` for the range, plus a `monthly` series.

**Query parameters**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `from` | date | no | — |
| `to` | date | no | — |

**Example request**

```http
GET /api/v1/reports/net-profit?from=2026-10-01&to=2026-11-08
```

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Net profit report fetched successfully",
  "data": {
    "from": "2026-10-01",
    "to": "2026-11-08",
    "sales_profit": "657642.00",
    "expenses": "68700.00",
    "wages": "192112.91",
    "net_profit": "396829.09",
    "monthly": [
      {
        "month": "2026-10",
        "sales_profit": "438734.00",
        "expenses": "55800.00",
        "wages": "155062.91",
        "net_profit": "227871.09"
      },
      {
        "month": "2026-11",
        "sales_profit": "218908.00",
        "expenses": "12900.00",
        "wages": "37050.00",
        "net_profit": "168958.00"
      }
    ]
  }
}
```

---

### GET /reports/collections

**Collection report** · 🔒 Bearer token

Money received from customers.

**Query parameters**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `from` | date | no | — |
| `to` | date | no | — |

**Example request**

```http
GET /api/v1/reports/collections?from=2026-11-01&to=2026-11-08
```

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Collection report fetched successfully",
  "data": {
    "from": "2026-11-01",
    "to": "2026-11-08",
    "total": "291284.00",
    "by_method": [
      {
        "method": "cash",
        "amount": "152804.00"
      },
      {
        "method": "bank",
        "amount": "88480.00"
      }
    ],
    "daily": [
      {
        "date": "2026-11-01",
        "amount": "40204.00"
      },
      {
        "date": "2026-11-03",
        "amount": "65800.00"
      }
    ]
  }
}
```

---

## 15. Settings

### GET /settings/factory

**Factory profile** · 🔒 Bearer token

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Factory profile fetched successfully",
  "data": {
    "id": 1,
    "factory_name": "Maa Tara Fly Ash Bricks",
    "owner_name": "Rahim Sheikh",
    "phone": "9833333333",
    "email": "maatara@test.com",
    "address": "Barasat, WB",
    "invoice_prefix": "INV-",
    "updated_by": 1,
    "created_at": "2026-11-08T14:18:10.000Z",
    "updated_at": "2026-11-08T14:21:40.000Z"
  }
}
```

---

### PUT /settings/factory

**Edit factory profile** · 🔒 Bearer token

The invoice prefix applies to new sales only. The logo is a static asset in the app (no upload).

**Request body**

| Field | Type | Required | Rules / notes |
|---|---|---|---|
| `factory_name` | string | yes | 1–150 chars |
| `owner_name` | string \| null | no | — |
| `phone` | string \| null | no | 10 digits |
| `email` | string \| null | no | — |
| `address` | string \| null | no | max 500 |
| `invoice_prefix` | string | no | 1–10 chars: A–Z, 0–9, `-` (upper-cased) |

**Example request**

```http
PUT /api/v1/settings/factory
Content-Type: application/json

{
  "factory_name": "Maa Tara Fly Ash Bricks",
  "owner_name": "Rahim Sheikh",
  "phone": "9833333333",
  "email": "maatara@test.com",
  "address": "Barasat, WB",
  "invoice_prefix": "INV-"
}
```

**Responses**

✅ **200 OK** · Success

```json
{
  "success": true,
  "status_code": 200,
  "message": "Factory profile updated",
  "data": {
    "id": 1,
    "factory_name": "Maa Tara Fly Ash Bricks",
    "owner_name": "Rahim Sheikh",
    "phone": "9833333333",
    "email": "maatara@test.com",
    "address": "Barasat, WB",
    "invoice_prefix": "INV-",
    "updated_by": 1,
    "created_at": "2026-11-08T14:18:10.000Z",
    "updated_at": "2026-11-08T14:21:40.000Z"
  }
}
```

❌ **422 Validation failed** · Validation errors

<details><summary>Request body</summary>

```json
{
  "factory_name": "",
  "invoice_prefix": "INVOICE-2026"
}
```

</details>

```json
{
  "success": false,
  "status_code": 422,
  "message": "Validation failed",
  "data": {
    "errors": [
      {
        "field": "factory_name",
        "message": "The factory name field is required"
      },
      {
        "field": "invoice_prefix",
        "message": "The invoice prefix field format is invalid"
      }
    ]
  }
}
```

---

