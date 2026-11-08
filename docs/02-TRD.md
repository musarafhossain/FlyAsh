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
| Frontend | **Flutter** (latest stable, Dart 3), one codebase for **Android, Web and Windows** |
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

- All business calculations (totals, profit, dues, wages, net profit) run **on the server**. The app only displays them.
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
- Language header: `Accept-Language: en` (default) or `bn`. Every `message` (success, errors, validation errors and field names) comes back in that language, with a `Content-Language` header. Translations live in `backend/resources/lang/{en,bn}/messages.json` and `validator.json`; code uses message keys (`sales.saved`), never raw text
- Dates `YYYY-MM-DD`; timestamps ISO-8601 in UTC (`2026-11-08T06:30:00.000Z`)
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

### 4.3 Pagination, search and filters

- Query params: `page` (default `1`), `limit` (default `20`, max `100`)
- Search: `search=<text>`
- Filters: plain params, for example `status=due&type=booking&from=2026-11-01&to=2026-11-30`
- Sorting: a sensible default per list (newest first). Optional `sort=name&order=asc` only where the UI needs it.

### 4.4 Endpoints (v1)

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
| | `POST /customers` · `GET/PUT/DELETE /customers/:id` | CRUD (delete only if no sales) |
| | `PATCH /customers/:id/status` | Activate / deactivate |
| | `GET /customers/:id/sales` | That customer's sales, paginated |
| **Sales** | `GET /sales` | List (search, type, status, from, to), paginated |
| | `POST /sales` | Create (customer_id **or** new_customer, items[], charges, initial payment) |
| | `GET/PUT/DELETE /sales/:id` | View / edit / soft delete |
| | `POST /sales/:id/deliver` | Booking → delivered (`delivered_date`) |
| | `POST /sales/:id/cancel` | Booking → cancelled |
| | `POST /sales/:id/payments` · `DELETE /sales/:id/payments/:paymentId` | Add / remove payment |
| | `GET /sales/upcoming-deliveries` | Booked, not delivered, paginated |
| **Labours** | `GET /labours` | List (search, `active`), paginated |
| | `POST /labours` · `GET/PUT /labours/:id` | Create / view / update |
| | `PATCH /labours/:id/status` | Deactivate (with `left_date`) / activate |
| **Attendance** | `GET /attendance?date=2026-11-08` | Active labours on that date + saved status |
| | `PUT /attendance` | Save one day: `{ date, records: [{ labour_id, status }] }` |
| | `GET /labours/:id/attendance?month=2026-11` | Monthly calendar for one labour |
| **Wages** | `GET /wages?month=2026-11` | Wage sheet for all labours, paginated |
| | `GET /labours/:id/wages?month=2026-11` | Detailed breakdown for one labour |
| | `GET/POST /labours/:id/advances` · `DELETE /advances/:id` | Advances |
| | `POST /labours/:id/wage-payments` · `DELETE /wage-payments/:id` | Wage payments |
| **Expenses** | `GET /expenses` | List (from, to, category_id), paginated, plus `period_total` |
| | `POST /expenses` · `GET/PUT/DELETE /expenses/:id` | CRUD |
| | `GET/POST /expense-categories` · `PUT /expense-categories/:id` | Categories |
| **Reports** | `GET /reports/sales?from&to` | Totals, by product, daily series |
| | `GET /reports/dues` | Customers with dues, paginated |
| | `GET /reports/expenses?from&to` | Totals by category |
| | `GET /reports/wages?month` | Wage summary |
| | `GET /reports/net-profit?from&to` | Profit − expenses − wages, monthly series |
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
| `SaleService` | Create and update a sale in **one DB transaction**: snapshot line prices, compute subtotal/total/cost/profit, record the initial payment, recompute `paid_amount`, `due_amount` and `payment_status`. Generate the invoice number. Enforce the rules in PRD §6.1–6.2 |
| `WageService` | Monthly wage sheet from attendance snapshots, advances and payments (PRD §6.3) |
| `ReportService` | Aggregate SQL queries for each report |
| `DashboardService` | One method returning every dashboard number |

Stored totals (`total`, `paid_amount`, `due_amount`, `profit`) are kept on the `sales` row and recomputed by `SaleService` whenever items or payments change. This keeps lists and reports fast and simple.

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
  6. Email is sent with **`@adonisjs/mail`** over SMTP (Gmail with an App Password, or any SMTP provider). The template contains the factory name, the OTP, "valid for 10 minutes" and "ignore this email if you did not ask for it", in English + Bengali.
  7. In development `MAIL_MAILER=log` prints the email (and OTP) to the console, so no real email is needed.
