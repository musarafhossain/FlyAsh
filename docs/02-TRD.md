# 02 · Technical Requirements Document (TRD): FlyAsh

| | |
|---|---|
| **Document** | Technical Requirements Document |
| **Version** | 1.0 |
| **Date** | 2026-11-08 |
| **Status** | Approved for v1 |
| **Related docs** | 01-PRD · 03-AppFlow · 04-UI-UX-Design-Brief · 05-Backend-Schema · 06-Implementation-Plan · 07-API-Reference |

**Guiding rule: keep it simple.** Use the framework defaults. Add no layer, package or abstraction until a real need appears.

---

## 1. Technology Stack

| Layer | Technology |
|---|---|
| Frontend | **Flutter 3.41** (Dart 3.11), one codebase for **Android, Web and Windows** |
| State management / DI | **flutter_riverpod** |
| Backend | **AdonisJS 7** (TypeScript) on **Node.js 24 LTS** |
| ORM / validation / auth | Lucid ORM · VineJS · `@adonisjs/auth` access tokens |
| Email | `@adonisjs/mail` over SMTP (password reset OTP) |
| Database | **MariaDB**: XAMPP's bundled MariaDB in development, MariaDB 11.4 LTS in production |
| Web server (prod) | Nginx (reverse proxy + static files) + PM2 (Node process manager) |
| OS (prod) | Ubuntu Server 24.04 LTS on a VPS |
| SSL | Let's Encrypt (certbot) |

Exact versions are pinned in `pubspec.yaml` / `package.json` when the projects are created.

## 2. System Architecture

```
┌───────────────────────────────┐
│ Flutter app                   │
│ Android · Web · Windows       │
└──────────────┬────────────────┘
               │ HTTPS, JSON, Bearer token
               ▼
┌───────────────────────────────┐        ┌──────────────┐
│ Nginx                         │        │ MariaDB      │
│  api.<domain> → Adonis :3333  │──────► │ flyash db    │
│  app.<domain> → Flutter web   │        └──────────────┘
│  /downloads   → APK / EXE     │
└──────────────┬────────────────┘
               ▼
       AdonisJS API (PM2)
```

- All business calculations (totals, tax, dues, wages, net profit) run **on the server**. The app only displays them.
- The app is **online only** in v1 (offline entry is Phase 2).

## 3. Repository Structure

One git repository (monorepo):

```
FlyAsh/
├── docs/        → these documents
├── backend/     → AdonisJS API
└── app/         → Flutter app
```

## 4. API Standards

### 4.1 Basics

- Base URL: `https://api.<domain>/api/v1` (dev: `http://localhost:3333/api/v1`)
- JSON request and response bodies, `snake_case` keys
- Auth header: `Authorization: Bearer <token>`
- Language header: `Accept-Language: en` (default) or `bn`. Every `message` (success, errors, validation errors and field names) comes back in that language, with a `Content-Language` header. Without the header, authenticated requests use the user's saved language (`users.locale`), and public requests use English. The app sends the header from its language setting and saves the choice with `PUT /auth/preferences`. Translations live in `backend/resources/lang/{en,bn}/messages.json` and `validator.json`; code uses message keys (`sales.saved`), never raw text
- Dates `YYYY-MM-DD`; timestamps ISO-8601 in UTC (`2026-11-08T06:30:00.000Z`). See §4.3 for the rules
- Money is sent and returned as **strings with 2 decimals** (`"28500.00"`), so no precision is lost in JSON. Flutter parses it with a decimal type.

### 4.2 Response format (every endpoint)

```json
{
  "success": true,
  "status_code": 200,
  "message": "Customer fetched successfully",
  "data": { }
}
```

| Case | `data` contains |
|---|---|
| Single record | The object |
| Paginated list | `{ items, page, limit, total, last_page }` |
| Action with no result (delete, logout) | `null` |
| Validation error (422) | `{ errors: [{ field, message }] }` |
| Other errors | `null` |

**Single record**
```json
{
  "success": true,
  "status_code": 200,
  "message": "Customer fetched successfully",
  "data": { "id": 12, "name": "Rahim Sheikh", "phone": "9876543210", "address": "Barasat", "total_due": "4500.00" }
}
```

**Paginated list**
```json
{
  "success": true,
  "status_code": 200,
  "message": "Customers fetched successfully",
  "data": {
    "items": [ { "id": 12, "name": "Rahim Sheikh" } ],
    "page": 1,
    "limit": 20,
    "total": 134,
    "last_page": 7
  }
}
```

**Validation error**
```json
{
  "success": false,
  "status_code": 422,
  "message": "Validation failed",
  "data": { "errors": [ { "field": "phone", "message": "Phone number already exists" } ] }
}
```

**Other error**
```json
{ "success": false, "status_code": 404, "message": "Sale not found", "data": null }
```

Status codes used: `200` OK · `201` Created · `400` Bad request / business rule failed · `401` Not logged in · `404` Not found · `409` Conflict (for example, deleting a used product) · `422` Validation · `429` Too many attempts · `500` Server error.

### 4.3 Dates and time

There are two kinds of time values, and they follow different rules:

| Kind | Examples | Format | Stored | In the app |
|---|---|---|---|---|
| **Timestamp** (when something happened) | `created_at`, `updated_at`, `last_login_at`, `cancelled_at` | ISO-8601 UTC: `2026-11-08T14:22:18.000Z` | `DATETIME` in UTC | `DateTime.parse(v).toLocal()` → shown in the **device** timezone |
| **Business date** (which day it counts for) | `sale_date`, `delivery_date`, `delivered_date`, `payment_date`, `date` (attendance), `expense_date`, `joining_date`, `left_date`, `wage_month` | `YYYY-MM-DD` (months: `YYYY-MM`) | `DATE`, no timezone | Shown **as is**. Never call `toLocal()` / `toUtc()` on it |

