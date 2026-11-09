#!/usr/bin/env bash
# Update the backend on the VPS from GitHub main.
#   bash /var/www/workspace/FlyAsh/deploy/deploy.sh
# The web app is built on a PC and uploaded to app/build/web (see docs/09-Deployment.md).
set -euo pipefail

ROOT=/var/www/workspace/FlyAsh
export NVM_DIR=/root/.nvm
. "$NVM_DIR/nvm.sh" >/dev/null

cd "$ROOT"
git pull --ff-only

cd backend
npm ci --no-audit --no-fund
node ace build
cp .env build/.env
cd build
npm ci --omit=dev --no-audit --no-fund
node ace migration:run --force

cd ..
if pm2 describe flyash-api >/dev/null 2>&1; then
  pm2 reload ecosystem.config.cjs --update-env
else
  pm2 start ecosystem.config.cjs
fi
pm2 save

sleep 2
curl -fsS http://127.0.0.1:3334/api/v1/health && echo && echo "Deployed."
