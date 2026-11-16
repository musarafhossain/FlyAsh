# 09 · Deployment (test server)

**URL:** https://flyash.musaraf.org.in. One domain:

| Path | Goes to |
|---|---|
| `/api/v1/*` | Adonis API (PM2 `flyash-api`, `127.0.0.1:3334`) |
| `/downloads/*` | App update files (APK / EXE) in `/var/www/flyash/downloads/` |
| everything else | Flutter web build (`app/build/web`, with SPA fallback) |

## Server layout

| What | Where |
|---|---|
| Code (git clone of `main`) | `/var/www/workspace/FlyAsh` |
| Backend secrets | `backend/.env` (not in git; copied to `backend/build/.env` on deploy) |
| Nginx site | `/etc/nginx/sites-available/flyash.musaraf.org.in` (from `deploy/nginx-flyash.conf`, plus certbot's HTTPS block) |
| Process | PM2 (`backend/ecosystem.config.cjs`); `pm2-root` service restarts it after a reboot |
| Database | MySQL 8 on the VPS, DB `flyash` |
| Node | nvm, v24 (`/root/.nvm`) |

Port 3333 is used by another app on this VPS, so FlyAsh uses **3334**.

## Update the backend

```bash
ssh musaraf-vps
bash /var/www/workspace/FlyAsh/deploy/deploy.sh
```

This runs `git pull`, then `npm ci`, build, migrations, PM2 reload and the health check.

## Update the web app

Build it on the PC, because the VPS has no Flutter and only 2 GB RAM:

```bash
cd app
flutter build web --release --dart-define=API_BASE_URL=https://flyash.musaraf.org.in/api/v1
tar czf flyash-web.tgz -C build/web .
scp flyash-web.tgz musaraf-vps:/tmp/
ssh musaraf-vps 'W=/var/www/workspace/FlyAsh/app/build/web; rm -rf $W.new && mkdir -p $W.new && tar xzf /tmp/flyash-web.tgz -C $W.new && rm -rf $W && mv $W.new $W && rm /tmp/flyash-web.tgz'
```

## Publish an app update (F18)

1. Raise `version:` in `app/pubspec.yaml` (e.g. `1.1.0+2` → `1.2.0+3`; the `+N` build number must go up every time).
2. Run from the repo on the PC (Git Bash):

```bash
bash deploy/publish-app.sh android "What is new"        # optional update
bash deploy/publish-app.sh android "Important fix" 3    # builds below 3 must update
bash deploy/publish-app.sh web "What is new"            # web build + reload prompt
```

Android builds the signed APK (64-bit phones only, obfuscated, ≈23 MB; crash symbols in `app/build/symbols/<version>`), uploads it as `/var/www/flyash/downloads/flyash-<version>.apk` (`https://flyash.musaraf.org.in/downloads/…`) and runs `node ace app:release`. Installed apps see the update on their next launch or from Settings → About → Check for updates.

**Release key:** `app/android/key.properties` + `app/android/app/flyash-release.jks` (not in git). Keep a copy somewhere safe (USB drive / cloud). Without them no update can be installed over the app.

The first APK with the updater (1.1.0+2) is installed by hand once. The test APK from 9 Nov is signed with a different (debug) key, so uninstall it first.

## Test database with fake data (`flyash_test`)

`flyash_test` is a copy of `flyash` (made on 2026-11-16) with everything emptied except `users`, `auth_access_tokens`, `factory_settings` (invoice counter reset to 0) and `app_versions`, then filled with 6 months of fake data. The live API keeps using `flyash`; `flyash_test` is only for trying things (point a test API at it with `DB_DATABASE=flyash_test`).

Re-fill it with fresh fake data (empties it again first; keeps users, tokens, factory profile, app versions): `bash /root/flyash_test_reset.sh` on the VPS (a copy of the steps below, without the copy from `flyash`).

Re-create it from the live data (as root on the VPS):

```bash
F=/root/flyash-backup-$(date +%Y%m%d-%H%M%S).sql.gz; mysqldump --single-transaction flyash | gzip > $F
mysql -e "DROP DATABASE IF EXISTS flyash_test; CREATE DATABASE flyash_test CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysqldump --single-transaction flyash | mysql flyash_test
# empty all tables except the kept ones, reset the invoice counter
KEEP="'adonis_schema','adonis_schema_versions','users','auth_access_tokens','factory_settings','app_versions'"
SQL=$(mysql -N -e "SELECT CONCAT('TRUNCATE TABLE \`', table_name, '\`;') FROM information_schema.tables WHERE table_schema='flyash_test' AND table_name NOT IN ($KEEP);")
mysql flyash_test -e "SET FOREIGN_KEY_CHECKS=0; $SQL UPDATE factory_settings SET last_invoice_no=0; SET FOREIGN_KEY_CHECKS=1;"
cd /var/www/workspace/FlyAsh/backend/build && . /root/.nvm/nvm.sh && DB_DATABASE=flyash_test node ace demo:seed --months=6
```

`node ace demo:seed` (`commands/demo_seed.ts`) refuses any database whose name does not contain "test". It creates 6 products, 60 customers (a few without phone, one inactive), 1–3 sales a day with payments (full / part / later), bookings (most delivered, a few cancelled), 5–18 % tax on some, 16 labours (2 monthly, one who left, two who joined later) with daily attendance, monthly wage payments, and daily + monthly expenses. Sales go through `SaleService`, so totals, dues and invoice numbers are real. The same seed gives the same data every time.

## Handy commands

```bash
pm2 logs flyash-api          # API logs; in test mode OTP mails are printed here
pm2 restart flyash-api
cd /var/www/workspace/FlyAsh/backend/build && node ace user:create --name=".." --phone=.. --email=.. --password=..
```

## Mail

On the test server mail is `MAIL_MAILER=log`, so nothing is sent and OTP codes show in `pm2 logs flyash-api`. For production, set `MAIL_MAILER=smtp` and the `SMTP_*` values in `backend/.env`, then run `pm2 restart flyash-api --update-env`.
