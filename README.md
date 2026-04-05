# Meeting Room Booking App

A Flutter application for booking meeting rooms, backed by Firebase Realtime Database.

---

## Tech Stack

- **Flutter** 3.41.6 / Dart 3.11+
- **Firebase Realtime Database** — data storage
- **Riverpod** (code generation) — state management
- **go_router** — navigation
- **Freezed** — immutable models
- **build_runner** — code generation

---

## Prerequisites

- Flutter SDK 3.41.6+ installed and in your `PATH`
- Node.js + npm (for Firebase CLI)
- A Firebase project created at [console.firebase.google.com](https://console.firebase.google.com)

---

## 1. Create the Flutter App

Run from the **parent folder** (e.g. `~/Desktop`), not inside the repo:

```bash
cd ~/Desktop
flutter create meeting_room_booking_app --org com.yourname --platforms ios,android
```

> Replace `com.yourname` with your own identifier (e.g. `com.acme`).

---

## 2. Install Dependencies

```bash
cd meeting_room_booking_app
```

Runtime dependencies:

```bash
flutter pub add \
  firebase_core \
  firebase_database \
  flutter_riverpod \
  riverpod_annotation \
  go_router \
  freezed_annotation \
  json_annotation
```

Dev dependencies (code generators):

```bash
flutter pub add --dev \
  build_runner \
  freezed \
  riverpod_generator \
  json_serializable
```

> **Note:** `riverpod_lint` and `custom_lint` are currently incompatible with
> `flutter_riverpod >=3.2.1` + `freezed_annotation ^3.x`. They can be added
> once the package authors release a compatible version.

---

## 3. Set Up Firebase

### Install CLIs

```bash
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
```

### Configure Firebase for Flutter

Run inside the project folder:

```bash
flutterfire configure
```

This registers your app on Android/iOS and generates `lib/firebase_options.dart`.

---

## 4. Initialize Firebase in the App

In `lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}
```

> `ProviderScope` must wrap the entire app for Riverpod to work.

---

## 5. Code Generation

Run once after adding/modifying `@freezed` models or `@riverpod` providers:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Or use the watcher during development (auto-runs on save):

```bash
dart run build_runner watch --delete-conflicting-outputs
```

---

## 6. Run the App

```bash
flutter pub get
flutter run
```

---

## CI/CD (GitHub Actions)

Two workflows live in `.github/workflows/`:

| File | Trigger | What it does |
|---|---|---|
| `ci.yml` | Every PR + push to `main` | Analyze, test, upload coverage |
| `cd.yml` | Push to `main` | Build signed Android AAB + iOS IPA, distribute via Firebase App Distribution |

### Required GitHub Secrets

Go to **Settings → Secrets and variables → Actions** in your GitHub repo and add:

#### Shared
| Secret | How to get it |
|---|---|
| `FIREBASE_APP_ID_ANDROID` | Firebase console → Project settings → Your Android app → App ID |
| `FIREBASE_APP_ID_IOS` | Firebase console → Project settings → Your iOS app → App ID |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | GCP console → IAM → Service Accounts → create key (JSON), paste full content |

#### Android signing
| Secret | How to get it |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -i your-key.jks \| pbcopy` |
| `ANDROID_STORE_PASSWORD` | Password used when creating the keystore |
| `ANDROID_KEY_PASSWORD` | Key password (often same as store password) |
| `ANDROID_KEY_ALIAS` | Alias used when creating the keystore |

Generate a keystore if you don't have one:
```bash
keytool -genkey -v -keystore release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Also update `android/app/build.gradle.kts` to read `key.properties`:
```kotlin
val keystoreProperties = Properties().apply {
    load(rootProject.file("key.properties").inputStream())
}

android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    buildTypes {
        release { signingConfig = signingConfigs.getByName("release") }
    }
}
```

#### iOS signing
| Secret | How to get it |
|---|---|
| `IOS_P12_BASE64` | Export your distribution certificate as `.p12`, then `base64 -i cert.p12 \| pbcopy` |
| `IOS_P12_PASSWORD` | Password set during `.p12` export |
| `IOS_PROVISIONING_PROFILE_BASE64` | Download `.mobileprovision` from Apple Developer portal, then `base64 -i profile.mobileprovision \| pbcopy` |
| `IOS_KEYCHAIN_PASSWORD` | Any strong random string (used only in CI) |

Also create `ios/ExportOptions.plist` (committed to the repo):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>ad-hoc</string>
  <key>teamID</key>
  <string>YOUR_TEAM_ID</string>
</dict>
</plist>
```

### Firebase App Distribution setup

In the Firebase console, go to **App Distribution** and create a tester group named `testers`.
Invite testers by email. They will receive install links automatically after each successful CD run.

---

## Troubleshooting

### Android Emulator frozen (not responding to clicks)

The emulator can freeze and stop handling input. Kill it and cold boot:

```bash
# Kill the frozen emulator
adb -s emulator-5554 emu kill

# Cold boot (skips saved snapshot that caused the freeze)
~/Library/Android/sdk/emulator/emulator -avd Pixel_8_Pro_API_35 -no-snapshot-load &
```

Wait ~30 seconds for it to fully boot, then run `flutter run` again.

> If you see multiple devices with `adb devices`, replace `emulator-5554` with the correct ID.

---

## Project Structure

```
lib/
  features/
    booking/
      data/           # repositories, data sources, models
      domain/         # entities, use cases, repository interfaces
      presentation/   # screens, widgets, providers
  shared/
    widgets/          # reusable UI components
    theme/
    utils/
  firebase_options.dart
  main.dart
```
