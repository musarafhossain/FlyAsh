# FlyAsh: Project Documents

FlyAsh is a sales, labour and expense management app for a fly ash brick factory.
It runs on **Android, Web and Windows**, built with **Flutter + AdonisJS + MariaDB**.

| # | Document | What it answers |
|---|---|---|
| 01 | [PRD](01-PRD.md) | **What** we build: features, business rules, calculations |
| 02 | [TRD](02-TRD.md) | **How** we build it: stack, architecture, API standards, deployment |
| 03 | [App Flow](03-AppFlow.md) | How users move between screens, and what each action does |
| 04 | [UI/UX Design Brief](04-UI-UX-Design-Brief.md) | How it looks: themes, colors, components, screens |
| 05 | [Backend Schema](05-Backend-Schema.md) | Database tables, columns, calculations, API data contracts |
| 06 | [Implementation Plan](06-Implementation-Plan.md) | The order of work, step by step, with done criteria |

**Read order for a new developer:** 01 → 02 → 05 → 03 → 04 → 06.

**Key decisions**
- Multiple users, all equal (no roles). No sign-up: the first user is created on the server.
- ₹ INR with Indian grouping. English + Bengali UI.
- Online only in v1 (offline entry in Phase 2).
- API envelope `{ success, status_code, message, data }`. Pagination uses `page` + `limit`.
- Light / Dark / System mode and 5 accent themes.
