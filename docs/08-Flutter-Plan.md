# 08 · Flutter App Plan: FlyAsh

| | |
|---|---|
| **Document** | Step-by-step build plan for the Flutter app (Android · Web · Windows) |
| **Version** | 1.0 |
| **Date** | 2026-11-08 |
| **Related docs** | 02-TRD §7 (Flutter architecture) · 03-AppFlow · 04-UI-UX-Design-Brief · 07-API-Reference |

The app is built **one small step at a time**. Each step ends with a working app, a quick check on Web and Windows (Android once the SDK licenses are accepted), and a git commit. The next step starts only after the current one is reviewed.

**Definition of done for every step**

1. `flutter analyze` and `flutter test` pass.
2. Checked on Web and Windows (Android once the SDK licenses are accepted).
3. **Responsive:** checked at **360 px** (small phone), **800 px** (tablet) and **1440 px** (desktop) wide, following 04-UI-UX §11 (bottom nav / rail / sidebar, cards on phones, tables on desktop, forms max 560 px wide). No overflow, no horizontal scroll.
4. Checked in **light and dark** mode and at least 2 accent colors.
5. Committed to git.

---

## Steps

| # | Step | Result you can see | Depends on |
|---|---|---|---|
| **F0** ✅ | **Setup** | Empty app with the FlyAsh logo runs on Web and Windows; folders, packages, app icon, run commands | — |
| **F1** ✅ | **Theme & design tokens** | 5 accents × light/dark, fonts (Inter + Hind Siliguri), a debug "gallery" screen to switch themes | F0 |
| **F2** ✅ | **Core widgets** | Hero card, KPI chip, status pill, buttons, inputs, empty/error/loading states in the gallery | F1 |
| **F3** ✅ | **Networking** | Dio client, `{ success, status_code, message, data }` parsing, errors, pagination helper, `Accept-Language` + token + `X-Business-Date` handling | F0 |
| **F4** ✅ | **Routing & app shell** | go_router, bottom nav (phone) / rail (tablet) / sidebar (desktop), drawer, placeholder screens | F2 |
| **F5** ✅ | **Localization & preferences** | English/Bengali ARB files, language + theme controller (cached locally, synced with `PUT /auth/preferences`) | F1, F3 |
| **F6** ✅ | **Auth** | Splash, Login, Forgot password (3 screens), logout, session expiry (401) | F3, F4, F5 |
| F7 | Profile, Users, Settings | My profile, change password, users list/add/edit, Settings (factory profile, appearance, language) | F6 |
| F8 | Products | List, add/edit, activate/deactivate, delete | F6 |
| F9 | Customers | List with dues, add/edit, detail with sales | F6 |
| F10 | Sales: list & detail | Sales list with filters, sale detail, upcoming deliveries | F8, F9 |
| F11 | Sales: form & payments | New/edit sale and booking, inline customer, live totals, add/remove payment, deliver, cancel | F10 |
| F12 | Labours & attendance | Labours list/form/detail, attendance screen with P/H/A toggles | F6 |
| F13 | Wages & advances | Wage sheet, labour wage detail, give advance, pay wages | F12 |
| F14 | Expenses | Expense list with totals, form, categories | F6 |
| F15 | Dashboard | Home screen with all cards and quick actions | F11, F13, F14 |
| F16 | Reports & export | 6 reports with charts and tables, PDF/Excel export | F15 |
| F17 | Receipt PDF | Sale receipt with the logo: share (WhatsApp), print, save | F11 |
| F18 | App update | Version check, optional/forced update for Android, Windows, Web | F6 |
| F19 | Polish & release builds | Accessibility pass, performance, APK, Windows installer, web build | all |

---

## F0 · Setup (details)

- [x] Create the Flutter project in `app/` for **android, web, windows** (package `flyash`, Android application id `com.flyash.app`, app name **FlyAsh**)
- [x] Clean Architecture folders (02-TRD §7.1): `lib/core/…`, `lib/features/…`
- [x] Base packages: Riverpod (plain providers, no code generation), Dio, go_router, freezed / json_serializable, secure storage, shared_preferences, intl + flutter_localizations, decimal; dev: build_runner, freezed, json_serializable, flutter_launcher_icons. (Feature packages such as `pdf`, `fl_chart`, `excel` are added in their own steps.)
- [x] Environment config: `API_BASE_URL` via `--dart-define` (dev default `http://localhost:3333/api/v1`)
- [x] Logo in `assets/images/logo.png`; app icon for Android, Web and Windows generated from it
- [x] Placeholder home screen showing the logo, the app name and the API URL
- [x] Lints, `flutter analyze` clean, a smoke widget test
- [x] `app/README.md` with run commands
- [x] Check: runs on Chrome and Windows

**Done when:** `flutter analyze` and `flutter test` pass, and the placeholder screen opens on Web and Windows.

---

## Notes

- **Android:** SDK licenses accepted; the first debug APK built on 2026-11-08.
- **Live API tests** (backend running): `flutter test test/integration --dart-define=LIVE_API=true`. Each run makes 2 wrong-password attempts; the login limit is 5 per 15 minutes.
- **Commands** always pass the API URL: `--dart-define=API_BASE_URL=...` (emulator: `http://10.0.2.2:3333/api/v1`, real phone: the PC's LAN IP).
- **Translations:** add every new UI string to both `app/lib/l10n/app_en.arb` and `app_bn.arb` (a test checks both files have the same keys). Numbers and dates stay in Latin digits.
- **Logo colors** (teal, slate, orange, leaf green) sit well with the Emerald and Ash Slate accents; the default accent stays Royal Blue unless changed in F1.
