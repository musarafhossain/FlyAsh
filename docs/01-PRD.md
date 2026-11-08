# 01 · Product Requirements Document (PRD): FlyAsh

| | |
|---|---|
| **Document** | Product Requirements Document |
| **Product** | FlyAsh: sales, labour and expense management for a fly ash brick factory |
| **Version** | 1.0 |
| **Date** | 2026-11-08 |
| **Status** | Approved scope for v1 (MVP) |
| **Related docs** | 02-TRD · 03-AppFlow · 04-UI-UX-Design-Brief · 05-Backend-Schema · 06-Implementation-Plan |

---

## 1. Overview

FlyAsh is a simple app that lets the owner of a fly ash brick factory run the daily business from a phone or a computer. It replaces paper notebooks for:

- **Selling** bricks (on-the-spot sales and advance bookings), including cost, profit, payments and dues
- Managing **customers** and **products**
- Managing **labours**: daily attendance, wage calculation, advances and wage payments
- Recording **extra expenses** (tiffin, machine repair, diesel and so on)
- Seeing **reports** and the real **net profit**

The app supports **multiple users with equal access** (no roles). There is no sign-up: the first user is created on the server, and any logged-in user can add more users. It runs on **Android, Web and Windows** with the same data on every device.

## 2. Problem and Goals

**Problems today**
- Sales, dues and advances are written in notebooks. Entries get lost, and totals are often wrong.
- Nobody knows the exact profit per sale or per month.
- Dues are hard to follow up because there is no quick list of who owes how much.
- Labour attendance and wage calculation at month end take hours and cause disputes.
- Small expenses (tiffin, repairs, fuel) are not recorded, so the profit looks higher than it really is.

**Goals for v1**

| # | Goal | Measure of success |
|---|---|---|
| G1 | Record a sale in under 1 minute | New sale with an existing customer in ≤ 6 taps + typing quantity |
| G2 | Know profit instantly | Profit per sale, per day and per month is visible without manual calculation |
| G3 | Never lose track of dues | A dues list per customer, always correct to the rupee |
| G4 | Attendance in under 1 minute per day | "Mark all present" then toggle the exceptions |
| G5 | Wages calculated automatically | The monthly wage sheet needs no manual maths |
| G6 | Real net profit | Net profit = sales profit − expenses − wages, for any period |

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
| Dashboard | Today's sales and profit, dues, deliveries, attendance, quick actions |
| Products | List and manage products with default cost and selling price |
| Customers | Name, phone, address, purchase history and dues |
| Sales | Instant sales and bookings, multiple items, transport, discount, payments, receipt PDF |
| Labours | Name, phone, address, wage type (daily/monthly) and amount |
| Attendance | Toggle-based attendance for any date (defaults to today) |
| Wages and Advances | Automatic monthly wage calculation, advances, wage payments |
| Expenses | Extra expenses with categories |
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
| DASH-1 | Hero card: **today's sales amount** and number of sales | P0 |
| DASH-2 | **Today's profit** | P0 |
| DASH-3 | KPI cards: **Total due** (all customers) · **Deliveries today** (bookings due today) · **Labours present today** · **This month's expenses** | P0 |
| DASH-4 | Quick actions: New Sale · New Booking · Take Attendance · Add Expense | P0 |
| DASH-5 | The 5 most recent sales | P1 |
| DASH-6 | Pull to refresh | P0 |

### 5.3 Products (PROD)

| ID | Requirement | Priority |
|---|---|---|
| PROD-1 | Product fields: **name** (required, unique), **unit** (Piece / 1000 Pieces / Truck / Other text), **default production cost per unit** (₹), **default selling price per unit** (₹), notes | P0 |
| PROD-2 | Product list with search, showing name, unit, cost, price and the margin per unit | P0 |
| PROD-3 | Add, edit and view products | P0 |
| PROD-4 | **Deactivate / activate** a product. Inactive products are hidden from the sale form but stay in old sales | P0 |
| PROD-5 | A product can be deleted only if it was never used in a sale | P1 |

