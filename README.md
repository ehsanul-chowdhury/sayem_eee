# Smart Irrigation

Android app for an IoT soil-moisture / pH / tank / pump monitoring and
control system. Single screen, no login, backed by Firebase Realtime
Database.

## Stack

- Flutter + Dart
- Firebase Realtime Database (`firebase_core`, `firebase_database`)
- No auth, no local storage, no extra screens

## Firebase data structure

```
moisture        number   (%)
ph              number
tank            string   "OK" | "LOW"
pump/status     string   "ON" | "OFF"   — set by the microcontroller
pump/command    string   "ON" | "OFF"   — set by the app
mode            string   "AUTO" | "MANUAL"
```

The app only ever writes `mode` and `pump/command`. Everything else
(`moisture`, `ph`, `tank`, `pump/status`) is written by the microcontroller
and read live by the app.

## Project setup

### 1. Credentials

Firebase config is not committed to this repo. Copy the template and fill
it in with your Firebase project's values (Firebase Console → Project
Settings → General → your Android app):

```bash
cp .env.example .env
```

```
FIREBASE_API_KEY=
FIREBASE_APP_ID=
FIREBASE_MESSAGING_SENDER_ID=
FIREBASE_PROJECT_ID=
FIREBASE_DATABASE_URL=
FIREBASE_STORAGE_BUCKET=
```

Also copy the Android Gradle config template and fill it the same way, or
download the real file from the Firebase Console (Project Settings →
your Android app → `google-services.json`):

```bash
cp android/app/google-services.json.example android/app/google-services.json
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run

Credentials are injected at build/run time via `--dart-define-from-file`,
so always pass the `.env` file:

```bash
flutter run --dart-define-from-file=.env
```

### 4. Build a release APK

```bash
flutter build apk --release --dart-define-from-file=.env
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

## Firebase project setup (one-time)

1. Create a Firebase project and add an Android app with package name
   `com.syem.eee.syem_eee`.
2. Enable **Realtime Database** (Build → Realtime Database → Create
   Database).
3. Seed initial data at the database root:
   ```json
   {
     "moisture": 42,
     "ph": 6.5,
     "tank": "OK",
     "pump": { "status": "OFF", "command": "OFF" },
     "mode": "AUTO"
   }
   ```
4. Set database rules for development (tighten before production):
   ```json
   {
     "rules": {
       ".read": true,
       ".write": true
     }
   }
   ```

## Microcontroller (ESP32) firmware

Firmware lives in [`esp32/smart_irrigation/`](esp32/smart_irrigation/).

- Reads soil moisture (analog pin 34) and pH (analog pin 35), publishes
  them plus tank status to `moisture`, `ph`, `tank`.
- Drives a relay (pin 26) for the pump and reports its real state to
  `pump/status`.
- Reads `mode`: runs its own auto-irrigation logic (moisture below
  threshold → pump on) when `mode == "AUTO"`, otherwise obeys whatever
  the app last wrote to `pump/command`.

### Setup

1. Arduino IDE → Library Manager → install **Firebase ESP Client**
   (by mobizt).
2. Copy the credentials template and fill it in:
   ```bash
   cp esp32/smart_irrigation/secrets.h.example esp32/smart_irrigation/secrets.h
   ```
   ```
   WIFI_SSID, WIFI_PASSWORD           — your network
   FIREBASE_API_KEY                   — same value as .env's FIREBASE_API_KEY
   FIREBASE_DATABASE_URL              — same value as .env's FIREBASE_DATABASE_URL
   ```
3. Adjust `MOISTURE_PIN`, `PH_PIN`, `PUMP_RELAY_PIN`, and the pH
   calibration formula in `readPh()` to match your actual sensors.
4. Flash `smart_irrigation.ino` to the board.

`secrets.h` is gitignored — never commit it.

## Project structure

```
lib/
  main.dart              app UI + Firebase read/write logic (single screen)
  firebase_options.dart  reads Firebase config from --dart-define values
android/                 standard Flutter Android project
esp32/smart_irrigation/  ESP32 firmware (Arduino sketch)
.env.example             app credential template (commit this)
.env                     real app credentials (gitignored, not committed)
```
