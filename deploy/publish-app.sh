#!/usr/bin/env bash
# Publish an app update from the PC (F18, docs/09-Deployment.md).
#
#   bash deploy/publish-app.sh android "Reports, receipts and in-app update"
#   bash deploy/publish-app.sh android "Important fix" 3   # builds below 3 must update
#   bash deploy/publish-app.sh web "New reports"
#
# Version and build come from app/pubspec.yaml (version: 1.1.0+2): raise them
# first. Android: builds the signed APK (needs android/key.properties),
# uploads it to /var/www/flyash/downloads/ and registers it with
# `node ace app:release`. Web: builds, uploads and registers the web build.
set -euo pipefail

PLATFORM=${1:?android or web}
NOTES=${2:?release notes}
MIN_BUILD=${3:-0}
HOST=musaraf-vps
SITE=https://flyash.musaraf.org.in
REMOTE=/var/www/workspace/FlyAsh
DOWNLOADS=/var/www/flyash/downloads

cd "$(dirname "$0")/../app"
VERSION_LINE=$(grep '^version:' pubspec.yaml | awk '{print $2}')
VERSION=${VERSION_LINE%+*}
BUILD=${VERSION_LINE#*+}
echo "Publishing $PLATFORM $VERSION (build $BUILD)…"

release() { # $1 = extra flags
  ssh "$HOST" ". /root/.nvm/nvm.sh >/dev/null && cd $REMOTE/backend/build && \
    node ace app:release --platform=$PLATFORM --version=$VERSION --build=$BUILD \
    --min-build=$MIN_BUILD $1 --notes=$(printf '%q' "$NOTES")"
}

case "$PLATFORM" in
  android)
    [ -f android/key.properties ] || { echo "android/key.properties missing (release key)"; exit 1; }
    # 64-bit phones only (the app is used on new phones): ~23 MB instead of
    # ~40 MB with 32-bit too. Obfuscated; crash symbols in build/symbols/<version>.
    flutter build apk --release --target-platform android-arm64 \
      --obfuscate --split-debug-info=build/symbols/$VERSION \
      --dart-define=API_BASE_URL=$SITE/api/v1
    FILE=flyash-$VERSION.apk
    ssh "$HOST" "mkdir -p $DOWNLOADS"
    scp build/app/outputs/flutter-apk/app-release.apk "$HOST:$DOWNLOADS/$FILE"
    release "--url=$SITE/downloads/$FILE"
    curl -fsSI "$SITE/downloads/$FILE" | head -1
    ;;
  web)
    flutter build web --release --dart-define=API_BASE_URL=$SITE/api/v1
    tar czf /tmp/flyash-web.tgz -C build/web .
    scp /tmp/flyash-web.tgz "$HOST:/tmp/"
    ssh "$HOST" "W=$REMOTE/app/build/web; rm -rf \$W.new && mkdir -p \$W.new && \
      tar xzf /tmp/flyash-web.tgz -C \$W.new && rm -rf \$W && mv \$W.new \$W && rm /tmp/flyash-web.tgz"
    rm /tmp/flyash-web.tgz
    release ""
    ;;
  *) echo "platform must be android or web"; exit 1 ;;
esac

curl -fsS "$SITE/api/v1/app/version?platform=$PLATFORM&build=1" && echo
echo "Done."