- **"Today" is the factory's day** (`APP_TIMEZONE`, default `Asia/Kolkata`), not the server's UTC day and not the viewer's device day. It changes at midnight IST.
- **Reports, dashboard and wages use business dates only**, so every viewer sees the same numbers wherever they are, and a sale at 11:59 PM never moves to the next day.
- Every response carries `X-Business-Date: 2026-11-08` and `X-Business-Timezone: Asia/Kolkata` (also exposed to the web app through CORS). The app stores the latest value and uses it, **not the device clock**, as the default date for forms, filters and "today" presets. A device in another timezone then never picks a date the server treats as the future.
- "Not in the future" checks (sale, payment, attendance, expense dates) compare against the factory's today.

### 4.4 Pagination, search and filters

- Query params: `page` (default `1`), `limit` (default `20`, max `100`)
- Search: `search=<text>`
- Filters: plain params, for example `status=due&type=booking&from=2026-11-01&to=2026-11-30`
- Sorting: a sensible default per list (newest first). Optional `sort=name&order=asc` only where the UI needs it.

### 4.5 Endpoints (v1)

All endpoints require auth except the ones marked 🌐.

| Module | Method & path | Purpose |
|---|---|---|
| **Health** | 🌐 `GET /health` | Server and DB status |
| **App update** | 🌐 `GET /app/version?platform=android\|windows\|web&build=12` | Latest version info + `update_available`, `force_update` |
| **Auth** | 🌐 `POST /auth/login` | Phone/email + password → token |
| | 🌐 `POST /auth/forgot-password` | `{ email }` → emails a 6-digit OTP. Always returns 200 with the same message |
| | 🌐 `POST /auth/verify-otp` | `{ email, otp }` → `{ reset_token }` (signed, valid 10 min, single use) |
| | 🌐 `POST /auth/reset-password` | `{ reset_token, password, password_confirmation }` → sets the new password and revokes all of that user's tokens |
| | `POST /auth/logout` | Revoke the current token |
| | `GET /auth/me` · `PUT /auth/me` | View / edit my profile |
| | `PUT /auth/password` | Change my password |
| | `PUT /auth/preferences` | Save my language, theme mode and theme color (only the fields sent) |
| **Users** | `GET /users` | List (search, `active`), paginated. **Excludes the logged-in user** |
| | `POST /users` · `GET/PUT /users/:id` | Add / view / edit another user |
| | `PATCH /users/:id/status` | Activate / deactivate another user |
| | `PUT /users/:id/password` | Reset another user's password (revokes their tokens) |
| | | Any `/users/:id` call with your own id returns `400` "Use My Profile to change your own details" |
| **Dashboard** | `GET /dashboard` | All dashboard cards in one call |
| **Products** | `GET /products` | List (search, `active=true\|false`), paginated |
| | `POST /products` · `GET/PUT/DELETE /products/:id` | Create / view / update / delete (delete only if unused → else 409) |
| | `PATCH /products/:id/status` | Activate / deactivate |
| **Customers** | `GET /customers` | List (search, `has_due=true`), paginated, each with `total_due` |
| | `POST /customers` · `GET/PUT/DELETE /customers/:id` | CRUD (phone optional; delete only if no sales) |
| | `PATCH /customers/:id/status` | Activate / deactivate |
| | `GET /customers/:id/sales` | That customer's sales, paginated |
| **Sales** | `GET /sales` | List (search, type, status, from, to), paginated |
| | `POST /sales` | Create (customer_id **or** new_customer, items[] with price only, transport / discount / tax_percent, initial payment) |
| | `GET/PUT/DELETE /sales/:id` | View / edit / soft delete |
| | `POST /sales/:id/deliver` | Booking → delivered (`delivered_date`) |
| | `POST /sales/:id/cancel` | Booking → cancelled |
| | `POST /sales/:id/payments` · `DELETE /sales/:id/payments/:paymentId` | Add / remove payment |
| | `GET /sales/upcoming-deliveries` | Booked, not delivered, paginated |
| **Labours** | `GET /labours` | List (search, `active`), paginated |
| | `POST /labours` · `GET/PUT /labours/:id` | Create / view / update |
| | `PATCH /labours/:id/status` | Deactivate (with `left_date`) / activate |
| **Attendance** | `GET /attendance?date=2026-11-08` | Active labours on that date, each with `present` (true / false) |
| | `PUT /attendance` | `{ date, records: [{ labour_id, present, wage? }] }`: present saves a row (with `wage` as that day's daily wage when given), false removes it. The app sends one switch at a time. `GET` returns `day_wage` per labour |
| | `GET /labours/:id/attendance?month=2026-11` | Monthly calendar for one labour |
| **Wages** | `GET /wages?month=2026-11` | Wage sheet for all labours, paginated |
| | `GET /labours/:id/wages?month=2026-11` | Detailed breakdown for one labour |
| | `POST /labours/:id/wage-payments` · `DELETE /wage-payments/:id` | Wage payments (no separate advances) |
| **Expenses** | `GET /expenses` | List (from, to, category text, search), paginated, plus `period_total` |
| | `POST /expenses` · `GET/PUT/DELETE /expenses/:id` | CRUD |
| | `GET /expense-categories` | Category names used before + defaults (suggestions only; categories are free text) |
| **Reports** | `GET /reports/sales?from&to` | Totals, by product, daily series |
| | `GET /reports/dues` | Customers with dues, paginated |
| | `GET /reports/expenses?from&to` | Totals by category |
| | `GET /reports/wages?month` | Wage summary |
| | `GET /reports/net-profit?from&to` | Sales (without tax) − expenses − wages, monthly series |
| | `GET /reports/collections?from&to` | Payments by date and method |
| **Settings** | `GET/PUT /settings/factory` | Factory profile |

Full request and response fields are defined in **05-Backend-Schema**.

## 5. Backend (AdonisJS)

### 5.1 Folder structure

Standard Adonis layout. Only `services/` and `helpers/` are added.

```
backend/
├── app/
│   ├── controllers/     → one per module, thin (validate → call model/service → respond)
│   ├── models/          → Lucid models
│   ├── validators/      → VineJS schemas
│   ├── services/        → calculation logic only: SaleService, WageService, ReportService, DashboardService
│   ├── helpers/         → api_response.ts (the response format), money.ts
│   ├── middleware/      → auth, force_json
│   └── exceptions/      → handler.ts (maps every error to the response format)
├── commands/            → app_release.ts, user_create.ts, user_reset_password.ts
├── database/
│   ├── migrations/
│   └── seeders/         → expense categories, (dev) sample data
├── start/routes.ts      → all routes under /api/v1
└── tests/               → Japa tests for the services
```

**No repository layer and no DTO classes on the backend.** Lucid models and VineJS validators cover that.

### 5.2 Response helper

A single helper keeps every response the same:

```ts
// app/helpers/api_response.ts
export function ok(response, data, message = 'Success', statusCode = 200) {
  return response.status(statusCode).send({ success: true, status_code: statusCode, message, data })
}

export function paginated(response, paginator, message = 'Success') {
  const meta = paginator.getMeta()
  return ok(response, {
    items: paginator.all(),
    page: meta.currentPage,
    limit: meta.perPage,
    total: meta.total,
    last_page: meta.lastPage,
  }, message)
}

export function fail(response, statusCode, message, data = null) {
  return response.status(statusCode).send({ success: false, status_code: statusCode, message, data })
}
```

Typical controller:

```ts
async index({ request, response }: HttpContext) {
  const { page = 1, limit = 20, search } = await request.validateUsing(listCustomersValidator)
  const customers = await Customer.query()
    .if(search, (q) => q.whereLike('name', `%${search}%`).orWhereLike('phone', `%${search}%`))
    .orderBy('created_at', 'desc')
    .paginate(page, Math.min(limit, 100))
  return paginated(response, customers, 'Customers fetched successfully')
}
```

The **exception handler** turns VineJS errors into 422 `{ errors: [...] }`, `E_ROW_NOT_FOUND` into 404, auth errors into 401, rate limits into 429, and anything unknown into 500 (stack traces only in dev).

### 5.3 Services (business logic)

| Service | Responsibility |
|---|---|
| `SaleService` | Create and update a sale in **one DB transaction**: snapshot line prices, compute subtotal / tax / total, record the initial payment, recompute `paid_amount`, `due_amount` and `payment_status`. Generate the invoice number. Enforce the rules in PRD §6.1–6.2 |
| `WageService` | Monthly wage sheet from attendance snapshots and wage payments (PRD §6.3) |
| `ReportService` | Aggregate SQL queries for each report |
| `DashboardService` | One method returning every dashboard number |

Stored totals (`tax_amount`, `total`, `paid_amount`, `due_amount`) are kept on the `sales` row and recomputed by `SaleService` whenever items or payments change. This keeps lists and reports fast and simple.

### 5.4 Authentication and security

- `@adonisjs/auth` **access tokens** (opaque, stored hashed in the DB) with **no expiry**. A token stays valid until logout, user deactivation, or a password change or reset. There is no refresh endpoint.
- **Login flow:**
  1. `POST /auth/login` with `{ "login": "<phone or email>", "password": "..." }`
  2. Response `data`: `{ "token": "oat_...", "user": { "id", "name", "phone", "email" } }`
  3. The app stores the token in `flutter_secure_storage`
  4. The Dio interceptor sends `Authorization: Bearer <token>` on every request
  5. The `auth` middleware hashes the token, looks it up in `auth_access_tokens`, and checks the user is active. Otherwise it returns `401` and the app clears the token and opens Login
  6. `POST /auth/logout` deletes the current token on the server and in the app
- Changing your own password deletes your **other** tokens (other devices are logged out, the current device stays logged in).
- **Forgot password (email OTP + signed reset token), 3 steps / 3 screens:**
  1. **Send OTP:** `POST /auth/forgot-password { email }`. If an **active** user has this email, the server deletes any older OTP for them, generates a random 6-digit OTP, saves its **hash** in `password_reset_otps` (`user_id`, `otp_hash`, `expires_at` = now + 10 min, `attempts` = 0, `verified_at` = null) and emails it. The response is **always** `200` "If this email is registered, an OTP has been sent", so nobody can find out which emails exist.
  2. **Verify OTP:** `POST /auth/verify-otp { email, otp }`. The server finds the latest unexpired, unverified OTP for that email and compares the hash. A wrong OTP does `attempts + 1`, and at 5 attempts the OTP is deleted (`400` "Too many attempts, request a new OTP"). A correct OTP sets `verified_at` and returns a **signed reset token**:
     ```ts
     const resetToken = encryption.verifier.sign(
       { user_id: user.id, otp_id: otp.id },   // payload
       '10 minutes',                           // expiry
       'password_reset'                        // purpose
     )
     ```
     The token is signed with `APP_KEY` (HMAC), so it cannot be changed or forged. It expires after 10 minutes and is valid only for the `password_reset` purpose.
  3. **Set new password:** `POST /auth/reset-password { reset_token, password, password_confirmation }`. The server checks the signature, expiry and purpose with `encryption.verifier.unsign(token, 'password_reset')`, then checks that the `otp_id` row still exists with `verified_at` set and belongs to `user_id`. This makes the token **single use**. The server then sets the new password, deletes the OTP row and **all** of the user's access tokens, and returns `200`. The app goes to Login. An invalid, expired or used token returns `400` "Reset link expired, please start again".
  4. Limits (`@adonisjs/limiter`): forgot-password 3 per 15 minutes per email + IP, verify-otp 10 per 15 minutes per IP, reset-password 10 per 15 minutes per IP. The app shows a 60-second "Resend OTP" countdown.
  5. The app keeps `reset_token` **in memory only** (passed to the next screen as a route argument, never saved to storage).
  6. Email is sent with **`@adonisjs/mail`** over SMTP (Gmail with an App Password, or any SMTP provider). The template contains the factory name, the OTP, "valid for 10 minutes" and "ignore this email if you did not ask for it", written in the user's saved language (`users.locale`).
  7. In development `MAIL_MAILER=log` prints the email (and OTP) to the console, so no real email is needed.
- Passwords hashed with **scrypt** (the Adonis default).
- **Users:** there are no roles, and every authenticated user can call every endpoint. There is no sign-up endpoint. The first user is created with `node ace user:create`, and a forgotten password can be reset on the server with `node ace user:reset-password <phone>`.
- Deactivating a user or resetting their password **deletes all of their access tokens**, so they are logged out everywhere. The auth middleware also rejects tokens of inactive users.
- `created_by` is set explicitly from `auth.user` in controllers and services on sales, payments, expenses, wage payments and attendance.
- `@adonisjs/limiter`: 5 login attempts per 15 minutes per IP + phone.
- CORS limited to the web app's domain (plus localhost in dev).
- **No file uploads:** the app stores no images on the server. The factory logo is a static asset in the Flutter app.
- All queries go through Lucid (parameterized), so there is no raw SQL string building.

### 5.5 Configuration (`.env`)

```
PORT=3333
HOST=0.0.0.0
NODE_ENV=development
APP_KEY=<generated>
TZ=UTC
APP_TIMEZONE=Asia/Kolkata
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=root
DB_PASSWORD=
DB_DATABASE=flyash
CORS_ORIGIN=http://localhost:5000
MAIL_MAILER=log            # smtp in production
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=
SMTP_PASSWORD=             # Gmail App Password
MAIL_FROM_ADDRESS=
MAIL_FROM_NAME=FlyAsh
```

"Today" and date ranges are calculated in `APP_TIMEZONE` (IST), and stored timestamps are UTC.

## 6. Database (MariaDB)

Full tables, columns and indexes are in **05-Backend-Schema**. Conventions:

| Convention | Rule |
|---|---|
| Charset | `utf8mb4` / `utf8mb4_unicode_ci` (Bengali text) |
| Primary keys | `id CHAR(36)` UUID v7 set by the app (except `auth_access_tokens.id`, numeric for Adonis tokens). Invoice numbers come from `factory_settings.last_invoice_no` |
| Names | `snake_case`, plural table names |
| Timestamps | `created_at`, `updated_at` on every table |
| **Money** | `DECIMAL(12,2)`, never FLOAT/DOUBLE |
| Quantity | `DECIMAL(12,2)` (allows fractional trucks) |
| Soft delete | `deleted_at` on `sales`. `is_active` on products, customers, labours, expense categories |
| Foreign keys | Always, with `ON DELETE RESTRICT` |
| Uniques | `users.phone`, `users.email`, `customers.phone`, `products.name`, `attendances(labour_id, date)`, `sales.invoice_no` |
| Audit | `created_by` (FK → `users.id`) on business records |
| Migrations | Every schema change is a Lucid migration. Never edit the DB by hand |

Main tables: `users`, `auth_access_tokens`, `password_reset_otps`, `factory_settings`, `products`, `customers`, `sales`, `sale_items`, `sale_payments`, `labours`, `attendances`, `wage_payments`, `expenses`, `app_versions`. All ids are UUID v7 (see 05-Backend-Schema).

## 7. Frontend (Flutter)

### 7.1 Clean Architecture, feature-first

```
app/lib/
├── main.dart
├── app.dart                     → MaterialApp.router, theme, locale
├── core/
│   ├── config/                  → env (API base URL via --dart-define)
│   ├── network/                 → dio_client.dart, api_response.dart, paginated.dart, interceptors
│   ├── error/                   → failure.dart, exceptions.dart
│   ├── theme/                   → tokens, 5 accents × light/dark, theme_controller
│   ├── router/                  → go_router routes + auth redirect
│   ├── l10n/                    → app_en.arb, app_bn.arb
│   ├── utils/                   → money (₹ en_IN format), dates, validators
│   └── widgets/                 → shared UI components from 04-UI-UX §9 (HeroCard, KpiChip, StatusPill, PaginatedListView …)
└── features/
    ├── auth/
    ├── dashboard/
    ├── products/
    ├── customers/
    ├── sales/
    ├── labours/
    ├── attendance/
    ├── wages/
    ├── expenses/
    ├── reports/
    ├── settings/
    └── app_update/
```

Each feature follows the same 3 layers:

```
features/customers/
├── domain/
│   ├── entities/customer.dart              → plain Dart class (freezed)
│   ├── repositories/customer_repository.dart   → abstract
│   └── usecases/                           → get_customers.dart, save_customer.dart …
├── data/
│   ├── models/customer_model.dart          → JSON ↔ entity (json_serializable)
│   ├── datasources/customer_remote_ds.dart → Dio calls
│   └── repositories/customer_repository_impl.dart
└── presentation/
    ├── providers/                          → Riverpod notifiers
    ├── pages/                              → customer_list_page, customer_form_page, customer_detail_page
    └── widgets/
```

**Dependency rule:** `presentation → domain ← data`. The domain layer has no Flutter or Dio imports.

**Keeping it simple:**
- A use case is a small class with one `call()` method. Simple CRUD use cases are one line.
- Repositories return `Future<Either<Failure, T>>`, written as a small sealed `Result<T>` class in core with no extra package.
- Riverpod providers do the dependency injection (no get_it).
- No separate local data source in v1 (online only).

### 7.2 Packages

| Purpose | Package |
|---|---|
| State / DI | `flutter_riverpod` (plain providers, no code generation) |
| HTTP | `dio` |
| Routing | `go_router` |
| Models | `freezed`, `json_serializable`, `build_runner` |
| Secure token storage | `flutter_secure_storage` |
| Preferences (theme, locale) | `shared_preferences` |
| Formatting & i18n | `intl`, `flutter_localizations` |
| Decimal money | `decimal` |
| PDF / print / share | `pdf`, `printing`, `share_plus` |
| Android launch screen | `flutter_native_splash` (dev; config in `pubspec.yaml`, regenerate with `dart run flutter_native_splash:create`; the `NormalTheme` window colour `@color/app_background` is set by hand in `res/values*/`) |
| Excel export | `excel` |
| Charts | `fl_chart` |
| Fonts | `google_fonts` (Inter, Hind Siliguri), bundled as assets for offline use |
| Links (call / WhatsApp) | `url_launcher` |
| App version | `package_info_plus` |
| App update install | `open_filex` (opens the downloaded APK/EXE) |
| Biometric (P2) | `local_auth` |

### 7.3 Networking

- One `Dio` instance (Riverpod provider) with the base URL from `--dart-define=API_BASE_URL=...`.
- **Auth interceptor** adds the Bearer token. On a `401` it clears the token and redirects to Login.
- A shared parser reads the standard response:

```dart
class ApiResponse<T> {
  final bool success;
  final int statusCode;
  final String message;
  final T? data;
}

class Paginated<T> {
  final List<T> items;
  final int page, limit, total, lastPage;
  bool get hasMore => page < lastPage;
}
```

- Errors become a `Failure` (`network`, `unauthorized`, `validation(fieldErrors)`, `server(message)`). Forms show field errors under the matching input.
- Timeouts: connect 10 s, receive 20 s (APK/EXE update downloads have no receive timeout).

### 7.4 Pagination in lists

One reusable `PagedList<T>` widget (`core/widgets/paged_list.dart`) with a `PagedListController`:
- Loads `page=1&limit=20`, then the next page when the user scrolls near the end, while `hasMore`.
- Pull to refresh resets to page 1 and skips the cache. Search and filter changes reset to page 1 with a skeleton (`controller.refresh()`; search is debounced 400 ms).
- Built-in loading skeleton shaped like the list (a table skeleton on desktop), empty state, error + retry, and a spinner while the next page loads (no "Showing x of y" line).
- When their data changes, lists reload **in the background** (`controller.revalidate()`): the loaded pages are fetched again and swapped in, the rows stay on screen, and a failed reload keeps the old rows. See §7.5.
- `itemId` turns on optimistic patches for the list (§7.5).

### 7.5 Caching, invalidation and optimistic updates

All server data goes through `ApiClient`, so caching is done there once for every section (`core/network/query_cache.dart`, `data_changed.dart`, `optimistic.dart`).

**Data tags.** Every endpoint belongs to one or more tags, taken from its path: `products`, `customers`, `sales`, `labours`, `attendance`, `wages`, `expenses`, `users`, `settings`, `dashboard`, `reports` (`/customers/7/sales` → customers + sales; `/wage-payments/3` → wages). `/auth/*`, `/health` and `/app/version` have no tag and are never cached.

**Query cache.** Each successful GET answer is kept in memory for **60 seconds**, keyed by user + language + path + query. Opening a screen again in that time (switching tabs, going back, the same filter again) shows the data at once with no request. The cache lives only while the app runs; it is never written to disk.

**Invalidation.** After a successful POST / PUT / PATCH / DELETE (not `/auth`), `ApiClient` works out which tags the change affects and:
1. removes those entries from the cache, so the next read goes to the server;
2. bumps those tags in `dataChangedProvider`, so the open screens that show them reload in the background.

| Change to | Makes stale |
|---|---|
| products | products |
| customers | customers, sales, dashboard, reports |
| sales (incl. payments, deliver, cancel) | sales, customers, dashboard, reports |
| labours | labours, attendance, wages, dashboard, reports |
| attendance | attendance, labours, wages, dashboard, reports |
| wage payments | wages, labours, dashboard, reports |
| expenses | expenses, dashboard, reports |
| users | users |
| factory settings | settings |

Screens listen only to their own tags: `ref.onDataChanged({DataTag.sales}, list.revalidate)`. For example, a new expense reloads the expense list and Home, but not the product list.

**Skipping the cache.** Pull to refresh (`PagedList`, `PageBody`, Home, Sale detail, Attendance) and Retry run inside `QueryCache.fresh(...)`: every GET inside goes to the server and refreshes the cache. Changes made by **other users** show after a pull to refresh or once the 60 s are over.

**Optimistic updates.** Quick actions change the screen first and roll back if the server refuses:

| Action | On screen at once | On failure |
|---|---|---|
| Deactivate / activate (products, customers, labours, users), from the list or the detail page | Status pill and menu label change | Back to the old state + the server's message |
| ~~Delete (products, customers, sales, expenses)~~ (not optimistic any more, see below) | — | The row comes back + the message (e.g. "Product is used in sales. Deactivate it instead") |
| ~~Delete a sale payment or a wage payment~~ | — | — |

**Deletes are not optimistic** (changed after review): `confirmDelete` (`core/widgets/form_submit.dart`) keeps the dialog open while the request runs (`showConfirmDialog(onConfirm:)`: buttons disabled, spinner); success closes it and the list reloads; failure shows the server message in the dialog and as a toast, and the dialog stays open.
| Attendance switch | The switch moves and the count updates | The switch goes back + the message |

How: the action calls `ref.optimistic(id, preview, request)` or `ref.optimisticRemove(id, request)`. The patch is stored by item id in `optimisticProvider` with a timestamp. `PagedList` (with `itemId`) and detail pages (`ref.patched(...)`, `ref.isRemoved(id)`) show patches made **after** their data was loaded. When the request succeeds, the tags are invalidated, the screen reloads in the background, and the server's data replaces the patch. When it fails, the patch is undone.

Forms (create / edit) are **not** optimistic: they wait for the server, because it may return validation errors or computed values (totals, tax, invoice no.).

### 7.6 Theming and motion

Motion and the design principles of 04-UI-UX §14 live in shared code, so every section gets them:
- `core/widgets/motion.dart`: `Motion` tokens (120 ms press, 220 ms enter, 35 ms stagger step, ease curves), `PressScale` (inside `AppCard` / `HeroCard` when tappable) and `StaggeredEntrance` (inside `ListGroup`). Both do nothing when the system asks for reduced motion.
- **Shared element + instant detail:** list rows call `context.push('/products/<id>', extra: product)`; the route passes `initial:` to the detail page (`_extra<T>(state)` in `app_router.dart`), which shows it at once and then loads the latest data. The avatar has the same `heroTag` (`product-<id>` …) on the row and on the detail header. A deep link or a refresh has no `extra`, so the page loads with a skeleton as before.
- `core/theme/oklch.dart`: `oklch(l, c, h)` → `Color`; used for the avatar colours.
- Typography tracking and leading are set per style in `AppTypography._style`; dialogs use `DialogThemeData.alignment (0, −0.12)`.
- Phone fields use `PhoneInputFormatter` (`normalizePhone`); the API does the same in `phoneRule` (`.parse(normalizePhone)`), so both sides are liberal in what they accept.
- **Back button (`core/router/back_guard.dart`):** `AppShell` tracks the drawer (`onDrawerChanged`); its `PopScope` closes the drawer before going Home. `BackGuardObserver` (one per navigator: root + each branch) reports popup routes (dialogs, sheets, popup menus) to `BackGuard`. On web, `BackGuard` is a `WidgetsBindingObserver` attached in `FlyAshApp.initState`, before the router listens, so it sees the browser's back (`didPushRouteInformation`) first: if something is open it closes it, returns `true` (the router does not navigate) and re-reports the current URL with `SystemNavigator.routeInformationUpdated(replace: false)`.
- **Labours tabs:** `/labours` and `/labours/wages` are two routes with the same page key (`_laboursSectionKey`), so switching tabs updates one `LaboursPage` in place and the `SegmentedTabs` pill slides.
- **Browser history after app pops (web, `core/router/web_history_sync.dart`):** Flutter's router adds a new history entry when the app pops a page (Save, ←), so history read list → edit → list and browser back reopened the form. `WebHistorySync` records which page each entry shows (Flutter web tags entries with `history.state.serialCount`). When a page route is popped by the app (`BackGuardObserver.didPop`, not during a browser move), it checks the entry two steps back; if it shows the same page as now, it calls `history.go(-2)`. One close can be reported by two navigators, so only one check runs at a time. Pages opened from a link (no entry behind) are left alone.
- **Fixed app bar in the pager:** the root pages of the four bottom-bar sections use `SectionAppBar` (`core/router/section_app_bar.dart`). Outside the pager it is a normal `AppBar`; inside, the page keeps an empty space of the bar's height and registers its leading / title / actions in `SectionBars`; `ShellPager` draws a fixed background bar (`kBarShadow`) and every section's bar on top, faded by the page distance. (Drawing them inside the pages does not work: each branch navigator's overlay clips them.) The bar is hidden (Offstage, never removed, so the pager keeps its place in the tree) when the current section is not on its first screen.
- **Reset on leave:** `AppShell._go` puts a bottom-bar section that is left on an inner page back on its list first (`goBranch(current, initialLocation: true)`, then the target after a frame). A swipe also lands on a section's list if it was left elsewhere.
- **Animations in hidden sections keep running** (no `TickerMode(false)` for the pager), so a press highlight never freezes and shows on return.
- **Search reset:** `sectionLeftProvider` (`core/router/section_events.dart`) is bumped after a frame when the current branch changes; lists use `ref.onSectionLeft(path, …)` to clear their search. `SearchField` (`core/widgets/search_field.dart`) is the shared search box with ✕.
- **Back button:** Android predictive back is turned off (`android:enableOnBackInvokedCallback="false"` in the manifest) so every back goes through Flutter's handling. On web, `BackGuard` closes the drawer / dialog and then steps the browser **forward** to the entry it was on (`history.go(1)`) instead of adding an entry (Chrome on Android skips entries added without a tap).
- **Money:** `Fmt.money` rounds to paise (half up) and shows paise only when there are some.
- **Skeletons:** `PagedList(skeleton:)` takes the list's own `SkeletonRows` shape; `SkeletonText` shows a line with real words and placeholder numbers. Home's skeleton is the real layout with `loading: true` on `HeroCard` / `KpiChip`.
- **Swipe pager:** the `StatefulShellRoute` uses `navigatorContainerBuilder` → `ShellPager` (`core/router/shell_pager.dart`). Phone / tablet: the 4 primary branch navigators are in a `PageView` (kept alive, `allowImplicitScrolling` so neighbours are built ahead; primary branches use `preload: true`). Swiping is enabled only when the location is the section's root path. A swipe calls `goBranch(i)` (keeps the branch's stack); a bottom-bar tap animates the pager. Drawer sections and desktop use an `IndexedStack`. FABs have their own `heroTag` (`fab-<section>`) because several sections are alive at once.
- Haptics: `HapticFeedback.selectionClick` on the attendance switch, `heavyImpact` when an optimistic delete is undone.


Implements 04-UI-UX §5–§8:
- `AppTokens` as a `ThemeExtension` holding all semantic colors. There are 10 combinations (5 accents × light/dark).
- `ThemeController` (Riverpod) holds `themeMode`, `accent` and `fontScale`, caches them in `shared_preferences`, and loads them **before `runApp`** so there is no flash of the wrong theme.
- **Theme mode and accent are saved to the account** (`users.theme_mode`, `users.accent_color`) with `PUT /auth/preferences` when changed. After login and on `/auth/me`, the app applies the account values and updates the local cache, so the theme follows the user to every device. Font size stays local.
- Widgets use `context.tokens.xxx` only. No hard-coded colors.

### 7.7 Localization and formatting

- ARB files for English and Bengali (`flutter gen-l10n`).
- Money: `NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)` in lists and 2 decimals on receipts → `₹1,00,000`.
- Dates: `dd MMM yyyy`, plus "Today" / "Yesterday" (compared with the factory date from `X-Business-Date`, see §4.3).
- A `BusinessDate` provider keeps the latest `X-Business-Date` (read by a Dio interceptor) and is the only source of "today" in the app. Timestamps are converted with `toLocal()`; business dates are never converted.

### 7.8 Receipts and exports

Receipt PDFs and report exports are generated **in the app** (`pdf` / `excel`) from data the API already returns. They are shared with `share_plus` or printed with `printing`, so the server needs no PDF engine. PDFs use Inter for Latin text. The `pdf` package cannot shape Bengali (vowel signs and conjuncts come out in the wrong order), so `PdfText` (`core/pdf/pdf_text.dart`) lays out any text with Bengali letters with Flutter's own text engine (Hind Siliguri) and places it as a 4× image; Latin text and numbers stay real PDF text. On the web the Excel file is downloaded and the receipt PDF too.

### 7.9 Platform notes

| Platform | Notes |
|---|---|
| Android | minSdk 26, internet permission, `REQUEST_INSTALL_PACKAGES` (for in-app update), FileProvider for the APK |
| Web | Built with `flutter build web`. Secure storage falls back to browser storage |
| Windows | `flutter build windows`, packaged with **Inno Setup** into `FlyAsh-Setup-<version>.exe` |

## 8. App Update System

### 8.1 Server side

Table `app_versions`: `platform` (android/windows/web), `version_name` (`1.2.0`), `build_number` (`12`), `min_supported_build`, `download_url`, `release_notes`, `is_active`, `created_at`.

`GET /app/version?platform=android&build=10` returns:

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
    "download_url": "https://api.<domain>/downloads/flyash-1.2.0.apk",
    "release_notes": "Sales report export added"
  }
}
```

`force_update = build < min_supported_build`.

Publishing a release:
1. Upload the file to `/var/www/flyash/downloads/` (served by Nginx).
2. Run `node ace app:release --platform=android --version=1.2.0 --build=12 --min-build=10 --url=... --notes="..."`.

### 8.2 Client side

| Platform | Flow |
|---|---|
| Android | On launch → check → dialog (optional) or blocking screen (forced) → download the APK with Dio and a progress bar into the app's temporary folder (`path_provider`) → `open_filex` opens the system installer (the user approves "Install unknown apps" once). The manifest declares `INTERNET` and `REQUEST_INSTALL_PACKAGES` |
| Windows | Same check → download the `.exe` into the temp folder with progress → launch the installer → `exit(0)`. The Inno Setup installer upgrades in place |
| Web | Check `platform=web` → if newer, the same dialog with **Reload** → `location.reload()`. Nginx serves `index.html`, `flutter_bootstrap.js`, `main.dart.js`, `flutter_service_worker.js` and `version.json` with `no-cache`, so the reload gets the new files |

Version source: `pubspec.yaml` `version: 1.2.0+12` (`+12` = build number), read with `package_info_plus`.

Code (F18): `features/update/` — `UpdateRepository` (`GET /app/version`, never from the cache), `UpdateController` (the found update), `UpdateGate` (wraps the app in `MaterialApp.builder`: start-up check, forced screen in place of the app, dialog on the router's navigator once the splash is gone), `UpdateRun` (download progress, cancel, retry), `UpdateInstaller` (download / install / reload; replaced in tests).

**Receipt → customer's WhatsApp (Android):** `MainActivity.kt` handles the method channel `flyash/whatsapp` (`sendFile`: path, phone, text). The PDF is written to `cache/receipts/` and shared through the app's `FileProvider` (`${applicationId}.fileprovider`, `res/xml/share_paths.xml`; `androidx.core` dependency) with an `ACTION_SEND` intent to `com.whatsapp`, then `com.whatsapp.w4b`, carrying the extra `jid = 91<number>@s.whatsapp.net` so the customer's chat opens directly. Returns `sent` / `not_installed`. Web and Windows fall back to saving the PDF + `wa.me/91<number>?text=…`.

**Android release build (F19):** `--target-platform android-arm,android-arm64 --obfuscate --split-debug-info=build/symbols/<version>` → about 40 MB (x86_64 is left out: only PC emulators use it; 32-bit ARM phones still work). Keep `build/symbols/<version>` to read crash stack traces (`flutter symbolize`). For an x86_64 emulator test add `android-x64`. `res/xml/network_security_config.xml` allows plain HTTP only to `10.0.2.2` and `localhost` (the PC's dev server); everything else is HTTPS.

**Android signing:** release APKs are signed with the FlyAsh release key (`app/android/app/flyash-release.jks` + `app/android/key.properties`, both git-ignored; Gradle falls back to the debug key when they are missing). **Every update must be signed with the same key**: keep a backup of both files outside the PC. An APK signed with another key cannot install over the app (the phone must uninstall first).

## 9. Development Environment (Windows + XAMPP)

| Item | Setup |
|---|---|
| Database | Start **MySQL (MariaDB)** from the XAMPP Control Panel. Apache is not needed. Create the DB `flyash` (utf8mb4) in phpMyAdmin |
| Backend | `cd backend && npm install && node ace migration:run && node ace db:seed && node ace user:create && npm run dev` → `http://localhost:3333` |
| App, Web | `flutter run -d chrome --web-port 5000 --dart-define=API_BASE_URL=http://localhost:3333/api/v1` |
| App, Windows | `flutter run -d windows --dart-define=API_BASE_URL=http://localhost:3333/api/v1` |
| App, Android emulator | `--dart-define=API_BASE_URL=http://10.0.2.2:3333/api/v1` |
| App, real phone | Use the PC's LAN IP (`http://192.168.x.x:3333/api/v1`) and allow port 3333 in Windows Firewall. Android needs `usesCleartextTraffic` in **debug only** |

