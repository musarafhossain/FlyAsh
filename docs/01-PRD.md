# 01 · Product Requirements Document (PRD): FlyAsh

| | |
|---|---|
| **Document** | Product Requirements Document |
| **Product** | FlyAsh: sales, labour and expense management for a fly ash brick factory |
| **Version** | 1.1 (updated after testing, 2026-11-15) |
| **Date** | 2026-11-08 |
| **Status** | Approved scope for v1 (MVP) |
| **Related docs** | 02-TRD · 03-AppFlow · 04-UI-UX-Design-Brief · 05-Backend-Schema · 06-Implementation-Plan · 07-API-Reference |

---

## 1. Overview

FlyAsh is a simple app that lets the owner of a fly ash brick factory run the daily business from a phone or a computer. It replaces paper notebooks for:

- **Selling** bricks (on-the-spot sales and advance bookings), including payments, tax and dues
- Managing **customers** and **products**
- Managing **labours**: daily attendance (present / absent), wage calculation and wage payments
- Recording **extra expenses** (tiffin, machine repair, diesel and so on)
- Seeing **reports** and the real **net profit**

The app supports **multiple users with equal access** (no roles). There is no sign-up: the first user is created on the server, and any logged-in user can add more users. It runs on **Android, Web and Windows** with the same data on every device.

## 2. Problem and Goals

**Problems today**
- Sales, dues and advances are written in notebooks. Entries get lost, and totals are often wrong.
- Nobody knows the exact net profit per month.
- Dues are hard to follow up because there is no quick list of who owes how much.
- Labour attendance and wage calculation at month end take hours and cause disputes.
- Small expenses (tiffin, repairs, fuel) are not recorded, so the profit looks higher than it really is.

**Goals for v1**

| # | Goal | Measure of success |
|---|---|---|
| G1 | Record a sale in under 1 minute | New sale with an existing customer in ≤ 6 taps + typing quantity |
| G2 | Know profit instantly | Net profit per month (sales − expenses − wages) is visible without manual calculation |
| G3 | Never lose track of dues | A dues list per customer, always correct to the rupee |
| G4 | Attendance in under 1 minute per day | One switch per labour (Present / Absent), saved at once |
| G5 | Wages calculated automatically | The monthly wage sheet needs no manual maths |
| G6 | Real net profit | Net profit = sales (without tax) − expenses − wages, for any period |

## 3. Users

**Typical users:** the owner, and the people they trust to run the factory with them (manager, munshi, accountant).

- They use an Android phone most of the time, and a Windows PC or a browser for reports.
- They are comfortable with WhatsApp-level apps and are not accountants.
- They prefer Bengali or English (switchable).
- They often work outdoors or in a noisy, dusty factory yard.

**Access model (v1)**

- **All users are equal.** There are no roles or permissions, and every user can use every module, including adding other users.
- **No sign-up screen.** The **first user** is created once on the server with a command. After that, any logged-in user adds new users from the app.
- Every record stores **who created it** (`created_by`), which is shown on the sale, payment and expense details.

## 4. Scope

### 4.1 In scope (v1)

| Module | Summary |
|---|---|
| Authentication | Login, my profile, change password, app lock (biometric) |
| Users | Add, edit and deactivate users, and reset a user's password (all users are equal) |
| Dashboard | Today's sales, dues, deliveries, attendance, month expenses, quick actions |
| Products | List and manage products with a selling price |
| Customers | Name, phone, address, purchase history and dues |
| Sales | Instant sales and bookings, multiple items, transport, discount, payments, receipt PDF |
| Labours | Name, phone, address, wage type (daily/monthly) and amount |
| Attendance | Toggle-based attendance for any date (defaults to today) |
| Wages | Automatic monthly wage calculation and wage payments (no separate advances) |
| Expenses | Extra expenses with a free-text category |
| Reports | Sales, dues, expenses, wages, net profit, with PDF/Excel export |
| Settings | Factory profile, appearance (theme), language, password |
| App Update | In-app update check and install for Android, Windows and Web |

### 4.2 Out of scope (v1), possible later

