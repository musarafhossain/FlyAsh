# 04 · UI/UX Design Brief — FlyAsh Brick Factory Management

| | |
|---|---|
| **Document** | UI/UX Design Brief |
| **Product** | FlyAsh: management software for a fly ash brick factory |
| **Version** | 1.0 |
| **Date** | 2026-11-08 |
| **Status** | Approved for v1. Section 10 matches the v1 scope in 01-PRD |
| **Related docs** | 01-PRD · 02-TRD · 03-AppFlow · 05-Backend-Schema · 06-Implementation-Plan · 07-API-Reference |

---

## 1. Purpose

This brief sets the visual language, interaction patterns, theming system and screen guidelines for the FlyAsh app. Designers and developers should be able to build any screen from this document alone, so the app looks and behaves the same everywhere.

It covers:

- The design direction taken from the reference UI (an HR management mobile app: clean cards, a blue accent, soft pastel stat chips and status pills).
- A **token-based theme system** with **Light / Dark / System** modes and **5 accent color themes**, all switchable at runtime from **Settings → Appearance**.
- The component library and how each component maps from the reference to the brick factory domain.
- Layout, navigation, accessibility, localization and data display rules.

It does not cover business rules, data models or the full feature list. Those go in the PRD (01), the TRD (02) and the Backend Schema (05).

---

## 2. Design Reference and What We Take From It

The reference set has 8 screens: splash, dashboard, employee list, attendance, leave requests, payroll, overtime and side drawer. We keep its **structure and feel** and change the content to fit a brick factory.

| Reference pattern | What we keep | FlyAsh usage |
|---|---|---|
| Full-bleed accent splash with illustration and pill CTA | Accent background, centered logo, white "Get Started" pill | Splash / onboarding with a brick stack and kiln illustration |
| Greeting header (avatar, "Good Morning", name, role, bell) | Same layout | Dashboard header: owner or manager name, role, notifications |
| **Hero stat card** (solid accent, big number, trend line) | Same | "Today's Production: 12,400 bricks · ↑ 8% vs yesterday" |
| Row of 4 **pastel KPI chips** (icon in a tinted square, label, number) | Same, 4 per row | Stock ready · Orders pending · Workers present · Dispatch today |
| **Quick Actions** grid (2 columns, icon and label) | Same | Add Production · New Sale · Add Expense · Mark Attendance |
| Search bar with filter button, summary chips, list of avatar rows with a **status pill** and overflow menu | Same | Workers, Customers, Orders, Suppliers lists |
| **Circular progress ring** with a time in the center, Present/Late/Absent tiles, primary action button | Same | Attendance (labour) screen, and the daily production target ring |
| **Segmented tabs** ("My Requests / Team Requests") | Same | "Pending / Completed", "Sales / Purchases" |
| Month selector (‹ October 2025 ›) and summary card with line items | Same | Payroll / wages, monthly reports, ledger |
| Status pills (Approved green, Pending amber, Rejected red) | Same semantic colors | Paid / Partial / Due, Delivered / In-transit / Cancelled |
| Bottom navigation (4–5 icons with labels, active tab tinted) | Same | Home · Production · Sales · Stock · More |
| Side drawer with an accent header (avatar, name, role), menu list, help card and red Log Out | Same | Full module menu |

**Design principles**

1. **Glanceable first.** The most important number on each screen sits in the hero card. A factory owner should get the day's status in under 5 seconds.
2. **Calm surfaces, one accent.** Neutral backgrounds, white (or dark) cards, and a single accent color for emphasis and actions. Pastel tints carry meaning and are never decoration only.
3. **Fast data entry.** Supervisors log production and attendance on the floor, often outdoors. Inputs are big, steppers and presets beat free typing, and recent values are remembered.
4. **Consistent status language.** The same color always means the same thing (see 5.3).
5. **Theme-safe by construction.** No hard-coded colors. Every color comes from a token, so all 10 combinations (5 accents × light/dark) work automatically.

---

## 3. Users and Usage Context

> **v1 has multiple users with equal access and no roles** (see 01-PRD §3). The personas below are design guidance for the kinds of people who will use the app.

| Persona | Device | Main tasks | Design implication |
|---|---|---|---|
| **Owner** | Phone, sometimes tablet or desktop | Dashboard, profit, dues, reports | Clear KPIs and charts, read-mostly |
| **Factory Manager** | Phone | Production plan, stock, dispatch, approvals | Quick actions and approval flows |
| **Supervisor / Munshi** | Low to mid-range Android phone, outdoors | Daily production entry, labour attendance, raw material intake | Big touch targets, high contrast, works in sunlight, few steps, offline tolerant |
| **Accountant** | Desktop or tablet, sometimes phone | Sales, payments, expenses, wages, ledger | Dense tables on wide screens, filters, export |

