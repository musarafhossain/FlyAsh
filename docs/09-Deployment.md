# 09 · Deployment (test server)

**URL:** https://flyash.musaraf.org.in. One domain:

| Path | Goes to |
|---|---|
| `/api/v1/*` | Adonis API (PM2 `flyash-api`, `127.0.0.1:3334`) |
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

## Handy commands

```bash
pm2 logs flyash-api          # API logs; in test mode OTP mails are printed here
pm2 restart flyash-api
cd /var/www/workspace/FlyAsh/backend/build && node ace user:create --name=".." --phone=.. --email=.. --password=..
```

## Mail

On the test server mail is `MAIL_MAILER=log`, so nothing is sent and OTP codes show in `pm2 logs flyash-api`. For production, set `MAIL_MAILER=smtp` and the `SMTP_*` values in `backend/.env`, then run `pm2 restart flyash-api --update-env`.
