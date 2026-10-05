#!/bin/sh
# Сборка APK в docker-контейнере с Android SDK (ставить SDK на машину не нужно).
#
#   cd mobile && sh scripts/build-apk.sh                              # боевой: https://bibleox.com
#   cd mobile && API_BASE=http://192.168.3.21 sh scripts/build-apk.sh # dev: локальный сервер в wi-fi сети
#
# Результат: mobile/apk/bibleox-<версия>.apk (dev-сборка: bibleox-<версия>-dev.apk)
set -e
cd "$(dirname "$0")/.."

IMAGE=ghcr.io/cirruslabs/android-sdk:36
# aapt2 от Google есть только под x86_64, поэтому на Mac с Apple Silicon — через эмуляцию amd64
PLATFORM="--platform linux/amd64"
VERSION=$(node -p "require('./package.json').version")

DOCKER=${DOCKER:-docker}
if ! "$DOCKER" version >/dev/null 2>&1; then
  DOCKER=/Applications/Docker.app/Contents/Resources/bin/docker
fi

GRADLE_ARGS=""
SUFFIX=""
if [ -n "$API_BASE" ]; then
  # dev-сборка: адрес сервера зашиваем при сборке, разрешаем http и смешанный контент
  echo "Dev-сборка, сервер: $API_BASE"
  VITE_API_BASE="$API_BASE" npm run build
  GRADLE_ARGS="-PdevCleartext=true"
  SUFFIX="-dev"
else
  npm run build
fi
npx cap sync android

if [ -n "$API_BASE" ]; then
  node -e "
    const f = 'android/app/src/main/assets/capacitor.config.json'
    const c = JSON.parse(require('fs').readFileSync(f, 'utf8'))
    c.android = { ...(c.android || {}), allowMixedContent: true }
    require('fs').writeFileSync(f, JSON.stringify(c, null, 2))
  "
fi

# Ключ подписи создаётся один раз. ЕГО НУЖНО СОХРАНИТЬ: без него обновление не встанет поверх старой версии.
if [ ! -f android/keystore.properties ]; then
  PASS=$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 24)
  "$DOCKER" run --rm $PLATFORM -v "$PWD/android":/project -w /project "$IMAGE" \
    keytool -genkeypair -v -keystore bibleox-release.keystore -alias bibleox \
      -keyalg RSA -keysize 4096 -validity 36500 \
      -storepass "$PASS" -keypass "$PASS" -dname "CN=Bibleox, O=Bibleox"
  printf 'storeFile=bibleox-release.keystore\nstorePassword=%s\nkeyAlias=bibleox\nkeyPassword=%s\n' "$PASS" "$PASS" > android/keystore.properties
  echo "Создан ключ подписи: android/bibleox-release.keystore (+ keystore.properties). Сохраните их в надёжном месте!"
fi

"$DOCKER" run --rm $PLATFORM \
  -v "$PWD":/project \
  -v bibleox-gradle-cache-amd64:/root/.gradle \
  -w /project/android \
  "$IMAGE" ./gradlew --no-daemon assembleRelease $GRADLE_ARGS

mkdir -p apk
cp android/app/build/outputs/apk/release/app-release.apk "apk/bibleox-$VERSION$SUFFIX.apk"
echo "Готово: mobile/apk/bibleox-$VERSION$SUFFIX.apk"