**Environment constraints:** bright sunlight, dust, wet or gloved hands, intermittent network, budget phones (360×640 dp minimum), and users who prefer Bengali.

---

## 4. Brand Identity

- **Name:** FlyAsh (tentative product name; the in-app title and the factory's own name can be configured).
- **Logo concept:** a simple mark of 3 stacked bricks with an ash-cloud or leaf accent, meant to suggest "eco bricks from fly ash". It is drawn in the current accent color, so it follows the selected theme.
- **Tone:** professional, trustworthy, practical. No playful mascots in the core app. Illustrations are allowed on splash, onboarding and empty states only.
- **Illustration style:** flat vector, the accent color plus neutrals (the same style as the reference splash). Subjects: brick stacks, kiln or curing yard, truck, workers in helmets.

---

## 5. Color System

All colors are **semantic tokens**. Components refer to tokens (`color.primary`, `color.surface`), never to hex values. Each token has a light value and a dark value. Contrast ratios below were checked against WCAG 2.1: **AA (4.5:1) for text, 3:1 for icons and large text.**

### 5.1 Neutral tokens (shared by all accent themes)

| Token | Light | Dark | Usage |
|---|---|---|---|
| `background` | `#F5F7FB` | `#0B1120` | App background behind cards |
| `surface` | `#FFFFFF` | `#131B2E` | Cards, sheets, app bar, bottom nav |
| `surfaceVariant` | `#F1F4F9` | `#1A2338` | Search field, input fill, segmented track, list hover |
| `surfaceElevated` | `#FFFFFF` | `#1C2640` | Dialogs, menus, bottom sheets |
| `border` | `#E3E8F0` | `#26314A` | Card borders, dividers, input outlines |
| `textPrimary` | `#0F172A` | `#E2E8F0` | Headings, primary values (16.6:1 / 13.9:1) |
| `textSecondary` | `#475569` | `#94A3B8` | Labels, subtitles (7.6:1 / 6.7:1) |
| `textTertiary` | `#64748B` | `#7C8BA1` | Captions, timestamps, placeholders (4.8:1 / 5.0:1) |
| `textDisabled` | `#94A3B8` | `#4B5870` | Disabled text (exempt from contrast rules) |
| `overlay` | `rgba(15,23,42,0.45)` | `rgba(0,0,0,0.60)` | Scrim behind the drawer, dialogs and sheets |
| `shadow` | `rgba(15,23,42,0.06)` | none (use `border` instead) | Card elevation |

### 5.2 Accent color themes (user selectable)

Every theme defines the same 5 tokens. In **light mode** `primary` is a deep tone with white text on top. In **dark mode** `primary` becomes a lighter tone with dark text on top, so buttons and icons stay readable on dark surfaces.

| # | Theme | Mode | `primary` | `onPrimary` | `primaryContainer` | `onPrimaryContainer` | Contrast (onPrimary / primary-on-surface / container) |
|---|---|---|---|---|---|---|---|
| 1 | **Royal Blue** *(default, matches the reference)* | Light | `#1A56F0` | `#FFFFFF` | `#E8EFFF` | `#0B2A80` | 5.8 / 5.4 / 11.0 |
| | | Dark | `#7AA2FF` | `#0B1120` | `#16264D` | `#D6E2FF` | 7.6 / 6.9 / 11.4 |
| 2 | **Brick Terracotta** *(on-brand for bricks)* | Light | `#C2410C` | `#FFFFFF` | `#FDEDE4` | `#6B210A` | 5.2 / 5.2 / 10.0 |
| | | Dark | `#FF9467` | `#0B1120` | `#3D1F14` | `#FFDCCB` | 8.7 / 7.9 / 11.6 |
| 3 | **Emerald Green** *(eco / green bricks)* | Light | `#047857` | `#FFFFFF` | `#E3F6EE` | `#053D2E` | 5.5 / 5.5 / 10.9 |
| | | Dark | `#4ADE9F` | `#0B1120` | `#0F3327` | `#C8F2DE` | 11.0 / 10.0 / 11.3 |
| 4 | **Deep Violet** | Light | `#6D28D9` | `#FFFFFF` | `#F0E9FD` | `#3A1478` | 7.1 / 7.1 / 11.5 |
| | | Dark | `#B394FF` | `#0B1120` | `#2A1C4D` | `#E6DBFF` | 7.7 / 7.0 / 11.6 |
| 5 | **Ash Slate** *(the "fly ash" grey)* | Light | `#475569` | `#FFFFFF` | `#EEF1F5` | `#1E293B` | 7.6 / 7.6 / 12.9 |
| | | Dark | `#A5B4C8` | `#0B1120` | `#232D3D` | `#DCE3EC` | 8.9 / 8.1 / 10.7 |

**Token roles**

- `primary`: primary buttons, active bottom-nav item, links, focused input outline, progress ring arc, selected segmented tab, FAB, the hero card background (light mode).
- `onPrimary`: text and icons placed on `primary`.
- `primaryContainer`: selected chip background, active nav item pill, drawer item highlight, the hero card background in **dark mode** (a solid bright card is too harsh in dark mode).
- `onPrimaryContainer`: text and icons on `primaryContainer`.
- **Derived values:** pressed state = `primary` mixed 12% with `textPrimary`; hover = 8% overlay; focus ring = `primary` at 40% alpha, 2 dp.

> **Rule:** Accent themes change **only** these 5 tokens. Neutrals and status colors stay the same in every theme, so status meaning never shifts when the user changes the theme.

### 5.3 Semantic status colors (theme independent)

Used for status pills, KPI chip icons, alerts, toasts and chart highlights. Each has a **foreground** (text/icon) and a **soft background** (pill/chip fill).

| Token | Meaning in FlyAsh | Light fg / bg | Dark fg / bg |
|---|---|---|---|
| `success` | Paid, Delivered, Present, In stock, Approved, Completed | `#15803D` / `#DCFCE7` | `#4ADE80` / `#14301F` |
| `warning` | Pending, Partial payment, Late, Low stock, Curing | `#B45309` / `#FEF3C7` | `#FBBF24` / `#3A2A0C` |
| `error` | Due / Overdue, Rejected, Absent, Out of stock, Cancelled, Breakage | `#B91C1C` / `#FEE2E2` | `#F87171` / `#3B1717` |
| `info` | In transit, Scheduled, Draft, On leave | `#0369A1` / `#E0F2FE` | `#38BDF8` / `#0C2A3D` |
| `neutral` | Inactive, Archived, N/A | `textSecondary` / `surfaceVariant` | same tokens |

All foreground/background pairs pass **AA (4.5:1 or better)** in both modes.

### 5.4 KPI chip tints (decorative categorical)

The reference uses pink, green, amber and blue tinted icon squares in the KPI row. We keep these as **categorical tints**. They tell the 4 chips apart and carry no status meaning.

| Token | Light bg / icon | Dark bg / icon |
|---|---|---|
| `tint.rose` | `#FCE7F3` / `#BE185D` | `#3A1529` / `#F472B6` |
| `tint.green` | `#DCFCE7` / `#15803D` | `#14301F` / `#4ADE80` |
| `tint.amber` | `#FEF3C7` / `#B45309` | `#3A2A0C` / `#FBBF24` |
| `tint.sky` | `#E0F2FE` / `#0369A1` | `#0C2A3D` / `#38BDF8` |

### 5.5 Chart palette

Charts use the current `primary` for the main series. Other series use, in order: `tint.sky` icon, `tint.amber` icon, `tint.rose` icon, `tint.green` icon, `textTertiary`. Gridlines use `border`. Positive deltas use `success` and negative deltas use `error`, always with an arrow (↑/↓) as well, so meaning never depends on color alone.

---

## 6. Typography

| | |
|---|---|
| **Latin font** | **Inter** (Google Fonts, variable). Fallback: system sans |
| **Bengali font** | **Hind Siliguri** (pairs well with Inter). Alternative: Noto Sans Bengali |
| **Numerals** | Inter tabular figures (`tnum`) for all amounts, counts and tables, so columns line up |

Type scale (sp/px; line height in brackets):

| Token | Size / weight | Usage (reference example) |
|---|---|---|
| `display` | 32 / 700 (40) | Hero number ("48", "08:32 AM", "12,400") |
| `h1` | 24 / 700 (32) | Splash title, empty-state title |
| `h2` | 20 / 600 (28) | Screen title in the app bar ("Employees", "Payroll") |
| `h3` | 17 / 600 (24) | Section headers ("Quick Actions", "Today's Attendance") |
| `title` | 15 / 600 (22) | List item primary text, card titles, user name |
| `body` | 14 / 400 (20) | Default text |
| `bodyStrong` | 14 / 600 (20) | Amounts in line items ("EGP 25,000" style) |
| `label` | 13 / 500 (18) | Button text, tabs, chip labels, input labels |
| `caption` | 12 / 400 (16) | Subtitles, dates, KPI chip labels ("On Leave", "Late") |
| `micro` | 11 / 600 (14) | Status pills, bottom-nav labels, badges |

- Bengali text renders about 10% larger visually. Use the same tokens but allow a +2 line height for Bengali.
- **Font size preference** (Appearance setting): Small 0.9× · Default 1.0× · Large 1.15× · Extra Large 1.3×. Layouts must not clip at 1.3×.

---

## 7. Spacing, Shape, Elevation, Iconography, Motion

### 7.1 Spacing (4-pt grid)

`space.1 = 4` · `space.2 = 8` · `space.3 = 12` · `space.4 = 16` · `space.5 = 20` · `space.6 = 24` · `space.8 = 32` · `space.10 = 40`

- Screen side padding: **16** (phone), **24** (tablet), **32** (desktop).
- Card inner padding: **16**. Gap between cards: **12**. Section spacing: **24**.
- KPI chip row: 4 equal columns, 8 gap.

### 7.2 Corner radius

| Token | Value | Usage |
|---|---|---|
| `radius.sm` | 8 | Icon squares in chips, small tags |
| `radius.md` | 12 | Inputs, buttons, list cards, KPI chips |
| `radius.lg` | 16 | Hero card, main cards, bottom sheet top corners |
| `radius.xl` | 24 | Splash illustration card, onboarding |
| `radius.full` | 999 | Status pills, avatars, "Get Started" pill, segmented tab track, FAB |

### 7.3 Elevation

The reference is almost flat. We use **level 0** (border only) for list cards, **level 1** (`0 1 3 shadow`) for hero and summary cards, and **level 2** (`0 8 24 shadow`) for dialogs, menus and sheets. In dark mode there are no shadows: elevation is shown with a lighter surface (`surface` → `surfaceElevated`) and a `border`.

### 7.4 Iconography

- **Set:** Lucide / Phosphor style outline icons, 1.75 px stroke, rounded caps (like the reference).
- **Sizes:** 20 (inline / list), 24 (app bar, bottom nav), 28 (quick actions), 40–48 (empty states).
- Filled variants only for the **active** bottom-nav item.
- Domain icons needed: brick / bricks-stack, factory, kiln / flame, truck, cement bag, sand / pile, droplet (water), scale (weight), hard hat (worker), wallet, receipt, invoice, rupee/taka (configurable currency icon), wrench (machine), chart.

### 7.5 Motion

| Interaction | Spec |
|---|---|
| Screen push / pop | 250 ms, ease-out, slide + fade |
| Bottom sheet / drawer | 300 ms, emphasized decelerate |
| Theme or mode change | 200 ms cross-fade of colors. **No layout jump** |
| Button press | Scale 0.98, 100 ms, plus ripple |
| Progress ring / counters | Animate from 0 on first view, 600 ms |
| **Reduce motion** (OS setting) | Turn off slides and counters; use instant cross-fades only |

---

## 8. Appearance and Theming Feature

### 8.1 Settings → Appearance screen

```
┌──────────────────────────────────────┐
│ ‹  Appearance                        │
├──────────────────────────────────────┤
│  THEME MODE                          │
│  ┌────────┐ ┌────────┐ ┌────────┐    │
│  │ ☀ Light│ │ ☾ Dark │ │ ⚙ System│   │  ← 3 preview tiles, the selected one
│  │ [mini] │ │ [mini] │ │ [split]│    │    gets a primary outline + check
│  └────────┘ └────────┘ └────────┘    │
│                                      │
│  ACCENT COLOR                        │
│   ●     ●     ●     ●     ●          │  ← 5 swatches (44 dp), selected = ring + ✓
│  Blue  Brick Emerald Violet Slate    │
│                                      │
│  FONT SIZE                           │
│  A ───────●──────────── A            │  ← 4 steps: S / Default / L / XL
│                                      │
│  PREVIEW                             │
│  ┌──────────────────────────────┐    │  ← live mini dashboard: hero card,
│  │ Today's Production  12,400   │    │    2 KPI chips, a pill and a button
│  │ [Stock] [Orders]  (Paid)     │    │    rendered with the current tokens
│  │ [ Primary Button ]           │    │
│  └──────────────────────────────┘    │
│                                      │
│  [ Reset to default ]                │  ← text button
└──────────────────────────────────────┘
```

### 8.2 Behaviour rules

1. **Theme mode:** `System` (default) follows the OS setting and updates live when the OS changes. `Light` and `Dark` override it.
2. **Accent color:** default is **Royal Blue**. Tapping a swatch applies it **instantly** with no confirm and no restart.
3. **Persistence:** theme mode and accent color are **saved to the user's account** (`PUT /auth/preferences` → `users.theme_mode`, `users.accent_color`), so each user sees their own theme on every device. A local copy is cached and restored before the first frame so there is no flash of the wrong theme; after login the account values replace the cache. Font size is saved on the device only. Before login (splash, login screens) the last cached theme is used.
4. **Scope:** the theme applies to the whole app, including the splash, the logo color, charts, the status bar and navigation bar colors, and the system-UI icon brightness.
5. **Splash before preferences load:** use the saved theme if it is cached, otherwise Royal Blue / System.
6. **Printed and PDF output** (invoices, challans, reports) always uses **light mode with the factory's brand color**, not the user's app theme.
7. **Quick toggle:** the side drawer has a small sun/moon icon button next to the user's name to switch Light/Dark without opening Settings.

### 8.3 Implementation rules for developers

- Define one `ThemeTokens` object per (mode × accent) = **10 combinations**, generated from §5 neutrals + §5.2 accent + §5.3 status.
- Components read tokens only. **Lint rule / code review check:** no hex literals or framework default colors in screen or component code.
- Expose the tokens through the framework's theme provider (for example `ThemeData` + `ThemeExtension` in Flutter, or CSS custom properties on `:root[data-theme][data-accent]` on the web).
- Every new component must be checked in **all 10 combinations** before merge (a widget gallery / Storybook page renders them side by side).

---

## 9. Component Library

Each component lists its anatomy, its variants and the reference screen it comes from.

### 9.1 App bars

- **Home header** (Dashboard): avatar 40, greeting (`caption`, `textSecondary`), name (`title`), role link "Manager ›" (`caption`, `primary`), and a notification bell with a red dot badge on the right.
- **Standard app bar:** back chevron ‹, title (`h2`), up to 2 trailing actions (calendar, ⊕ add, filter). Surface color, no shadow; a bottom `border` shows only after scrolling.

### 9.2 Hero stat card

- `radius.lg`, padding 20, background `primary` (light) or `primaryContainer` (dark).
- Leading icon in a 44 dp square (white at 18% alpha). Label (`caption`), value (`display`), and a trend line ("↑ 8% vs yesterday", `caption`, `success` / `error` with arrow). A trailing chevron › makes it tappable.
- One hero card per screen at most.

### 9.3 KPI chip

- Equal-width tile, `radius.md`, `surface` with a `border`. It contains a 32 dp tinted icon square (`tint.*`, `radius.sm`), a label (`caption`, `textSecondary`) and a value (`h3`, `textPrimary`).
- Layout: 4 per row on phone (2×2 if Font size is XL), up to 6 per row on tablet.

### 9.4 Quick action tile

- 2-column grid, `radius.md`, `surface` with a `border`, height 64. It contains a 36 dp icon in a `primaryContainer` circle and a label (`label`).
- Pressed: `surfaceVariant` background.

### 9.5 Search and filter bar

- Search field: `surfaceVariant` fill, `radius.md`, height 44, search icon, placeholder "Search workers…".
- Filter button: 44×44, `radius.md`. A small `primary` dot appears when filters are active.
- Filters open in a **bottom sheet** (date range, status chips, sort).

### 9.6 Summary stat strip

The row under the search bar on list screens (for example "Total 48 · Active 45 · On leave 3"). It has 3 small cards, each with a colored dot (status color), a caption and a value.

### 9.7 List item (entity row)

```
[Avatar/Icon 40]  Title (title)                    (Status pill)  ⋮
                  Subtitle (caption, secondary)
                  Meta (caption, tertiary)                  Amount/time
```

- Card style (each row is its own card with a 12 gap), or grouped (rows inside one card with dividers). Pick one per screen.
- The leading element is an **avatar** (people), a **tinted icon square** (orders, materials, expenses) or a **date block**.
- Swipe actions (optional): call / edit / delete, with an undo toast for delete.
- The overflow ⋮ opens a menu: View · Edit · Share · Delete (destructive in `error`).

### 9.8 Status pill

`radius.full`, height 22, horizontal padding 10, `micro` text, `status.bg` fill and `status.fg` text. Optional 6 dp leading dot. The **text is always present**; color is never the only signal.

### 9.9 Segmented tabs

A full-width track (`surfaceVariant`, `radius.full`, height 40) with 2–3 segments. The selected segment is `surface` with level 1 elevation and `primary` text; the others use `textSecondary`. Switching animates in 200 ms.
Alternative: an underline tab style for 3 or more tabs (as in the reference's "My Overtime / Team Overtime").

### 9.10 Period selector

`‹  October 2026  ›` centered in a `surface` card, with a tappable label that opens a month/date picker. Variants: Day / Week / Month / Custom range.

### 9.11 Progress ring

A 160 dp ring with a 10 dp stroke: `primary` arc on a `surfaceVariant` track. The center holds a status dot and label, the main value (`display`) and a sub-caption.
FlyAsh uses: **production vs. daily target** ("9,300 / 12,000 bricks · 78%"), attendance clock-in, and the kiln/curing cycle progress.

### 9.12 Line-item summary card

As in the reference Payroll card: rows of icon + label + right-aligned amount (`bodyStrong`, tabular), a divider, then a total row (`title`, bold). Deductions are shown in `error` with "−".
Used for wages, invoice totals, daily cash summary and production cost breakdown.

### 9.13 Buttons

| Variant | Style | Usage |
|---|---|---|
| Primary | `primary` fill, `onPrimary` text, height 48, `radius.md`, full width on mobile forms | Main action (Save, Clock Out, View Payslip) |
| Secondary | `primaryContainer` fill, `onPrimaryContainer` text | Second action |
| Outline | `border` outline, `textPrimary` | Cancel, filters |
| Text | No fill, `primary` text | "View all", "Reset" |
| Destructive | `error` fill, white text (only inside confirm dialogs) | Delete, Cancel order |
| Pill CTA | White fill, `primary` text, `radius.full` | Splash "Get Started →" |
| FAB | 56 dp, `primary`, ⊕ icon | Add on list screens (alternative to ⊕ in the app bar; pick one per screen) |

States: default, pressed, focused (ring), disabled (38% opacity), loading (spinner replaces the label, width stays the same).

### 9.14 Form inputs

- Text field: label above (`label`), field height 48, `surface` with a `border` (or `surfaceVariant` fill), `radius.md`. Focus: 2 dp `primary` border. Error: `error` border and helper text below.
- **Number stepper** (− value +) for brick counts, bags and trips, with large ± targets (48 dp).
- **Quick-fill chips** under number fields (for example "1,000 · 2,000 · 5,000").
- Dropdown / searchable select (bottom sheet on mobile), date picker, toggle switch, radio cards, and an amount field with the currency prefix.
- Required fields are marked with `*`. Validate on blur and on submit; never block typing.
- The keyboard type matches the field (numeric for quantities and phone numbers).

### 9.15 Feedback and states

| State | Pattern |
|---|---|
| Loading (first load) | Skeleton shimmer in the card's shape (no full-screen spinners) |
| Loading (refresh) | Pull-to-refresh indicator in `primary` |
| Empty | Illustration (48–120 dp), `h3` title, one-line hint, primary action ("No sales yet · Create first sale") |
| Error | Inline card with an `error` icon, a message and a "Retry" button |
| Offline | Thin `warning` banner at the top: "Offline: changes will sync when connected". Unsynced records show a small cloud-off icon |
| Success | Toast / snackbar at the bottom, 3 s, with an optional "Undo" |
| Destructive confirm | Dialog: title, consequence text, Cancel (outline) + Delete (destructive) |
| Badge | Red dot or count on the bell and nav icons |

### 9.16 Navigation components

- **Bottom navigation** (phone): 4 items (Home, Sales, Attendance, Expenses), 24 dp icons with `micro` labels. Active: filled icon, `primary` color, and a `primaryContainer` pill behind the icon. Inactive: `textTertiary`. Height 64 plus the safe area.
- **Side drawer** (opened from the ☰ button on the left of the app bar, or by swiping): header block (`primary` background in light mode, `primaryContainer` in dark) with avatar 48, name, role › and the theme toggle. Then the module menu list (icon 20 + `body`); the active item gets a `primaryContainer` pill. A **"Need help? Contact support"** card sits at the bottom, with **Log Out** in `error`.
- **Navigation rail** (tablet ≥ 600 dp) and **persistent sidebar** (desktop ≥ 1024 dp) replace the bottom nav and drawer.

---

## 10. Information Architecture and Screens (v1)

> Matches the v1 scope in **01-PRD**. Detailed screen-to-screen flows are in **03-AppFlow**.

### 10.1 Navigation map

```
Bottom nav:  Home │ Sales │ Attendance │ Expenses      (☰ in the app bar opens the drawer)

Drawer (☰):
  Dashboard · Sales · Upcoming Deliveries · Customers · Products
  Labours · Attendance · Wages & Advances · Expenses · Reports
  Users
  Settings (My profile · Factory profile · Appearance · Language · Password · About & Updates)
```

### 10.2 Screen briefs

| Screen | Key composition |
|---|---|
| **Splash** | Full `primary` background, logo, "FlyAsh", tagline ("Smarter Bricks. Stronger Business."), loader while the session and update check run |
| **Login** | Logo, phone/email + password, primary "Sign in", text button **"Forgot password?"** under the password field, language switch (EN / বাংলা) at the top right |
| **Forgot password: email** | Back ‹, title "Forgot password", hint "Enter the email linked to your account", email field, primary "Send OTP". Then a neutral message: "If this email is registered, an OTP has been sent". Footer hint: "No email? Ask another user to reset your password" |
| **Forgot password: verify OTP** | Back ‹, title "Verify OTP", "OTP sent to r•••@gmail.com", **6 separate OTP boxes** (auto-advance, paste support, numeric keyboard, auto-submit on the 6th digit), primary "Verify", "Resend OTP in 0:59" countdown that turns into a text button. Wrong OTP → boxes shake + `error` text "Wrong OTP · 4 tries left" |
| **Forgot password: new password** | Title "Set new password", new password + confirm (show/hide eye), live rule hint "At least 6 characters", primary "Reset password". Back ‹ asks "Cancel password reset?". Success → toast "Password changed. Please log in" → Login. Expired token → dialog "Session expired, please start again" → Email screen |
| **Dashboard (Home)** | Home header (logged-in user, factory name, bell) → hero card *Today's Sales* (₹ amount, number of sales) with today's profit → KPI row (Total due · Deliveries today · Present today · Month expenses) → Quick actions (New Sale · New Booking · Attendance · Add Expense) → recent sales list |
| **Sales list** | Segmented: *All / Instant / Booking*. Search + filter sheet (date range, status). Row: customer initials avatar, name, invoice no. + date, ₹ total, pill (*Paid* `success` / *Partial* `warning` / *Due* `error` / *Booked* `info` / *Cancelled* `neutral`). FAB "New Sale" |
| **New / Edit Sale (form)** | Type toggle (Instant / Booking) → customer picker (search sheet with "+ New customer" inline) → item cards (product select, quantity stepper, cost and price pre-filled and editable) + "Add item" → transport and discount → payment received + method → booking: delivery date and address → **sticky summary bar** (Total · Profit · Due) + primary "Save" |
| **Sale detail** | Header with invoice no. + status pills → customer card (call / WhatsApp) → items → line-item summary card (subtotal, transport, discount, **total**, cost, **profit** in `success`, paid, **due** in `error`) → payments list → actions: Add payment · Mark delivered · Cancel · Edit · Share receipt |
| **Upcoming deliveries** | List of booked sales by delivery date. Overdue rows get an `error` "Overdue" pill. Each row has a "Mark delivered" action |
| **Customers** | Search, "Has due" filter chip. Row: initials avatar, name, phone, due ₹ on the right (`error` when > 0). Detail: contact card, summary strip (Purchases · Paid · Due), sales list |
| **Products** | List rows: tinted brick icon, name, unit, cost → price, margin. Inactive products are dimmed with an "Inactive" pill. Form: name, unit, default cost, default price, notes |
| **Labours** | Search. Row: avatar, name, wage ("₹500 / day" or "₹15,000 / month"), today's status pill. Form: name, phone, address, wage type toggle, amount, joining date |
| **Attendance** | Adapted from the reference: date selector (‹ Today, 08 Nov ›, future dates disabled) → ring (present / total) → tiles Present · Half Day · Absent · Not marked → "Mark all present" → list with a **3-state segmented toggle per labour** (P / H / A, 48 dp targets) → sticky "Save attendance" |
| **Wages** | Month selector → hero card (total earned this month) → summary strip (Advances · Paid · Balance) → list per labour: days worked, earned, balance, pill (*Paid / Partial / Due*). Detail: calculation breakdown card (worked days × rate, − advances, − paid = balance), "Give advance" and "Pay wage" buttons |
| **Expenses** | Period selector → total hero → category chips (filter) → expense rows (category icon, note, date, ₹) → FAB "Add expense". Form: date, category select (+ new), amount, note |
| **Reports** | Tiles grid: Sales · Dues · Expenses · Wages · **Net Profit** · Collections. Each opens a period selector + chart + table + export (PDF / Excel) |
| **Users** | Search. Row: initials avatar, name, phone, last login, pill (*Active* `success` / *Inactive* `neutral`). **The logged-in user is not listed.** FAB "Add user". Form: name, phone, email, password (on create only). Detail actions: Edit · Reset password · Deactivate/Activate. Empty state: "Only you so far · Add user" |
| **My Profile** | Avatar with initials, name, phone, email, last login → "Edit profile" (name, phone, email) and "Change password" (old + new + confirm) |
| **Settings** | Groups: My profile · Factory profile · Appearance (§8.1) · Language · Change password · About & Updates (version, "Check for updates") · Logout |
| **Update dialog / screen** | Optional: dialog with version, release notes, "Later" / "Update now", and a download progress bar. Forced: full-screen blocking page with an illustration and a single "Update" button |

---

## 11. Layout and Responsiveness

| Breakpoint | Width | Navigation | Grid |
|---|---|---|---|
| Compact (phone) | < 600 dp | Bottom nav + drawer | 4 columns, 16 margin |
| Medium (tablet) | 600–1023 dp | Navigation rail (+ drawer for the full menu) | 8 columns, 24 margin; list-detail split view on lists |
| Expanded (desktop / web) | ≥ 1024 dp | Persistent sidebar (240 dp, collapsible to 72) | 12 columns, 32 margin, content max-width 1280 |

- Lists turn into **data tables** on expanded layouts (sortable columns, sticky header, row actions on hover).
- Dashboard: KPI row goes from 4 → 6 columns; Quick actions and the summary card sit side by side.
- Forms: single column, max-width 560, centered, on tablet and desktop.
- Respect safe areas (notch, gesture bar). Phone layouts are portrait only; tablet and desktop work in both orientations.

---

## 12. Data Display Conventions

| Data | Format |
|---|---|
| Brick counts | Thousands separators, no decimals: `12,400 pcs`. Large numbers abbreviated only in KPI chips: `1.2 L` / `12.4K` (style follows the locale setting) |
| Currency | **₹** with Indian grouping (`₹1,00,000`). Right-aligned, tabular figures, 0 decimals in lists and 2 on receipts |
| Weights / volumes | `tonnes` (2 decimals), `bags`, `cft`, `trips`. The unit is always shown |
| Dates | `08 Nov 2026` in lists, `Today` / `Yesterday` for recent items. Time `08:32 AM` (12-hour by default) |
| Deltas | `↑ 8%` in `success` / `↓ 3%` in `error`, always with the arrow |
| Phone numbers | Tap to call; a WhatsApp action where relevant |
| Empty values | Show `—`, never a blank |

---

## 13. Accessibility and Localization

**Accessibility**

- Every text and icon pair meets **WCAG 2.1 AA** in all 10 theme combinations (verified in §5).
- Touch targets **≥ 48×48 dp** (≥ 56 for the main floor-entry actions: steppers, Save, attendance toggles).
- Status is never shown by color alone. Pills always have text, and charts have labels and arrows.
- Screen-reader labels on all icon-only buttons (bell, filter, ⊕, ⋮, theme toggle).
- Dynamic text up to 1.3× without clipping or overlap; scrolling is preferred over truncation for important values.
- Visible focus rings for keyboard use on desktop.
- Reduce motion is respected (§7.5).

**Localization**

- Languages at launch: **English** and **বাংলা (Bengali)**. The language is switchable in Settings and on the Login screen, independent of the theme. Once logged in, the choice is saved to the user's account.
- All strings live in resource files. No text inside images.
- Plan for Bengali strings being about 20–30% longer: buttons grow in width, and labels wrap to 2 lines rather than truncating.
- Number display: Latin digits by default, with an optional Bengali digits (০১২৩…) setting. *(To be confirmed.)*

---

## 14. Decisions (settled)

| Topic | Decision |
|---|---|
| Platforms | **Android + Web + Windows** in v1 (iOS/macOS in Phase 2) |
| Currency | **₹ INR**, Indian grouping (`₹1,00,000`) |
| Users | **Multiple users, all equal (no roles).** No sign-up: the first user is created on the server, and users add other users |
| Theme sync | Theme mode and accent color saved to the user's account (`users.theme_mode`, `users.accent_color`); font size per device |
| Language sync | Saved to the user's account (`users.locale`), so it follows the user to every device |
| Factory branding | The factory name from Settings and a **static logo bundled in the app** appear in the app header and on receipts. No images are uploaded or stored on the server |
| Offline | Online only in v1. Offline entry in Phase 2 |
| Bengali digits | Not in v1 (Latin digits) |

---

## 15. Deliverables Checklist (design phase)

- [ ] Token file: 10 theme combinations (JSON / Dart / CSS) generated from §5
- [ ] Component gallery covering every §9 component in all 10 combinations
- [ ] Hi-fi mockups: Splash, Login, Dashboard, Sales list, New Sale, Sale detail, Customers, Attendance, Wages, Expenses, Reports, Settings → Appearance, Update dialog (light and dark, Royal Blue + one other accent)
- [ ] Icon set (outline + filled active), including the domain icons in §7.4
- [ ] Illustrations: splash, 3 onboarding pages, 6 empty states
- [ ] App icon and logo in each accent color
