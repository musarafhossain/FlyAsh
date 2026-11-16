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
| **F7** ✅ | **Profile, Users, Settings** | My profile, change password, users list/add/edit, Settings (factory profile, appearance, language) | F6 |
| **F8** ✅ | **Products** | List, read-only detail page, add/edit (name, price, notes: no unit, no cost), activate/deactivate, delete | F6 |
| **F9** ✅ | **Customers** | List with dues, add/edit (phone optional), detail with stat cards and sales | F6 |
| **F10** ✅ | **Sales: list & detail** | Sales list with filters, sale detail, upcoming deliveries | F8, F9 |
| **F11** ✅ | **Sales: form & payments** | New/edit sale and booking, inline customer, tax %, live totals, add/remove payment, deliver, cancel (actions in the ⋮ menu) | F10 |
| **F12** ✅ | **Labours & attendance** | Labours tab: list, form (wage type Daily/Monthly + wage amount required on create), detail; attendance screen with one Present switch per labour (saves at once; no half day) | F6 |
| **F13** ✅ | **Wages** | Labour wage detail (`/labours/:id/wages`), pay wages (no advances). The Wages tab / wage sheet was removed on 2026-11-16 (Reports → Wages was removed too, so no all-labours month view remains) | F12 |
| **F14** ✅ | **Expenses** | Expense list with the total, search and a filter sheet; form with a free-text category | F6 |
| **F15** ✅ | **Dashboard** | Home screen with all cards and quick actions (no greeting header) | F11, F13, F14 |
| **F16** ✅ | **Reports & export** | 6 reports with charts and tables, PDF/Excel export | F15 |
| **F17** ✅ | **Receipt PDF** | Sale receipt with the logo: share (WhatsApp), print, save | F11 |
| **F18** ✅ | **App update** | Version check, optional/forced update for Android, Windows, Web | F6 |
| **F19** ✅ | **Polish & release builds** | Accessibility pass, performance, APK (Windows installer dropped for now: APK only) | all |

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
- **Shared building blocks from F7** (use them in F8+): `PagedList` (paginated API list with skeleton, error + retry, empty state, pull to refresh, endless scroll; background `revalidate()` and optimistic patches, see 02-TRD §7.5), `DataTableCard` (desktop tables), `PageBody` (form/detail column, max 560/720 px), `MenuGroup`/`MenuRow`/`InfoRow`, `FormSubmit` mixin (validate → busy → 422 field errors / banner), `Validators` (phone, email, password, same-as), `showMessage`.
- **Money input:** use `MoneyField` + `Validators.money` (digits, up to 2 decimals, ₹ prefix). Values are sent as strings ("4.5"), never doubles; compute previews with `Decimal`.
- **Call / WhatsApp:** `ContactLauncher.call(phone)` / `.whatsApp(phone)` (tel:+91…, wa.me/91…); returns false when nothing can open it → show `couldNotOpen`. Tests replace `ContactLauncher.launch`.
- **Sale labels:** `SaleSummary` (sales/domain) and `SaleStatusPill` + `l.paymentStatusText / saleStatusText / saleTypeText` (sales/presentation/sale_labels.dart) are shared by every sale list.
- **Dates:** `Ymd` (core/utils/dates.dart) works on business-date strings; `DateRange.preset(...)` builds Today / This week / This month … from `businessDateProvider` (the factory's today), never the device clock.
- **Live API tests without the owner's password:** create a temporary user (`node ace user:create --phone=6000000099 …`), run with `--dart-define=LIVE_LOGIN=… --dart-define=LIVE_PASSWORD=…`, then reset `factory_settings.updated_by` and delete that user.
- **Pickers:** `showSearchPicker<T>()` (core/widgets/search_picker_sheet.dart) is a searchable, paginated bottom sheet (customers, products; reuse for labours).
- **Forms:** after save they pop back to the caller (the list, or the detail page for an edit opened there) and return the saved record; the caller reloads. A deep-linked form with nothing under it goes to the section's list.
- **Live-test cleanup also covers** `expenses` (created_by), `labours`, `attendances`, `wage_payments` (rows of the temporary user's labours). Ids are UUIDs, so there is no AUTO_INCREMENT to reset.
- **Live tests that create sales** cannot clean up through the API (records with sales are kept); afterwards delete the temporary user's rows from `sales`, `sale_items`, `sale_payments`, `customers`, `products`, `users` and set `factory_settings.last_invoice_no` back to its value before the run (invoice numbers come from that counter, not from an id). Locally, reseeding the database does the same.
- **Dates in forms:** `DateField` (core/widgets/date_field.dart) for any business-date input with first/last limits.
- **Shell branches** set `initialLocation: item.path`, so the route order inside a section never changes which page a sidebar tap opens.
- **Deep links with filters:** `/sales?period=today` and `/customers?filter=due` (used by Home). Shell root pages stay alive, so they apply a changed query in `didUpdateWidget`.
- **Changes after testing (2026-11):** shared pieces every section uses now:
  - Lists: `ListGroup(flat: true)` + `ListRowSurface(onLongPress:)`; long press calls `showActionMenu` (popup next to the row); no "Showing x of y".
  - Detail pages: ✏ Edit + `ActionMenuButton` (⋮) in the app bar; `PageBody(onRefresh:)` for pull to refresh; stat cards use `KpiChip`.
  - Skeletons (`core/widgets/skeletons.dart`): list (with the search box), detail and form skeletons; `KpiChip(loading:)`, `HeroCard(loading:)`.
  - Caching (02-TRD §7.5): `QueryCache` keeps GET answers 60 s by data tag (`DataTag`); a write invalidates only the affected tags and bumps them in `dataChangedProvider`. Screens use `ref.onDataChanged({DataTag.x}, …)` and lists `controller.revalidate()` (background reload, no skeleton). Pull to refresh / Retry run in `QueryCache.fresh`.
  - Optimistic updates: `ref.optimistic(id, preview, request)` / `ref.optimisticRemove(id, request)` (`core/network/optimistic.dart`); lists apply patches with `PagedList(itemId:)`, detail pages with `ref.patched(...)` / `ref.isRemoved(id)`. Models have `withActive(bool)` for the preview.
  - After save: create → list; edit → where it was opened from. Forms are popped, not stacked.
  - Section taps use `goBranch(index, initialLocation: true)`, so a section always opens its list.
  - Review fixes (2026-11-16): shared `confirmDelete` (dialog waits, no optimistic deletes), `SearchField` with ✕, `sectionLeftProvider` (search cleared on leave), `SectionAppBar` + `SectionBars` (fixed pager bar), `SkeletonRows` / `SkeletonText`, `CountUpText`, `CompactChoiceChip`, `LifetimeWageCard`, `Fmt.money` auto paise, `dialogButtonStyle` / `dialogTitleStyle` for every dialog. Tests: `review_fixes_test.dart`.
  - `WebHistorySync` (2026-11-16): on web, after the app pops a page the browser history steps back as well (02-TRD §7.6). Unit tests use a fake history (`web_history_sync_test.dart`); real check in headless Chrome.
  - `BackGuard` (2026-11-16): back closes the drawer / dialogs / sheets / menus first, also the browser back on web. New navigators need a `BackGuardObserver()` in their `observers`; tests simulate the browser back with a `pushRouteInformation` platform message (`back_button_test.dart`).
  - `ShellPager` (2026-11-16): swipe between the 4 bottom-bar sections on phone / tablet (02-TRD §7.6). Tests that scroll a page must name its own vertical `Scrollable` (the pager is a horizontal one), and finders may need `.hitTestable()` because neighbour sections are built.
  - `kStatusBarStyle`: black status bar. `togglePopover` (app_bar_actions.dart): language / appearance popovers with a 16 px edge gap.
- **Design principles pass (2026-11-16, 04-UI-UX §14):** `core/widgets/motion.dart` (`Motion` tokens, `PressScale`, `StaggeredEntrance`), `core/theme/oklch.dart` (avatar colours), `heroTag` on `ColorAvatar` / `InitialsAvatar` / `ProductIcon`, detail pages take `initial` from `push(extra: record)`, `PhoneInputFormatter` + `normalizePhone` (also on the API), typography tracking, dialogs at the optical centre, haptics.
- **Reports (F16, 2026-11-16):** `features/reports/` — `ReportsRepository` (6 endpoints; dues pages through `/reports/dues` with `grand_total`), `report_views.dart` turns each report into a `ReportView` (summary figures, one chart, tables) that both the screen (`ReportBody`) and the export use. The page keeps the raw data and builds the view in `build()`, so a language change shows at once. Charts: `fl_chart` bars (one series, no legend, tooltip, losses in the error colour under a zero line) and plain horizontal bars for categories / labours. Export (`report_export.dart`): `pdf` A4 with Inter + Hind Siliguri fallback (Bengali names) → `Printing.sharePdf`; `excel` .xlsx → `share_plus`. Home "Total due" opens `/reports/dues`. Tests: `test/features/reports_test.dart` (each report, period chips → from/to, wages month, dues → customer, export bytes, overflow 360/800/1440 light + dark).
- **Receipt PDF (F17, 2026-11-16):** `features/sales/presentation/receipt_pdf.dart` → `buildReceiptPdf(sale, factory, l, accent, generatedOn)`; sale detail ⋮ → Share receipt / Print receipt. Factory profile from `factorySettingsProvider`; accent = the owner's accent in light mode; money via `Fmt.moneyFixed` (2 decimals). Output through `ReceiptOutput.share` / `.print` (tests replace them). All app PDFs (receipts, report exports) take fonts from `core/pdf/pdf_theme.dart` and text from `core/pdf/pdf_text.dart` (`PdfText.build` + `pdfTable`), which draws Bengali with Flutter so it is shaped correctly. Tests: `test/features/receipt_test.dart`, `test/core/pdf_text_test.dart`.
- **App update (F18, 2026-11-16):** `features/update/` (02-TRD §8.2). `UpdateGate` sits in `MaterialApp.builder` around the router. `testApp(updateCheck: false)` is the default so other tests make no version request; `test/features/update_test.dart` covers no update, optional (Later / Update now / progress / install), failure + Retry, Cancel, forced (back blocked), web Reload, failed check, About, overflow. Version is now `1.1.0+2`. Windows uses the same flow once the Inno Setup installer exists (F19). Publishing: `deploy/publish-app.sh` (09-Deployment).
- **Polish & APK (F19, 2026-11-16):** accessibility test over every main screen (tap targets, labels, contrast, light + dark, 1.3× text); fixes: app bar buttons and info rows 48 dp, segmented tabs 48 dp, compact chips 48 dp tap height, `textTertiary` darker (#5E6E84), report tiles grow with the font size. Release APK: 64-bit only + obfuscated (≈23 MB), `INTERNET` permission in the main manifest, release key. Real Android check (Android 16 emulator): launch, version check, update 1.1.0 → 1.1.1 end to end. Fixed there: black status bar painted by the app (Android 15+ ignores `statusBarColor`), no grey band on the login bar, the update dialog keeps its width, a finished download is reused after the "allow installs" step. Windows installer: not now (the owner needs the APK only).
- **Android splash (2026-11-16, after install):** the launch screen was Flutter's default (black in dark mode, white otherwise). Now `flutter_native_splash` draws the app background + logo in light and dark (Android 12+ and older), the window behind Flutter uses the same colours, and the splash page keeps the logo in the exact centre so the hand-over does not jump. Checked by screen recording a cold start on the Android 16 emulator, light and dark. Version 1.1.1+3.
- **Receipt → WhatsApp (2026-11-16):** sale ⋮ → "Send receipt on WhatsApp" (`ReceiptOutput.whatsApp`, native `flyash/whatsapp` channel on Android, see 02-TRD §8). `ActionMenuItem` gained `enabled` + `hint` (the item is greyed out with "No phone number for this customer"). Checked on the Android 16 emulator: the PDF is written and handed to the FileProvider; without WhatsApp the "not installed" message shows. Tests in `receipt_test.dart`.
- **Attendance date (2026-11-16):** leaving the Attendance section resets the day to today (`onSectionLeft` → `_goTo(today)`), like the search reset. Test: `attendance_test.dart` "leaving Attendance and coming back opens today again".
- **Factory GST + receipt header (2026-11-16):** optional `gst_number` in the factory profile (server migration 0027, GSTIN check in the app and on the server), printed as "GSTIN: …" on receipts. The receipt header is now centred: logo beside the factory name, then address, phone · email, GSTIN; "Receipt" and the invoice no. sit in one row under the accent rule.
- **Labours without tabs (2026-11-16):** the Wages tab (wage sheet) is gone; `LaboursPage` is just the labour list. Wage detail moved to `/labours/:id/wages` (old `/labours/wages…` links fall back to `/labours`). Shared wage widgets live in `wages/presentation/widgets/wage_widgets.dart`. Tests: `labours_section_test.dart`, `wages_test.dart`.
- **Reports = net profit (2026-11-16):** the grid and the other five reports were removed; `/reports` is `NetProfitPage` (old `/reports/<type>` → `/reports`). Net profit is now sales with tax − expenses − wages paid (server `ReportService.netProfitFor`, field `wages_paid`). "This week" became "Last 7 days" (a Monday-start week is only "today" on a Monday). The wide 5-column month table (it broke on phones) became a card per month. Loading shows the real cards with `SkeletonLine` placeholders (one text line high; `KpiChip` values keep their line height when scaled), checked by a test that the chart does not move. Export moved from the app bar to an "Export" button next to the dates so the title fits. The app bar title is "Reports" (same as the sidebar). Home "Total due" → `/customers?filter=due` again.
- **APK size (2026-11-16):** 64-bit only (`android-arm64`; the app runs on new phones): ≈23 MB (was ≈40 MB with 32-bit, 66 MB with x86_64). The rest is the Flutter engine (11.3 MB) and the app code (9.2 MB). Decided with the owner: existing accounts keep their colour (no Brick migration of users); no all-labours monthly wage screen.
- **Page transitions (2026-11-16):** `AppPageTransitionsBuilder` for every platform (fade in over the untouched old page) replaces the platform defaults; the pager's fixed bar background is always drawn and its titles fade with the page; `PagerSectionBar` remembers the last page. Fixes the white flash and the overlapping titles on going back, and makes the app bar look updated in place. Checked with frame-by-frame screenshots (Sales and Customers, open and back) and `test/features/page_transitions_test.dart` (Sales, Expenses, Customers, Labours, Products, Users, Settings: the list is never faded during the back animation; bottom-bar titles fade in, no jump). With the old transition all seven cases fail.
- **Fake data (2026-11-16):** `node ace demo:seed --months=6` fills a test database (name must contain "test") — see 09-Deployment "Test database". On the VPS: `flyash_test`, a copy of `flyash` emptied except users, tokens, factory profile and app versions.
- **Riverpod retries are off** (`retry: noRetry`): a failed load shows an error with a Retry button instead of retrying silently.
- **Logo colors** (teal, slate, orange, leaf green) sit well with the Emerald and Ash Slate accents; the default accent is Brick Terracotta (changed from Royal Blue on 2026-11-16; app, web splash, report PDFs and the server default for new users).
