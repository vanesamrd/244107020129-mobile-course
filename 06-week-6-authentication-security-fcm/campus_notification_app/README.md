# Campus Notification App

A Flutter application for campus notifications, authentication, and Firebase Cloud Messaging (FCM) integration.

## Overview

This project is built for:
- campus announcement delivery
- secure authentication flow
- Firebase push notification support
- token refresh and session handling
- route-based notification navigation
- Android and iOS compatibility

## Tech Stack

- Flutter
- Dart
- Firebase Core
- Firebase Messaging
- Dio
- Flutter Secure Storage
- GoRouter / route management
- Flutter local notifications

## Project Structure

```text
campus_notification_app/
├── android/
├── ios/
├── lib/
│   ├── data/
│   ├── messaging/
│   ├── pages/
│   ├── providers/
│   ├── routes.dart
│   ├── main.dart
│   └── ...
├── test/
├── pubspec.yaml
├── analysis_options.yaml
├── README.md
└── ...
```

## Prerequisites

Before running this project, make sure you have:

- Flutter SDK installed
- Android Studio / Xcode installed as needed
- Firebase project configured
- Android SDK Platform 34 installed for newer Firebase Messaging compatibility
- A valid `google-services.json` for Android

## Required Android Setup

This app uses Firebase Messaging, which requires a newer compile SDK than older default Flutter projects.

In `android/app/build.gradle.kts`, make sure the app uses at least:

```kotlin
android {
    namespace = "com.example.campus_notify"
    compileSdk = 34
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.campus_notify"
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
}
```

Also ensure Android SDK Platform 34 is installed via Android Studio SDK Manager.

## Firebase Setup

1. Create a Firebase project.
2. Add Android app package ID.
3. Download `google-services.json` and place it in:
   - `android/app/google-services.json`
4. Add the Firebase plugin configuration in Gradle if needed.
5. Enable Cloud Messaging in Firebase Console.
6. Validate notification permissions for Android 13+.

## App Features

### Authentication
- login flow
- secure token storage
- session expiry handling
- refresh token strategy

### Push Notifications
- Firebase Messaging integration
- notification permission request
- foreground / background handling
- deep linking into routes
- announcement-based navigation

### Notification Flow
- app receives push payload
- route is extracted from message data
- notification opens the destination page
- users land on announcement/detail screen if route is valid

## Local Development

Run the app using:

```bash
flutter pub get
flutter run
```

Optional emulator target:

```bash
flutter run -d emulator-5554
```

## Common Notes

- Firebase Messaging may fail to build if Android compile SDK is too low.
- Android 13+ requires POST_NOTIFICATIONS permission handling.
- If token refresh fails, app should force re-login and clear the session.
- Use secure storage for access/refresh tokens, not plain shared preferences.

## Troubleshooting

### Build fails with Firebase AAR metadata error

Symptoms:
- `firebase_messaging:checkDebugAarMetadata` fails
- dependency requires compileSdk 34+

Fix:
- update `compileSdk` to 34
- install Android SDK Platform 34
- run `flutter clean` and `flutter pub get`

### Notification permission issue on Android 13+

Use runtime permission request logic before showing notification UI or handling messaging.

### Token expired / 401 issue

Ensure the app:
- catches `401 Unauthorized`
- refreshes token once
- clears session and redirects to login if refresh fails

## Notes

This project is intended as a campus notification app with secure auth and push delivery support. It is suitable for learning, prototype development, and further extension with backend APIs.

## License

This project is for educational and development use unless otherwise specified by the project owner.
