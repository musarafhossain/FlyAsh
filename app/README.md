# FlyAsh app (Flutter)

Android · Web · Windows client for the FlyAsh API. Architecture and rules: `../docs/02-TRD.md` §7.
Build plan: `../docs/08-Flutter-Plan.md`.

## Requirements

- Flutter 3.41+ (Dart 3.11)
- The API running (see `../backend/README.md`)
- Android: run `flutter doctor --android-licenses` once and accept all licenses

## Run

```bash
flutter pub get

# Web (Chrome)
flutter run -d chrome --web-port 5000 --dart-define=API_BASE_URL=http://localhost:3333/api/v1

# Windows
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:3333/api/v1

# Android emulator
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3333/api/v1
```

Without `--dart-define`, the API URL defaults to `http://localhost:3333/api/v1`.

## Commands

| Command | Purpose |
|---|---|
| `flutter analyze` | Lints |
| `flutter test` | Tests |
| `dart run build_runner build --delete-conflicting-outputs` | Generate freezed / JSON code |
| `dart run flutter_launcher_icons` | Regenerate app icons from `assets/icon/` |
| `flutter build web --release --dart-define=API_BASE_URL=...` | Web build |
| `flutter build windows --release --dart-define=API_BASE_URL=...` | Windows build |
| `flutter build apk --release --dart-define=API_BASE_URL=...` | Android APK |

## Layout

```
lib/
  main.dart, app.dart
  core/       config (env), network, error, theme, router, l10n, utils, widgets
  features/   one folder per feature: domain / data / presentation
assets/
  images/logo.png        the FlyAsh logo (static, used in the app and on receipts)
  icon/                  sources for the generated app icons
```
