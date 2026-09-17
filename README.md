# Smart Irrigation

Android app + ESP32 firmware for a soil moisture / pH / tank / pump
system, synced through Firebase Realtime Database. No login, one screen.

## What's in here

```
lib/           Flutter app
android/       Android project
esp32/         ESP32 firmware (Arduino)
```

## 1. Firebase project

1. Create a project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add an Android app with package name `com.syem.eee.syem_eee`
3. Build → Realtime Database → Create Database
4. Rules tab → paste this and publish:
   ```json
   { "rules": { ".read": true, ".write": true } }
   ```
5. Data tab → import this JSON at the root:
   ```json
   {
     "moisture": 42,
     "ph": 6.5,
     "tank": "OK",
     "pump": { "status": "OFF", "command": "OFF" },
     "mode": "AUTO"
   }
   ```
6. Project Settings → General → your Android app → grab: API key, App ID,
   Sender ID, Project ID, Database URL, Storage bucket

## 2. App setup

```bash
cp .env.example .env
```

Fill `.env` with the values from step 1.6:

```
FIREBASE_API_KEY=
FIREBASE_APP_ID=
FIREBASE_MESSAGING_SENDER_ID=
FIREBASE_PROJECT_ID=
FIREBASE_DATABASE_URL=
FIREBASE_STORAGE_BUCKET=
```

Download `google-services.json` from Project Settings → your Android app,
save it as `android/app/google-services.json`.

```bash
flutter pub get
flutter run --dart-define-from-file=.env
```

Build a release APK:

```bash
flutter build apk --release --dart-define-from-file=.env
```

APK output: `build/app/outputs/flutter-apk/app-release.apk`

**Always pass `--dart-define-from-file=.env`** — without it the app has no
Firebase credentials and won't connect.

## 3. ESP32 setup

1. Arduino IDE → Library Manager → install **Firebase ESP Client** (mobizt)
2. ```bash
   cp esp32/smart_irrigation/secrets.h.example esp32/smart_irrigation/secrets.h
   ```
3. Fill `secrets.h`:
   ```
   WIFI_SSID / WIFI_PASSWORD     your network
   FIREBASE_API_KEY              same as .env
   FIREBASE_DATABASE_URL         same as .env
   ```
4. In `smart_irrigation.ino`, set `MOISTURE_PIN`, `PH_PIN`, `PUMP_RELAY_PIN`
   to match your wiring, and adjust the pH formula in `readPh()` for your
   sensor's calibration
5. Flash it

## How it talks

| Path           | Who writes it | Who reads it |
|----------------|----------------|--------------|
| `moisture`     | ESP32          | App          |
| `ph`           | ESP32          | App          |
| `tank`         | ESP32          | App          |
| `pump/status`  | ESP32          | App          |
| `pump/command` | App            | ESP32        |
| `mode`         | App            | ESP32        |

App buttons: **AUTO** sets `mode`, **ON**/**OFF** set `pump/command`.

## Notes

- `.env`, `google-services.json`, and `esp32/.../secrets.h` are gitignored
  — never commit real credentials.
- The database rules above are wide open (dev only). Tighten them before
  shipping anything real.
# sayem_eee
