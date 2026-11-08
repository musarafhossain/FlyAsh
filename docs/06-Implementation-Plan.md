# 06 · Implementation Plan: FlyAsh

| | |
|---|---|
| **Document** | Step-by-step build plan for v1 |
| **Version** | 1.0 |
| **Date** | 2026-11-08 |
| **Related docs** | 01-PRD · 02-TRD · 03-AppFlow · 04-UI-UX-Design-Brief · 05-Backend-Schema |

---

## 1. Approach

- **Vertical slices:** each module is built end to end (migration → API → Flutter screens → test), so something usable exists after every step.
- **Foundation first:** response format, auth, theme, networking and pagination are built once in Steps 1–3 and reused everywhere.
- **One step = one or more git commits.** A step is "done" only when its checklist passes.
- Backend: `F:\FlyAsh\backend` · App: `F:\FlyAsh\app` · Docs: `F:\FlyAsh\docs`.

## 2. Step Overview

| Step | Name | Depends on | Size |
|---|---|---|---|
| 0 | Project setup | — | S |
| 1 | Backend foundation | 0 | M |
| 2 | Backend auth, users, password reset | 1 | M |
| 3 | Flutter foundation (theme, router, network, widgets) | 0 | L |
| 4 | Flutter auth, profile, users | 2, 3 | M |
| 5 | Products | 3 | S |
| 6 | Customers | 3 | S |
| 7 | Sales (core) | 5, 6 | L |
| 8 | Sales extras: payments, bookings, receipt PDF | 7 | M |
| 9 | Labours & attendance | 3 | M |
| 10 | Wages & advances | 9 | M |
| 11 | Expenses & uploads | 3 | M |
| 12 | Dashboard | 7, 9, 11 | S |
| 13 | Reports & export | 8, 10, 11 | M |
| 14 | Settings, factory profile, localization | 4 | M |
| 15 | App update system | 14 | M |
| 16 | Testing, polish & QA | all | M |
| 17 | VPS deployment & first release | 16 | M |

S = about 1–2 days, M = about 3–4 days, L = about 5–7 days (one developer).

---

## 3. Steps in Detail

### Step 0 · Project setup
- [ ] `git init` in `F:\FlyAsh`, `.gitignore` (node_modules, build, .env, .dart_tool …), first commit with `docs/`
- [ ] XAMPP: start MySQL (MariaDB), create the DB `flyash` with `utf8mb4_unicode_ci`
- [ ] Create the Adonis API project in `backend/` (AdonisJS 7 API starter on Node 24, Lucid with mysql2, auth with access tokens, VineJS)
- [ ] Create the Flutter project in `app/` (`--platforms=android,web,windows`, org `com.flyash`)
- [ ] `.env.example` for the backend, `README.md` per project with run commands

**Done when:** `npm run dev` serves `GET /` on :3333, and `flutter run -d chrome` and `-d windows` show the default app.

### Step 1 · Backend foundation
- [ ] `helpers/api_response.ts` (`ok`, `paginated`, `fail`) exactly as in TRD §5.2
- [ ] Exception handler: 422 / 404 / 401 / 429 / 400 / 409 / 500 → the standard envelope
- [ ] `force_json` middleware, CORS config, `APP_TIMEZONE` date helper ("today" in IST)
- [ ] Shared VineJS rules: phone, money, pagination (`page`, `limit` ≤ 100)
- [ ] `GET /api/v1/health`
- [ ] All migrations from 05-Backend-Schema §3 + seeders (categories, factory settings)
- [ ] Japa setup + a test for the response format and pagination meta

**Done when:** `node ace migration:fresh --seed` builds all 16 tables, and `/health` returns the envelope.

### Step 2 · Backend auth, users, password reset
- [ ] `User` model, access tokens (no expiry), `node ace user:create`, `node ace user:reset-password`
- [ ] `POST /auth/login` (phone or email), `logout`, `GET/PUT /auth/me`, `PUT /auth/password` (revokes the other tokens)
- [ ] Auth middleware rejects inactive users. `last_login_at` is updated on login
- [ ] Limiter on login (5 / 15 min)
- [ ] `/users` CRUD, status and password reset. Excludes / blocks your own id. Revokes tokens on deactivate or reset
- [ ] `@adonisjs/mail` (log mailer in dev), `password_reset_otps`, `forgot-password` → `verify-otp` (signed `reset_token` via `encryption.verifier`) → `reset-password`
- [ ] `created_by` auto-fill hook (a reusable mixin)
- [ ] Tests: login, inactive user 401, OTP wrong-attempts, expired or used reset token