- Offline data entry with sync *(Phase 2)*
- iOS and macOS apps *(Phase 2)*
- Production tracking, raw materials, brick stock
- Roles and permissions (in v1 all users have the same access)
- Suppliers and purchases
- GST invoicing and tax reports
- SMS or WhatsApp automation (reminders)

### 4.3 Platforms

| Platform | Distribution |
|---|---|
| Android (phone/tablet) | APK download from our server (with in-app update). Play Store is optional later |
| Web | Browser at `app.<domain>` |
| Windows | Installer (`.exe`) downloaded from our server (with in-app update) |

## 5. Functional Requirements

Priority: **P0** = must have for launch · **P1** = should have for launch · **P2** = nice to have.

### 5.1 Authentication (AUTH)

| ID | Requirement | Priority |
|---|---|---|
| AUTH-1 | A user logs in with phone number (or email) and password | P0 |
| AUTH-2 | The session stays logged in **with no expiry** until the user logs out, is deactivated, or their password is changed or reset | P0 |
| AUTH-3 | **No sign-up screen.** The first user is created once during server setup with a command. Other users are added from the app (see 5.13) | P0 |
| AUTH-4 | Change your own password from Settings (old password required) | P0 |
| AUTH-5 | Optional app lock with fingerprint or face (Android/Windows Hello) when the app opens | P2 |
| AUTH-6 | Too many wrong passwords block login for 15 minutes | P1 |
| AUTH-7 | **My profile:** the logged-in user views and edits their own name, phone and email (the only place to change your own details) | P0 |
| AUTH-8 | **Forgot password (email OTP), 3 separate screens:** (1) **Email** → a **6-digit OTP** is emailed → (2) **Verify OTP** → OTP correct → (3) **New password** (new + confirm) → password changed, the user is logged out of all devices and logs in again. The new password screen works only after the OTP was verified (it uses a signed, short-lived reset token) | P0 |
| AUTH-9 | OTP rules: valid for **10 minutes**, single use, max **5 wrong tries** (then request a new OTP), "Resend OTP" after **60 seconds**, max **3 OTP requests per 15 minutes** per email. The screen never reveals whether an email is registered ("If this email is registered, an OTP has been sent"). After a correct OTP, the user has **10 minutes** to set the new password, otherwise they start again | P0 |
| AUTH-10 | Fallback for users **without an email**: another user resets the password from the Users screen (USER-4). If nobody can log in, the password is reset on the server with a command | P0 |

### 5.2 Dashboard (DASH)

| ID | Requirement | Priority |
|---|---|---|
| DASH-1 | Hero card: **today's sales amount** and number of sales (no greeting, name or date line above it) | P0 |
| DASH-2 | ~~Today's profit~~ removed: products have no cost, so a sale has no profit (see 6.1) | — |
| DASH-3 | KPI cards: **Total due** (all customers) · **Deliveries today** (bookings due today) · **Labours present today** · **This month's expenses** | P0 |
| DASH-4 | Quick actions: New Sale · New Booking · Take Attendance · Add Expense | P0 |
| DASH-5 | The 5 most recent sales | P1 |
| DASH-6 | Pull to refresh | P0 |

### 5.3 Products (PROD)

| ID | Requirement | Priority |
|---|---|---|
| PROD-1 | Product fields: **name** (required, unique), **default selling price** (₹), notes. There is **no unit and no cost** | P0 |
| PROD-2 | Product list with search, showing name and price | P0 |
| PROD-3 | Add and edit products; a separate read-only **product detail** page (tap a product). Deactivate / Delete are on the detail page (⋮) and in the list's long-press menu, not on the edit form | P0 |
| PROD-4 | **Deactivate / activate** a product. Inactive products are hidden from the sale form but stay in old sales | P0 |
| PROD-5 | A product can be deleted only if it was never used in a sale | P1 |

### 5.4 Customers (CUST)