Notes: XAMPP usually ships an older MariaDB (10.4). The schema uses only features that work on both 10.4 and 11.4. Keep XAMPP's MariaDB on port 3306.

## 10. Production Deployment (VPS)

| Step | Detail |
|---|---|
| Server | Ubuntu 24.04 LTS, minimum 1 vCPU / 2 GB RAM / 25 GB SSD |
| Install | Node LTS, PM2, Nginx, MariaDB 11.4, certbot, git |
| Domains | `api.<domain>` → Adonis, `app.<domain>` → Flutter web build |
| Backend deploy | `git pull` → `npm ci` → `node ace build` → `cd build && npm ci --omit=dev` → `node ace migration:run --force` → `pm2 reload flyash-api` |
| Web deploy | `flutter build web --release --dart-define=API_BASE_URL=https://api.<domain>/api/v1` → copy `build/web` to `/var/www/flyash/web` |
| Nginx | Reverse proxy to `127.0.0.1:3333`, `client_max_body_size 10M`, gzip, static `/downloads`, SPA fallback for web (`try_files $uri $uri/ /index.html`, required because the app uses clean URLs without `#`) |
| SSL | `certbot --nginx` for both domains, auto-renew |
| Firewall | UFW: allow 22, 80, 443 only. MariaDB listens on localhost only |
| DB user | A dedicated `flyash` user with rights on the `flyash` DB only (not root) |
| **Backups** | Nightly cron: `mysqldump` + gzip of the DB → `/var/backups/flyash`, keeping 30 days. Optional weekly copy off the server |
| Logs | PM2 logs with logrotate. Adonis logger (pino) at `info` in prod |
| Process | PM2 `ecosystem.config.cjs`, `pm2 startup` so the API restarts after a reboot |