**Done when:** the whole auth + users API works in an HTTP client (Bruno / Postman collection saved in `backend/api-collection/`).

### Step 3 · Flutter foundation
- [ ] Folder structure from TRD §7.1. Packages from TRD §7.2. `build_runner` set up
- [ ] **Theme:** tokens, 5 accents × light/dark, `ThemeController` (saved and loaded before `runApp`), font scale, Inter + Hind Siliguri bundled
- [ ] **Core widgets** (04-UI-UX §9): AppBar variants, HeroCard, KpiChip, QuickActionTile, SearchBar, StatusPill, SegmentedTabs, PeriodSelector, ProgressRing, LineItemSummaryCard, buttons, inputs (money, stepper, date), EmptyState, ErrorState, Skeleton, ConfirmDialog
- [ ] **Widget gallery** page (debug only) showing every widget in all 10 theme combinations
- [ ] **Network:** Dio client, auth interceptor, `ApiResponse<T>`, `Paginated<T>`, `Failure` mapping, `Result<T>`
- [ ] **Pagination:** `PaginatedNotifier<T>` + `PaginatedListView<T>` (infinite scroll, refresh, search debounce)
- [ ] **Router:** go_router with shell + bottom nav / rail / sidebar (responsive), auth redirect
- [ ] **l10n:** ARB en/bn scaffolding. **Utils:** ₹ formatting (`en_IN`), dates
- [ ] Tests: money format, `ApiResponse` / `Paginated` parsing

**Done when:** the gallery looks right in all themes on Android, Web and Windows, and an empty shell with 5 tabs navigates correctly.

### Step 4 · Flutter auth, profile, users
- [ ] Splash (theme + token + `/auth/me`), Login, Forgot password ① ② ③, Logout, global 401 handling
- [ ] My Profile (view, edit, change password)
- [ ] Users list (current user hidden), add, edit, reset password, activate / deactivate

**Done when:** every auth flow in 03-AppFlow §2 and §10 works against the local API.

### Step 5 · Products
- [ ] API: CRUD, status, delete-if-unused (409), search, pagination
- [ ] App: list, form, activate / deactivate, delete with the 409 message

### Step 6 · Customers
- [ ] API: CRUD, unique phone (422 with `existing_customer_id`), `total_due` subquery, `has_due` filter, `/customers/:id/sales`
- [ ] App: list with due, form, detail with summary strip and sales list, call / WhatsApp

### Step 7 · Sales (core)
- [ ] API: `SaleService` (transaction, snapshots, `recalculate()`, invoice no.), `POST/GET/PUT/DELETE /sales`, list filters, inline new customer
- [ ] Rules: total ≥ 0, paid ≤ total, edit rejected if the new total < paid
- [ ] App: sales list (tabs, filters, search), sale form (customer picker + inline add, items, live summary), sale detail
- [ ] Tests: every formula in 05 §4.1, the edit rule, the inline customer with a duplicate phone

**Done when:** an instant sale with 2 items, transport, discount and a partial payment shows the correct profit, due and status everywhere.

### Step 8 · Sales extras
- [ ] API: payments add / delete, `deliver`, `cancel` (blocked with payments), `upcoming-deliveries`
- [ ] App: add payment sheet, mark delivered, cancel, upcoming deliveries screen
- [ ] Receipt PDF (factory header + logo, items, totals, paid, due) → share / print / save
- [ ] Tests: status transitions, the overpayment block, booking revenue counted on the delivered date

### Step 9 · Labours & attendance
- [ ] API: labours CRUD + status (left date), `GET/PUT /attendance` with wage snapshot, labour monthly calendar
- [ ] App: labours list, form, detail. Attendance screen (date picker, P/H/A toggles, mark all, summary, save, unsaved-changes guard)

### Step 10 · Wages & advances
- [ ] API: `WageService` (05 §4.2), `/wages`, `/labours/:id/wages`, advances, wage payments
- [ ] App: wage sheet, labour wage detail, give advance, pay wage, delete entries
- [ ] Tests: daily vs monthly, half day, a mid-month wage change (snapshot), advances and balance status

