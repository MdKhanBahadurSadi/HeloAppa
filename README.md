# HeloAppa

A well-structured Flutter application for Real-time Messaging and WebRTC Video/Audio Calling.

## Features
- **Authentication:** Firebase Auth integration.
- **Messaging:** Real-time chat using Cloud Firestore.
- **Calling:** WebRTC-based Video and Audio calls.
- **Notifications:** FCM (Firebase Cloud Messaging) for incoming call alerts.
- **UI:** Modern and clean UI with support for themes.

## Tech Stack
- **Framework:** Flutter
- **State Management:** BLoC / Cubit
- **Backend:** Firebase (Auth, Firestore, Messaging, Storage)
- **Networking:** Dio, WebRTC
- **Local Storage:** Hive

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Firebase Project setup

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/mdkhanbahadursadi/heloappa.git
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Add your `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS) to the respective directories.
4. Run the app:
   ```bash
   flutter run
   ```

## Project Structure
- `lib/core`: Common utilities, constants, themes, and shared services.
- `lib/features`: Feature-based modules (Auth, Chat, Call, etc.).
- `lib/di`: Dependency injection setup.
- `lib/router`: App routing configuration.

## Security Note
The project uses FCM HTTP v1 API. For production, ensure that the message sending logic is moved to a backend (like Firebase Cloud Functions) to protect your service account credentials.
