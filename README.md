# BulletinBeacon

A lightweight, dedicated iOS/Android application designed with a single focus:
1. **Automated Daily Check & Notifications**: Checks everyday for new monthly Visa Bulletin releases from the U.S. Department of State. When a new bulletin is issued, gives an instant notification highlighting dates moved for your category and others.
2. **Prominent "Your Category" Top Card**: Displays the user's selected category (e.g. EB-2 India) in a prominent separate card at the top, showing the current cutoff date, previous cutoff date, and clear movement indicators (e.g., `Advanced +3 months (+92 days)`, `Retrogressed`, `Became Current`, or `No change`).
3. **Dedicated "Other Categories" Card**: Displays all other categories together in a separate card with movement badges and past vs current dates.
4. **Instant Category Switching**: Tap "Change" on the top card or tap any category in the list to select it as your primary category.
5. **No Account Required**: Category, chargeability area, and preferences are stored 100% locally on the device with zero logins, tracking, or ads.

---

## Project Structure

- `lib/` — Root Flutter application entry point ([main.dart](file:///Users/warlord/Downloads/visa_bulletin_lite/lib/main.dart)).
- `app/` — Standalone Flutter application package (synchronized with root).
- `assets/` — Bundled sample bulletin data ([sample_bulletin.json](file:///Users/warlord/Downloads/visa_bulletin_lite/assets/sample_bulletin.json)).
- `backend/` — Serverless Azure Function (Python) parser + optional Firebase notification sender ([function_app.py](file:///Users/warlord/Downloads/visa_bulletin_lite/backend/function_app.py)).
- `.github/workflows/` — Automated build pipelines for Android APK and iOS.

---

## Running the App Locally

Ensure Flutter (stable) is installed, then run from the root directory:

```bash
flutter pub get
flutter run
```

With no build-time URL specified, the app opens with the bundled sample bulletin data, which is ideal for offline testing and visual validation.

### Using a Custom Bulletin Feed URL
```bash
flutter run --dart-define=BULLETIN_URL=https://YOUR_STORAGE_ACCOUNT.blob.core.windows.net/public/current.json
```

---

## Daily Checking & Notification System

- **Everyday Check**: The app automatically checks for fresh bulletins on launch and resume, recording the last checked timestamp.
- **Local Notifications**: Uses `flutter_local_notifications` to alert the user immediately whenever a new bulletin month is detected, showing date movements. A test notification button is built right into the app bar.
- **Firebase Cloud Messaging (Optional)**: If you provide Firebase credentials via `--dart-define`, the app also subscribes to the `visa-bulletin` topic:
  ```bash
  flutter run \
    --dart-define=FIREBASE_API_KEY=... \
    --dart-define=FIREBASE_APP_ID=... \
    --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
    --dart-define=FIREBASE_PROJECT_ID=...
  ```

---

## Building Release Binaries

### Android APK
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### iOS Release
```bash
flutter build ios --release
```
Open `ios/Runner.xcworkspace` in Xcode, select your Signing Team, and archive for distribution.

---

## Testing

Run unit and parsing tests:
```bash
flutter test
```
