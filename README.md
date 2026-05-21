# HeloAppa - Modern Real-time Chat & Video Call App

HeloAppa is a professional, high-performance real-time communication application built with Flutter. It features instant messaging, high-quality video/audio calling using WebRTC, and real-time user presence tracking, all wrapped in a clean architecture.

## 🚀 Key Features

- **Real-time Messaging:** Instant chat with message status (delivered, seen).
- **High-Quality Calls:** Seamless Video and Audio calling powered by WebRTC and Firebase.
- **Push Notifications:** Stay updated with FCM (Firebase Cloud Messaging) and CallKit integration for incoming calls.
- **User Presence:** Real-time online/offline status and "last seen" tracking.
- **Modern UI/UX:** Clean, intuitive design with support for both Dark and Light modes.
- **Secure Authentication:** Social login (Google) and Email/Password authentication via Firebase.
- **Mock Mode:** Built-in capability to run the app with dummy data for testing without backend dependencies.

## 🏗️ Architecture

The project follows **Clean Architecture** principles with a **Feature-first approach**:

- **Presentation Layer:** Managed using the **BLoC (Business Logic Component)** pattern for predictable state management.
- **Domain Layer:** Contains business logic, entities, and repository interfaces (completely platform-independent).
- **Data Layer:** Implements repositories, data sources (Firebase, Hive, WebRTC), and models.
- **Dependency Injection:** Handled by `GetIt` for efficient service management and testability.

## 🛠️ Tech Stack

- **Framework:** [Flutter](https://flutter.dev/)
- **State Management:** [flutter_bloc](https://pub.dev/packages/flutter_bloc)
- **Backend/Database:** [Firebase](https://firebase.google.com/) (Firestore, Auth, Messaging, Storage)
- **Local Storage:** [Hive](https://pub.dev/packages/hive)
- **Real-time Communication:** [WebRTC](https://webrtc.org/)
- **Dependency Injection:** [GetIt](https://pub.dev/packages/get_it)
- **Navigation:** [GoRouter](https://pub.dev/packages/go_router)

## 📦 Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Firebase Account
- Google Cloud Project (for Google Sign-In)

### Installation
1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/heloappa.git
    cd heloappa
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Configure Firebase:**
    - Create a Firebase project.
    - Add Android and iOS apps.
    - Download and place `google-services.json` in `android/app/` and `GoogleService-Info.plist` in `ios/Runner/`.
4.  **Run the app:**
    ```bash
    flutter run
    ```

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