### 5.4 Customers (CUST)

| ID | Requirement | Priority |
|---|---|---|
| CUST-1 | Customer fields: **name** (required), **phone** (required, 10 digits, unique), **address** (optional) | P0 |
| CUST-2 | Customer list with search (name or phone) and a **due amount** shown on each row | P0 |
| CUST-3 | Add, edit and view customers | P0 |
| CUST-4 | Adding a phone number that already exists is **blocked**, and the app offers to open the existing customer | P0 |
| CUST-5 | Customer detail: contact info, **total purchases, total paid, total due**, and the list of their sales | P0 |
| CUST-6 | One-tap **Call** and **WhatsApp** buttons | P1 |
| CUST-7 | A customer can be deleted only if they have no sales. Otherwise they can be deactivated | P1 |
| CUST-8 | Filter the list to "Has due" only, sorted by highest due | P1 |

### 5.5 Sales (SALE)

| ID | Requirement | Priority |
|---|---|---|
| SALE-1 | Two sale types: **Instant** (sold and delivered now) and **Booking** (delivered later) | P0 |
| SALE-2 | **Customer:** search and select an existing customer, **or add a new customer inline** (name, phone, address) without leaving the form | P0 |
| SALE-3 | **Items:** one or more lines, each with product, quantity, **production cost per unit** and **selling price per unit**. Cost and price pre-fill from the product defaults and can be edited | P0 |
| SALE-4 | **Transport charge** (added) and **discount** (subtracted), both optional | P0 |
| SALE-5 | The app shows the subtotal, total, **profit** and due amount live while the owner types | P0 |
| SALE-6 | **Payment at the time of sale:** amount received now (for bookings this is the **advance**), plus the payment method (Cash / UPI / Bank / Other) | P0 |
| SALE-7 | **Add a later payment** to any sale (date, amount, method, note). Payments are listed on the sale with dates | P0 |
| SALE-8 | Payment status is automatic: **Paid / Partial / Due** | P0 |
| SALE-9 | **Booking fields:** expected delivery date (required), delivery address (defaults to the customer's address) | P0 |
| SALE-10 | Booking status: **Booked → Delivered** or **Cancelled**. "Mark as delivered" records the delivery date (default today) | P0 |
| SALE-11 | Each sale gets an automatic **invoice number** (`INV-000001`, sequential) | P0 |
| SALE-12 | Sale list with filters: date range (Today / This week / This month / Custom), type (Instant / Booking), status (Paid / Partial / Due / Booked / Cancelled), and search (customer name, phone, invoice no.). Paginated | P0 |
| SALE-13 | Sale detail: customer, items, totals, profit, payments, status and actions (Add payment · Mark delivered · Cancel · Edit · Share receipt) | P0 |
| SALE-14 | **Receipt PDF** with the factory logo (static, bundled in the app), name, address and phone, invoice no., customer, items, totals, paid and due. Share via WhatsApp or other apps, print, or save | P1 |
| SALE-15 | Edit a sale (items, prices, charges, notes). Totals and status are recalculated | P0 |
| SALE-16 | Delete a sale, with confirmation (soft delete, removed from all reports) | P1 |
| SALE-17 | Notes field | P1 |
| SALE-18 | "Upcoming deliveries" list: bookings not yet delivered, sorted by delivery date, with overdue ones highlighted | P1 |

### 5.6 Labours (LAB)

| ID | Requirement | Priority |
|---|---|---|
| LAB-1 | Labour fields: **name** (required), **phone** (optional), **address** (optional), **wage type** (Daily / Monthly, required), **wage amount** ₹ (required), **joining date** (default today) | P0 |
| LAB-2 | Labour list with search, showing wage type and amount, and today's attendance status | P0 |
| LAB-3 | Add, edit and view labours | P0 |
| LAB-4 | **Deactivate** a labour who has left (with a leaving date). Inactive labours are hidden from attendance after that date, and their history stays | P0 |
| LAB-5 | Labour detail: info, this month's attendance summary, wage summary, advances and payments | P0 |

### 5.7 Attendance (ATT)

| ID | Requirement | Priority |
|---|---|---|
| ATT-1 | The attendance screen opens on **today's date**. A date picker allows **any past date or today**. Future dates are not allowed | P0 |
| ATT-2 | Lists all labours active on that date, each with a **toggle**: **Present / Half Day / Absent** (a 3-state segmented toggle) | P0 |
| ATT-3 | **"Mark all present"** button | P0 |
| ATT-4 | Summary at the top: Present · Half Day · Absent · Not marked | P0 |
| ATT-5 | **Save** stores the whole day in one action. Re-opening a date shows the saved values, which can be edited | P0 |
| ATT-6 | Monthly attendance view per labour (calendar with colored days) | P1 |

### 5.8 Wages and Advances (WAGE)

| ID | Requirement | Priority |
|---|---|---|
| WAGE-1 | **Monthly wage sheet:** pick a month and see every labour's present days, half days, absent days, **earned wage**, advances, paid, and **balance** | P0 |
| WAGE-2 | **Advances:** record an advance given to a labour (date, amount, note). Advances are deducted from that month's wage | P0 |
| WAGE-3 | **Wage payments:** record a payment to a labour for a month (date, amount, method, note). Partial payments are allowed | P0 |
| WAGE-4 | Status per labour per month: **Paid / Partial / Due** | P0 |
| WAGE-5 | Labour wage detail per month: day-by-day attendance, calculation breakdown, advances and payments | P1 |
| WAGE-6 | Delete a wrong advance or payment (with confirmation) | P0 |

### 5.9 Expenses (EXP)

| ID | Requirement | Priority |
|---|---|---|
| EXP-1 | Expense fields: **date** (default today), **category** (required), **amount** ₹ (required), **note** | P0 |
| EXP-2 | Default categories: **Labour Tiffin · Machine Repair · Diesel / Fuel · Electricity Bill · Transport · Others** | P0 |
| EXP-3 | The owner can add, rename and deactivate categories. A category in use cannot be deleted | P1 |
| EXP-4 | Expense list with date range and category filters, showing the total for the filtered period. Paginated | P0 |
| EXP-5 | Add, edit and delete expenses | P0 |

### 5.10 Reports (REP)

All reports take a date range (Today / This week / This month / Last month / This year / Custom).

| ID | Report | Content | Priority |
|---|---|---|---|
| REP-1 | **Sales report** | Number of sales, sales amount, cost, profit. Breakdown by product. Daily chart | P0 |
| REP-2 | **Dues report** | Every customer with dues: name, phone, total due, oldest due date. Sorted by due | P0 |
| REP-3 | **Expense report** | Total, and a breakdown by category (chart and table) | P0 |
| REP-4 | **Wage report** | Per month: total earned, advances, paid, balance, per labour | P1 |
| REP-5 | **Net profit report** | Sales profit − expenses − wages = **net profit** for the period, with a monthly trend chart | P0 |
| REP-6 | **Collection report** | Money received (all payments) by date and method | P1 |
| REP-7 | **Export** any report as PDF or Excel | P1 |

### 5.11 Settings (SET)

| ID | Requirement | Priority |
|---|---|---|
| SET-1 | **Factory profile:** factory name, owner name, phone, email, address, invoice prefix. Used in receipts and the app header. The **logo is a static image bundled in the app** (no image upload or storage on the server) | P0 |
| SET-2 | **Appearance:** theme mode (Light / Dark / System), 5 accent colors, font size. Saved on the device (see 04-UI-UX §8) | P0 |
| SET-3 | **Language:** English / বাংলা | P1 |
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
| Status | auto | Active / Inactive (default Active) |
| Last login | auto | Updated on every successful login |
| Created by | auto | The user who added this user (empty for the first user) |
| Created at / Updated at | auto | |

| ID | Requirement | Priority |
|---|---|---|
| USER-1 | User list with search, showing name, phone, status (*Active* / *Inactive*) and last login. **The logged-in user is not shown in this list**; they manage their own details in **My Profile** (AUTH-7, AUTH-4) | P0 |
| USER-2 | **Add user:** name, phone, email, password. The new user can log in right away | P0 |
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
| Line cost | `quantity × unit_cost` |
| Subtotal | Σ line amounts |
| **Total** | `subtotal + transport_charge − discount` (must be ≥ 0) |
| Total cost | Σ line costs |
| **Profit** | `total − total_cost`. Transport charge counts as income; if the owner pays a truck, that is recorded as an expense (Transport) |
| Paid amount | Σ payments of the sale |
| **Due** | `total − paid_amount` |
| Payment status | `paid_amount = 0` → **Due** · `0 < paid < total` → **Partial** · `paid = total` → **Paid** |
| Overpayment | Not allowed: a payment cannot make paid_amount > total |
| Price snapshot | Unit cost and unit price are saved on the sale line. Changing the product later does **not** change old sales |
| Editing a sale | If the new total is less than what was already paid, the edit is rejected with a clear message |

### 6.2 Bookings

| Rule | Definition |
|---|---|
| Statuses | `booked` → `delivered` or `cancelled`. Instant sales are created as `delivered` |
| Advance | Stored as a normal payment, made on the booking date |
| Cancel | Only a `booked` sale can be cancelled. If it has payments, the owner must first delete them (refund) before cancelling |
| Which date counts | Sales, revenue and profit are counted on the **delivery date**: the sale date for instant sales, the delivered date for bookings |
| Pending bookings | Booked but not delivered: not counted in sales or profit yet. Shown in "Upcoming deliveries", and their advances appear in collections |
| Dues | Due amounts count for `delivered` sales only. For `booked` sales the remaining amount is shown as "balance to collect on delivery" |

### 6.3 Attendance and Wages

| Rule | Definition |
|---|---|
| Attendance value | Present = 1 day · Half Day = 0.5 day · Absent = 0 · Not marked = 0 (and flagged as "not marked" on the wage sheet) |
| Worked days (month) | Σ attendance values in the month |
| **Daily wage labour** | `earned = worked_days × daily_wage` |
| **Monthly wage labour** | `per_day = monthly_wage ÷ days_in_month` · `earned = worked_days × per_day` (rounded to 2 decimals). Weekly off or holidays the owner wants to pay are marked as Present |
| Wage rate snapshot | Each attendance record stores the wage type and rate on that day, so a later wage change does not change past months |
| Balance | `earned − advances_in_month − payments_for_month` · a negative balance is shown as "advance carried" (no automatic carry-forward in v1) |
| Wage status | `payments + advances = 0` and earned > 0 → **Due** · balance > 0 → **Partial** · balance ≤ 0 → **Paid** |
| Who appears | Labours active on the date (joining date ≤ date, and no leaving date or leaving date ≥ date) |

### 6.4 Expenses and Net Profit

| Rule | Definition |
|---|---|
| Expense date | Counted in the period of its `expense_date` |
| **Wages in a period** | Earned wages from attendance in that period (not the payments) |
| **Net profit** | `sales_profit (delivered in period) − expenses (in period) − wages_earned (in period)` |
| Collections | Money actually received, counted by payment date (separate from profit) |

### 6.5 Dashboard definitions

| Card | Definition |
|---|---|
| Today's sales | Σ total of sales delivered today (instant today + bookings delivered today) |
| Today's profit | Σ profit of the same sales |
| Total due | Σ due of all delivered, non-deleted sales |
| Deliveries today | Count of `booked` sales with delivery date = today (overdue counted separately) |
| Present today | Present + Half Day count for today |
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
3. Bricks are sold per piece, per thousand, or per truck, and the unit is set per product.
4. Labour wages are daily or monthly. Piece-rate wages are not in v1.
5. The server (VPS) and domain will be ready before launch.
