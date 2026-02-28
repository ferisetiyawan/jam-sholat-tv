# PrayTime TV (Jam Sholat Masjid)
A specialized Flutter application designed for Masjid display screens. This project helps congregations keep track of prayer times, announcements, and live streams from the Holy Mosque.

## 🚀 Quick Start (Onboarding)
This project uses FVM (Flutter Version Management) to ensure everyone is on the exact same Flutter version (3.41.1).

1. Prerequisites
If you haven't installed FVM yet, run:
```bash
dart pub global activate fvm
```
2. Setup SDK & Packages
Once you've cloned the repo, run these commands in order:
### Install the specific Flutter version defined in .fvmrc
```bash
fvm install
```
#### Link the project to the local SDK
```bash
fvm use
```

### Get all necessary packages
```bash
fvm flutter pub get
```

## 🛠 Running the App (Android Focus)
Since we are using FVM, always prefix your flutter commands with fvm.

Debugging
To run the app on your connected device or emulator in debug mode:
```bash
fvm flutter run
```
### Building for Production (Release)
When you're ready to deploy to the Masjid's Android TV or Tablet, generate the APK:
Build a universal APK
```bash
fvm flutter build apk --release
```
OR build App Bundle for Play Store
```bash
fvm flutter build appbundle
```
The output file will be located at: build/app/outputs/flutter-apk/app-release.apk

## ✨ Core Features
- Offline First: Automatically fetches and caches prayer data for the first 6 months to ensure reliability without constant internet.
- Live Makkah: Built-in integration for Makkah live streaming.
- Announcements: Digital signage board to display upcoming events with image support.
- More to come: Stay tuned for updates on themes and localized settings.

## 📂 Project Config
SDK Path: If you are using VS Code, it is already configured via .vscode/settings.json to point to .fvm/flutter_sdk.
Note: Please do not commit your local .fvm/flutter_sdk folder. It is already ignored in .gitignore.
