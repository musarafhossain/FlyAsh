# FlyAsh API (backend)

AdonisJS 7 + MariaDB REST API for the FlyAsh app. See `../docs` for the full documents
(02-TRD for API standards, 05-Backend-Schema for tables and data contracts).

## Requirements

- **Node.js 24+** (AdonisJS 7 requires it)
- MariaDB 10.4+ (XAMPP in development, 11.4 LTS in production)

## First-time setup (development)

1. Start **MySQL** from the XAMPP Control Panel (Apache is not needed).
2. Create the databases (phpMyAdmin or the command line):
   ```sql
   CREATE DATABASE flyash CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   CREATE DATABASE flyash_test CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   ```
3. Install and configure:
   ```bash
   npm install
   cp .env.example .env
   node ace generate:key
   ```
4. Create the tables, default data and the first user:
   ```bash
   node ace migration:run
   node ace db:seed          # categories, factory profile, sample data (development only)
   node ace user:create      # asks for name, phone, email, password
   ```
5. Run:
   ```bash
   npm run dev               # http://localhost:3333/api/v1/health
   ```

## Commands

| Command | Purpose |
|---|---|
| `npm run dev` | Dev server with hot reload |
| `node ace test` | Run all tests (uses the `flyash_test` database) |
| `npx tsc --noEmit` | Type check |
| `node ace migration:run` | Apply new migrations (also regenerates `database/schema.ts`) |
| `node ace migration:fresh --seed` | Drop everything and rebuild with sample data (dev only) |
| `node ace user:create` | Create a user (the app has no sign-up screen) |
| `node ace user:reset-password <phone or email>` | Reset a password and log the user out everywhere |
| `node ace app:release --platform=android --version=1.2.0 --build=12 --min-build=10 --url=... --notes="..."` | Publish an app update |

## Project layout

```
app/
  controllers/   thin HTTP layer: validate → model/service → standard response
  services/      business logic: sales, wages, reports, dashboard, mail
  models/        Lucid models (columns come from database/schema.ts)
  validators/    VineJS schemas (rules.ts holds the shared rules)
  helpers/       api_response (envelope), money (paise maths), dates (IST), uploads
  exceptions/    handler.ts maps every error to the envelope; AppError for business rules
commands/        user:create, user:reset-password, app:release
database/        migrations, seeders, generated schema.ts (do not edit by hand)
start/           routes.ts, kernel.ts, limiter.ts, defaults.ts (UTC + snake_case JSON)
tests/functional one spec per module
```

## Conventions

- Every response: `{ success, status_code, message, data }`. Lists: `data = { items, page, limit, total, last_page }`.
- JSON keys are `snake_case`. Money is a string with 2 decimals (`"1500.00"`). Dates are `YYYY-MM-DD`.
- Money maths uses integer paise (`app/helpers/money.ts`), never floats.
- "Today" and months use `APP_TIMEZONE` (Asia/Kolkata). Timestamps are stored in UTC.
- `created_by` is set explicitly from `auth.user` in controllers and services.
- In development `MAIL_MAILER=log` prints emails (password reset OTPs) to the console.