### Step 11 · Expenses & uploads
- [ ] API: `POST /uploads` (image type and size checks, UUID names, `/uploads` static), expense categories, expenses CRUD + `period_total`
- [ ] App: expense list (period, category chips, total), form with category sheet and bill photo (camera / gallery / file picker on web and Windows), manage categories

### Step 12 · Dashboard
- [ ] API: `DashboardService` → `GET /dashboard` (05 §5.8)
- [ ] App: home header, hero, KPI row, quick actions, recent sales. Every card links to its screen

### Step 13 · Reports & export
- [ ] API: the 6 report endpoints (05 §5.9) using `ReportService`
- [ ] App: reports grid, report screen (period presets, summary, `fl_chart` chart, table), PDF + Excel export
- [ ] Test: net profit = sales profit − expenses − wages on sample data

### Step 14 · Settings, factory profile, localization
- [ ] API: `GET/PUT /settings/factory` (logo via `/uploads`)
- [ ] App: settings screen, factory profile, Appearance (04-UI-UX §8.1 with live preview), language switch
- [ ] Translate all strings to Bengali (`app_bn.arb`), and check layouts with long Bengali text and 1.3× font

### Step 15 · App update system
- [ ] API: `app_versions` + `GET /app/version`, `node ace app:release`
- [ ] App: check on launch + About screen, optional dialog, forced screen
- [ ] Android: APK download with progress + installer (`REQUEST_INSTALL_PACKAGES`, FileProvider)
- [ ] Windows: Inno Setup script (`app/windows/installer/flyash.iss`), EXE download + run + exit
- [ ] Web: reload banner, and `no-cache` headers for `index.html` and the service worker

**Done when:** installing build N and publishing build N+1 updates the app on Android and Windows, and the banner appears on Web.

### Step 16 · Testing, polish & QA
- [ ] All backend service tests pass (`node ace test`). Flutter tests pass (`flutter test`)
- [ ] Manual smoke test on Android (real low-end phone), Chrome, Windows, in light and dark mode, EN and BN
- [ ] Accessibility pass: contrast, 48 dp targets, screen reader labels, 1.3× text
- [ ] Error states: no internet, 500, 401 mid-session, slow network
- [ ] Performance: list first page < 1.5 s on 4G, no jank while scrolling

### Step 17 · VPS deployment & first release
- [ ] VPS: Ubuntu 24.04, Node LTS, PM2, Nginx, MariaDB 11.4, UFW, certbot (TRD §10)
- [ ] DB user `flyash`, production `.env` (SMTP with a Gmail App Password, `MAIL_MAILER=smtp`)
- [ ] Deploy the API (`node ace build`, migrations, `pm2 start`), `node ace user:create` for the first real user
- [ ] Deploy the web build to `app.<domain>`, set up `/downloads`
- [ ] Nightly backup cron (DB + uploads, 30 days) **and one test restore**
- [ ] Release v1.0.0+1: APK + Windows installer → `/downloads`, `node ace app:release` for android / windows / web
- [ ] Install on the owner's devices and walk through a real day (sales, attendance, expense)

---

## 4. Definition of Done (every step)

1. Works on **Android, Web and Windows** (or is explicitly platform-specific).
2. Matches 03-AppFlow (flows) and 04-UI-UX (visuals), in **light + dark** and at least 2 accents.
3. API responses follow the envelope. Lists are paginated with `page` / `limit`.
4. Money logic has passing tests.
5. No hard-coded colors or strings in the UI (tokens + ARB).
6. Committed to git with a clear message.

## 5. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| XAMPP MariaDB 10.4 vs production 11.4 differences | Use only portable SQL. Run the migrations on a 11.4 instance before going live |
| Android blocks APK install from the app | Explain the "Install unknown apps" permission in the UI before opening it, and keep the download URL as a fallback |
| Gmail SMTP limits or blocks | Use an App Password. Switch to a transactional SMTP provider if the volume grows |
| Money rounding errors | DECIMAL in the DB, strings in JSON, the `decimal` package in Dart, server as the single source of truth |
| Lost data on the VPS | Nightly backups + a monthly restore test + an optional off-site copy |
| Scope creep | New ideas go to the PRD "Later" list and are not added mid-step |