| ID | Requirement | Priority |
|---|---|---|
| CUST-1 | Customer fields: **name** (required), **phone** (optional, 10 digits, unique when given), **address** (optional) | P0 |
| CUST-2 | Customer list with search (name or phone) and a **due amount** shown on each row | P0 |
| CUST-3 | Add, edit and view customers | P0 |
| CUST-4 | Adding a phone number that already exists is **blocked**, and the app offers to open the existing customer | P0 |
| CUST-5 | Customer detail: contact info, **total purchases, total paid, total due**, and the list of their sales | P0 |
| CUST-6 | One-tap **Call** and **WhatsApp** buttons (only when the customer has a phone) | P1 |
| CUST-7 | A customer can be deleted only if they have no sales. Otherwise they can be deactivated | P1 |
| CUST-8 | Filter the list to "Has due" only, sorted by highest due | P1 |

### 5.5 Sales (SALE)

| ID | Requirement | Priority |
|---|---|---|
| SALE-1 | Two sale types: **Instant** (sold and delivered now) and **Booking** (delivered later) | P0 |
| SALE-2 | **Customer:** search and select an existing customer, **or add a new customer inline** (name, phone optional, address) without leaving the form | P0 |
| SALE-3 | **Items:** one or more lines, each with product, quantity and **price**. The price pre-fills from the product and can be edited (no cost) | P0 |
| SALE-4 | **Transport charge** (added), **discount** (subtracted) and **tax %** (added on subtotal + transport − discount), all optional | P0 |
| SALE-5 | The app shows the subtotal, tax, total and due amount live while the owner types | P0 |
| SALE-6 | **Payment at the time of sale:** amount received now (for bookings this is the **advance**), plus the payment method (Cash / UPI / Bank / Other) | P0 |
| SALE-7 | **Add a later payment** to any sale (date, amount, method, note). Payments are listed on the sale with dates | P0 |
| SALE-8 | Payment status is automatic: **Paid / Partial / Due** | P0 |
| SALE-9 | **Booking fields:** expected delivery date (required), delivery address (defaults to the customer's address) | P0 |
| SALE-10 | Booking status: **Booked → Delivered** or **Cancelled**. "Mark as delivered" records the delivery date (default today) | P0 |
| SALE-11 | Each sale gets an automatic **invoice number** (`INV-000001`, sequential) | P0 |
| SALE-12 | Sale list with filters: date range (Today / This week / This month / Custom), type (Instant / Booking), status (Paid / Partial / Due / Booked / Cancelled), and search (customer name, phone, invoice no.). Paginated | P0 |
| SALE-13 | Sale detail: customer, items, totals (incl. tax), payments, status. Edit is the pencil; Add payment · Mark delivered · Cancel booking · Delete are in the ⋮ menu (Share receipt in F17) | P0 |
| SALE-14 | **Receipt PDF** with the factory logo (static, bundled in the app), name, address and phone, invoice no., customer, items, totals, paid and due. Share via WhatsApp or other apps, print, or save | P1 |
| SALE-15 | Edit a sale (items, prices, charges, notes). Totals and status are recalculated | P0 |
| SALE-16 | Delete a sale, with confirmation (soft delete, removed from all reports) | P1 |
| SALE-17 | Notes field | P1 |
| SALE-18 | "Upcoming deliveries" list: bookings not yet delivered, sorted by delivery date, with overdue ones highlighted | P1 |

### 5.6 Labours (LAB)

| ID | Requirement | Priority |
|---|---|---|
| LAB-1 | Labour fields: **name** (required), **phone** (optional), **address** (optional), **wage type** (Daily / Monthly, required), **wage amount** ₹ (required), **joining date** (default today) | P0 |
| LAB-2 | Labour list with search, showing wage type and amount, and today's attendance (Present / Absent) | P0 |
| LAB-3 | Add, edit and view labours | P0 |
| LAB-4 | **Deactivate** a labour who has left (with a leaving date). Inactive labours are hidden from attendance after that date, and their history stays | P0 |
| LAB-5 | Labour detail: info, wage this month as stat cards (Earned · Paid · Balance), attendance calendar; ⋮ → Pay wage · Wage details · Deactivate | P0 |

### 5.7 Attendance (ATT)

| ID | Requirement | Priority |
|---|---|---|
| ATT-1 | The attendance screen opens on **today's date**. A date picker allows **any past date or today**. Future dates are not allowed | P0 |
| ATT-2 | Lists all labours active on that date (with search), each with a **switch**: on = **Present**, off = **Absent**. There is no half day | P0 |
| ATT-3 | ~~"Mark all present"~~ removed | — |
| ATT-4 | A line at the top: "12 present · 5 absent" | P0 |
| ATT-5 | **Each switch saves at once** (no Save button). Present saves a row; absent removes it. A failed save puts the switch back | P0 |
| ATT-6 | Monthly attendance view per labour (calendar with colored days) | P1 |

### 5.8 Wages (WAGE)

| ID | Requirement | Priority |
|---|---|---|
| WAGE-1 | **Monthly wage sheet:** pick a month and see every labour's present days, absent days, **earned wage**, paid and **balance** | P0 |
| WAGE-2 | ~~Advances~~ removed: money given before the month ends is simply a wage payment | — |
| WAGE-3 | **Wage payments:** record a payment to a labour for a month (date, amount, method, note). Partial payments are allowed | P0 |
| WAGE-4 | Status per labour per month: **Paid / Partial / Due** | P0 |
| WAGE-5 | Labour wage detail per month: day-by-day attendance, calculation breakdown and payments; ⋮ → Pay wage | P1 |
| WAGE-6 | Delete a wrong payment (long press → Delete, with confirmation) | P0 |

### 5.9 Expenses (EXP)

| ID | Requirement | Priority |
|---|---|---|
| EXP-1 | Expense fields: **date** (default today), **category** (required, **any text**), **amount** ₹ (required), **note** | P0 |
| EXP-2 | Suggested categories (small chips in one row under the field, scrolled sideways): ones used before, then **Labour Tiffin · Diesel · Fly Ash · Cement · Stone Dust · Machine Repair · Electricity Bill · Transport · Others**. A default is not offered when a used name already starts with it (so only one Diesel) | P0 |
| EXP-3 | ~~Category management~~ removed: categories are free text, no list to manage | — |
| EXP-4 | Expense list with search and a filter button (period + category), showing the total for the filtered period. Endless scroll | P0 |
| EXP-5 | Add, edit and delete expenses | P0 |

### 5.10 Reports (REP)

All reports take a date range (Today / This week / This month / Last month / This year / Custom).

| ID | Report | Content | Priority |
|---|---|---|---|
| REP-1 | **Sales report** | Number of sales and sales amount. Breakdown by product. Daily chart | P0 |
| REP-2 | **Dues report** | Every customer with dues: name, phone, total due, oldest due date. Sorted by due | P0 |
| REP-3 | **Expense report** | Total, and a breakdown by category (chart and table) | P0 |
| REP-4 | **Wage report** | Per month: total earned, paid, balance, per labour | P1 |
| REP-5 | **Net profit report** | Sales (without tax) − expenses − wages = **net profit** for the period, with a monthly trend chart | P0 |
| REP-6 | **Collection report** | Money received (all payments) by date and method | P1 |
| REP-7 | **Export** any report as PDF or Excel | P1 |

### 5.11 Settings (SET)

| ID | Requirement | Priority |
|---|---|---|
| SET-1 | **Factory profile:** factory name, owner name, phone, email, address, invoice prefix. Used in receipts and the app header. The **logo is a static image bundled in the app** (no image upload or storage on the server) | P0 |
| SET-2 | **Appearance:** theme mode (Light / Dark / System) and 5 accent colors are **saved to the user's account** (`users.theme_mode`, `users.accent_color`), so they follow the user to every device. Font size stays per device (see 04-UI-UX §8) | P0 |
| SET-3 | **Language:** English / বাংলা. The choice is **saved to the user's account** (`users.locale`), so it follows the user to every device, and the server sends emails and messages in that language | P1 |
| SET-4 | **Change password**, **Logout** | P0 |
| SET-5 | **App lock** on/off (biometric) | P2 |
| SET-6 | **About:** app version, check for updates | P0 |

### 5.12 App Update (UPD)

| ID | Requirement | Priority |
|---|---|---|
| UPD-1 | On launch (and from Settings → About), the app asks the server whether a newer version exists for its platform | P0 |
| UPD-2 | **Optional update:** a dialog with the version and release notes, plus **Update now / Later**. "Later" hides it until the next launch | P0 |
| UPD-3 | **Forced update:** if the installed version is older than the minimum supported version, a blocking screen allows only **Update** | P0 |
| UPD-4 | **Android:** the app downloads the new APK with a progress bar and opens the system installer | P0 |
| UPD-5 | **Windows:** the app downloads the new installer with a progress bar, launches it and closes itself | P0 |
| UPD-6 | **Web:** a banner "New version available, Reload" refreshes to the latest build | P0 |
| UPD-7 | A new version is published on the server with one command (version, build number, file, minimum version, release notes) | P0 |

### 5.13 Users (USER)

All users have the same access. There are no roles.

**User information stored**

| Field | Required | Notes |
|---|---|---|
| Name | ✅ | Shown in the app header and on "created by" |
| Phone | ✅ | 10 digits, unique. Used to log in |
| Email | — | Unique if given. Can also be used to log in. **Needed for "Forgot password" by email OTP**; the form shows a hint when it is left empty |
| Password | ✅ | Min 6 characters, stored **hashed** (never readable) |
| Language | auto | `en` (default) or `bn`. Changed by the user in Settings → Language |
| Theme mode | auto | `system` (default), `light` or `dark`. Changed in Settings → Appearance |
| Theme color | auto | `blue` (default), `brick`, `emerald`, `violet` or `slate`. Changed in Settings → Appearance |
| Status | auto | Active / Inactive (default Active) |
| Last login | auto | Updated on every successful login |
| Created by | auto | The user who added this user (empty for the first user) |
| Created at / Updated at | auto | |

| ID | Requirement | Priority |
|---|---|---|
| USER-1 | User list with search, showing name, phone, status (*Active* / *Inactive*) and last login. **The logged-in user is not shown in this list**; they manage their own details in **My Profile** (AUTH-7, AUTH-4) | P0 |
| USER-2 | **Add user:** name, phone, email, password, language (optional, default English). The new user can log in right away | P0 |
| USER-3 | Edit another user's name, phone and email | P0 |
| USER-4 | **Reset password** for another user (sets a new password and logs that user out of all devices) | P0 |
| USER-5 | **Deactivate / activate** another user. A deactivated user is logged out of all devices and cannot log in. Users are never deleted, so `created_by` history stays | P0 |
| USER-6 | Safety rules: the Users endpoints never act on the logged-in user (they use My Profile instead), so **nobody can deactivate themselves**. As a result at least one active user always remains | P0 |

## 6. Business Rules and Calculations

All calculations are done **on the server**. The app only displays the results. Money is stored with 2 decimals, and all amounts are in **₹ (INR)**.

### 6.1 Sales

| Rule | Definition |
|---|---|
| Line amount | `quantity × unit_price` |
| Subtotal | Σ line amounts |
| Taxable | `subtotal + transport_charge − discount` (must be ≥ 0) |
| Tax | `taxable × tax_percent ÷ 100` (0–100 %, rounded to paise) |
| **Total** | `taxable + tax` |
| Profit | Not tracked per sale (products have no cost). See 6.4 for net profit |
| Paid amount | Σ payments of the sale |
| **Due** | `total − paid_amount` |
| Payment status | `paid_amount = 0` → **Due** · `0 < paid < total` → **Partial** · `paid = total` → **Paid** |
| Overpayment | Not allowed: a payment cannot make paid_amount > total |
| Price snapshot | The product name and unit price are saved on the sale line. Changing the product later does **not** change old sales |
| Editing a sale | If the new total is less than what was already paid, the edit is rejected with a clear message |

### 6.2 Bookings

| Rule | Definition |
|---|---|
| Statuses | `booked` → `delivered` or `cancelled`. Instant sales are created as `delivered` |
| Advance | Stored as a normal payment, made on the booking date |
| Cancel | Only a `booked` sale can be cancelled. If it has payments, the owner must first delete them (refund) before cancelling |
| Which date counts | Sales are counted on the **delivery date**: the sale date for instant sales, the delivered date for bookings |
| Pending bookings | Booked but not delivered: not counted in sales yet. Shown in "Upcoming deliveries", and their advances appear in collections |
| Dues | Due amounts count for `delivered` sales only. For `booked` sales the remaining amount is shown as "balance to collect on delivery" |

### 6.3 Attendance and Wages

| Rule | Definition |
|---|---|
| Attendance | A row = **Present** for that day; no row = **Absent**. No half day |
| Present / absent days (month) | present = rows in the month · absent = employed days so far − present |
| **Daily wage labour** | `earned = present_days × daily_wage` |
| **Monthly wage labour** | `per_day = monthly_wage ÷ days_in_month` · `earned = present_days × per_day` (rounded to 2 decimals). Weekly off or holidays the owner wants to pay are marked as Present |
| Wage rate snapshot | Each attendance record stores the wage type and rate on that day, so a later wage change does not change past months |
| Balance | `earned − payments_for_month` (an advance is just an early payment). A negative balance means paid extra (no automatic carry-forward in v1) |
| Wage status | `payments = 0` and earned > 0 → **Due** · balance > 0 → **Partial** · balance ≤ 0 → **Paid** |
| Who appears | Labours active on the date (joining date ≤ date, and no leaving date or leaving date ≥ date) |

### 6.4 Expenses and Net Profit

| Rule | Definition |
|---|---|
| Expense date | Counted in the period of its `expense_date` |
| **Wages in a period** | Earned wages from attendance in that period (not the payments) |
| **Net profit** | `sales without tax (delivered in period) − expenses (in period) − wages_earned (in period)` |
| Collections | Money actually received, counted by payment date (separate from profit) |

### 6.5 Dashboard definitions

| Card | Definition |
|---|---|
| Today's sales | Σ total of sales delivered today (instant today + bookings delivered today) |
| Total due | Σ due of all delivered, non-deleted sales |
| Deliveries today | Count of `booked` sales with delivery date = today (overdue counted separately) |
| Present today | Labours marked present today |
| This month's expenses | Σ expenses from the 1st of the month to today |

## 7. Non-Functional Requirements

| Area | Requirement |
|---|---|
| **Performance** | Lists load the first page in < 1.5 s on 4G. All lists are paginated (default 20 per page) |
| **Platforms** | Android 8.0+ (API 26+), latest Chrome / Edge / Firefox / Safari for Web, Windows 10/11 (64-bit) |
| **Connectivity** | Online only in v1. Without internet the app shows a clear "No internet" state with Retry and never loses typed form data |
| **Security** | HTTPS only, hashed passwords, token auth, login rate limit, token stored in secure storage |
| **Reliability** | Daily automatic database backup on the server, keeping 30 days |
| **Usability** | Follows 04-UI-UX-Design-Brief: large touch targets, light/dark themes, Bengali support |
| **Localization** | English and Bengali UI. ₹ with Indian grouping (`₹1,00,000`). Dates as `08 Nov 2026` |
| **Accuracy** | Money uses exact decimals (never floating point). Totals always match the line items |
| **Data safety** | Customers, products, labours and sales are soft-deleted or deactivated, so history is never broken |

## 8. Release Plan

| Phase | Content |
|---|---|
| **v1.0 (MVP)** | Everything in §5 marked P0 and P1, on Android, Web and Windows |
| **v1.x** | P2 items (biometric lock), report polish, feedback fixes |
| **Phase 2** | Offline data entry with sync, iOS/macOS, Play Store listing |
| **Later** | Production and stock, raw materials, suppliers, roles and permissions, WhatsApp due reminders |

## 9. Assumptions

1. There is one factory. Every user works on the same data, with equal access.
2. The owner keeps money in ₹. No GST invoice is needed in v1.
3. A product has one price; the quantity sold is just a number (no unit is stored).
4. Labour wages are daily or monthly. Piece-rate wages are not in v1.
5. The server (VPS) and domain will be ready before launch.