## 11. Testing

Only what protects the money logic:

| Where | What |
|---|---|
| Backend (Japa) | Functional tests for `SaleService` (totals, tax, payments, status, edit/cancel rules), `WageService` (daily/monthly, present days, payments), the net profit report, and the response format + pagination |
| Flutter | Unit tests for money formatting, JSON parsing of `ApiResponse` / `Paginated`, and the sale form calculations shown live |
| Manual | A smoke test checklist per release on Android, Web and Windows |

## 12. Coding Conventions

- **Backend:** ESLint + Prettier (Adonis defaults). Controllers stay under about 100 lines, and logic moves to a service only when it is reused or complex.
- **Flutter:** `flutter_lints`, `dart format`. Files `snake_case.dart`, one widget per file for pages.
- **API fields** are `snake_case`. Dart models map them to `camelCase` via `json_serializable` (`fieldRename: FieldRename.snake`).
- **Git:** `main` stays deployable. Short-lived branches per feature, with Conventional Commit messages (`feat:`, `fix:`, `docs:`).
- **Secrets** are never committed (`.env` is git-ignored, `.env.example` is committed).

## 13. Future Technical Considerations (not in v1)

- **Offline entry (Phase 2):** local SQLite (`drift`) + an outbox queue. Records get a client UUID so sync is safe to retry.
- **iOS / macOS:** the same Flutter code. Needs a Mac and an Apple Developer account.
- **Roles and permissions:** add a `role` column to `users` and a permission check in middleware. `created_by` already exists on records.