- Passwords hashed with **scrypt** (the Adonis default).
- **Users:** there are no roles, and every authenticated user can call every endpoint. There is no sign-up endpoint. The first user is created with `node ace user:create`, and a forgotten password can be reset on the server with `node ace user:reset-password <phone>`.
- Deactivating a user or resetting their password **deletes all of their access tokens**, so they are logged out everywhere. The auth middleware also rejects tokens of inactive users.
- `created_by` is set explicitly from `auth.user` in controllers and services on sales, payments, expenses, advances, wage payments and attendance.
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
| Primary keys | `id INT UNSIGNED AUTO_INCREMENT` |
| Names | `snake_case`, plural table names |
| Timestamps | `created_at`, `updated_at` on every table |
| **Money** | `DECIMAL(12,2)`, never FLOAT/DOUBLE |
| Quantity | `DECIMAL(12,2)` (allows fractional trucks) |
| Soft delete | `deleted_at` on `sales`. `is_active` on products, customers, labours, expense categories |
| Foreign keys | Always, with `ON DELETE RESTRICT` |
| Uniques | `users.phone`, `users.email`, `customers.phone`, `products.name`, `attendances(labour_id, date)`, `sales.invoice_no` |
| Audit | `created_by` (FK → `users.id`) on business records |
| Migrations | Every schema change is a Lucid migration. Never edit the DB by hand |

Main tables: `users`, `auth_access_tokens`, `password_reset_otps`, `factory_settings`, `products`, `customers`, `sales`, `sale_items`, `sale_payments`, `labours`, `attendances`, `labour_advances`, `wage_payments`, `expense_categories`, `expenses`, `app_versions`.

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
| State / DI | `flutter_riverpod` (+ `riverpod_annotation`, `riverpod_generator`) |
| HTTP | `dio` |
| Routing | `go_router` |
| Models | `freezed`, `json_serializable`, `build_runner` |
| Secure token storage | `flutter_secure_storage` |
| Preferences (theme, locale) | `shared_preferences` |
| Formatting & i18n | `intl`, `flutter_localizations` |
| Decimal money | `decimal` |
| PDF / print / share | `pdf`, `printing`, `share_plus` |
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

One reusable `PaginatedListView<T>` widget + a `PaginatedNotifier<T>` base class:
- Loads `page=1&limit=20`, then the next page when the user scrolls near the end, while `hasMore`.
- Pull to refresh resets to page 1. Search and filter changes reset to page 1 (search is debounced 400 ms).
- Built-in loading skeleton, empty state, error + retry, and a "loading more" footer.

### 7.5 Theming

Implements 04-UI-UX §5–§8:
- `AppTokens` as a `ThemeExtension` holding all semantic colors. There are 10 combinations (5 accents × light/dark).
- `ThemeController` (Riverpod) holds `themeMode`, `accent` and `fontScale`, saves them in `shared_preferences`, and loads them **before `runApp`** so there is no flash of the wrong theme.
- Widgets use `context.tokens.xxx` only. No hard-coded colors.

### 7.6 Localization and formatting

- ARB files for English and Bengali (`flutter gen-l10n`).
- Money: `NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)` in lists and 2 decimals on receipts → `₹1,00,000`.
- Dates: `dd MMM yyyy`, plus "Today" / "Yesterday".

### 7.7 Receipts and exports

Receipt PDFs and report exports are generated **in the app** (`pdf` / `excel`) from data the API already returns. They are shared with `share_plus` or printed with `printing`, so the server needs no PDF engine.

### 7.8 Platform notes

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
| Android | On launch → check → dialog (optional) or blocking screen (forced) → download the APK with Dio and a progress bar into app storage → `open_filex` opens the system installer (the user approves "Install unknown apps" once) |
| Windows | Same check → download the `.exe` into the temp folder with progress → launch the installer → `exit(0)`. The Inno Setup installer upgrades in place |
| Web | Check `platform=web` → if newer, show the banner "New version available · Reload" → reload, bypassing the cache. Nginx serves `index.html` / `flutter_service_worker.js` with `no-cache` |

Version source: `pubspec.yaml` `version: 1.2.0+12` (`+12` = build number), read with `package_info_plus`.

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
| Nginx | Reverse proxy to `127.0.0.1:3333`, `client_max_body_size 10M`, gzip, static `/downloads`, SPA fallback for web |
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
| Backend (Japa) | Functional tests for `SaleService` (totals, profit, payments, status, edit/cancel rules), `WageService` (daily/monthly, half day, advances), the net profit report, and the response format + pagination |
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
