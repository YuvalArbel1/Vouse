# Vouse Flutter Client 📱

<div align="center">
  <img src="https://raw.githubusercontent.com/YuvalArbel1/Vouse/main/vouse_flutter/assets/images/vouse_app_logo.png" alt="Vouse Logo" width="150"> 
  <br/>
  <strong>A modern, cross-platform social media management app built with Flutter.</strong>
  <br/>
  <br/>
  <!-- Badges -->
  <img src="https://img.shields.io/badge/framework-Flutter-blue?style=for-the-badge&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/language-Dart-blue?style=for-the-badge&logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/state-Riverpod-purple?style=for-the-badge&logo=riverpod" alt="Riverpod">
  <img src="https://img.shields.io/badge/auth-Firebase-orange?style=for-the-badge&logo=firebase" alt="Firebase">
  <img src="https://img.shields.io/badge/API Client-Retrofit-brightgreen?style=for-the-badge" alt="Retrofit">
  <!-- Add build status, license, etc. badges here if applicable -->
</div>

## ✨ Overview

The Vouse Flutter client provides an intuitive and seamless experience for managing social media accounts on the go. Built using Flutter for cross-platform compatibility (Android & iOS), it connects securely to the Vouse backend API to offer features like post scheduling, media management, engagement tracking, and AI-assisted content creation.

## 🚀 Key Features

*   🔒 **Secure Authentication:** Smooth login/signup flow using Firebase Authentication (Email, Google Sign-In) integrated with the Vouse backend.
*   📱 **Cross-Platform:** Single codebase for both Android and iOS using Flutter.
*   ✍️ **Post Creation & Scheduling:** Compose posts with text, images, and location tags. Schedule them for automatic publishing via the Vouse server.
*   🖼️ **Media Handling:** Select and preview images for your posts.
*   📊 **Engagement Tracking:** View performance metrics for your published posts.
*   🔔 **Push Notifications:** Receive real-time updates about your account and published posts via FCM.
*   🗺️ **Location Services:** Tag posts with location data using Google Maps integration.
*   🤖 **AI Assistance (via Backend):** Leverage backend AI features for content suggestions (details implemented server-side).
*   🏛️ **Clean Architecture:** Organized codebase following clean architecture principles for maintainability and testability.
*   💡 **State Management:** Efficient and scalable state management using Riverpod.

## 📸 Screenshots / Demo

*(Placeholders - Replace with actual screenshots or GIFs)*

| Login Screen                                     | Home Dashboard                                   | Post Creation                                      |
| :-----------------------------------------------: | :----------------------------------------------: | :------------------------------------------------: |
| ![Login Screen](placeholder_login.png)           | ![Home Screen](placeholder_home.png)             | ![Post Creation](placeholder_create.gif)           |
| **Post History**                                 | **Engagement View**                              | **Profile/Settings**                             |
| ![Post History Screen](placeholder_history.png) | ![Engagement Screen](placeholder_engagement.png) | ![Profile Screen](placeholder_profile.png)         |

## 🛠️ Tech Stack

*   **Framework:** [Flutter](https://flutter.dev/)
*   **Language:** [Dart](https://dart.dev/)
*   **State Management:** [Riverpod](https://riverpod.dev/)
*   **API Client:** [Retrofit](https://pub.dev/packages/retrofit) / [Dio](https://pub.dev/packages/dio)
*   **Authentication:** [Firebase Auth](https://pub.dev/packages/firebase_auth), [Google Sign-In](https://pub.dev/packages/google_sign_in), [Flutter AppAuth](https://pub.dev/packages/flutter_appauth) (for Twitter OAuth flow)
*   **Local Storage:** [SQFlite](https://pub.dev/packages/sqflite)
*   **Secure Storage:** [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage)
*   **Cloud Storage:** [Firebase Storage](https://pub.dev/packages/firebase_storage)
*   **Mapping/Location:** [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter), [Geocoding](https://pub.dev/packages/geocoding), [Location](https://pub.dev/packages/location)
*   **Push Notifications:** [Firebase Messaging](https://pub.dev/packages/firebase_messaging), [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
*   **Image Handling:** [Image Picker](https://pub.dev/packages/image_picker), [Photo Manager](https://pub.dev/packages/photo_manager)
*   **Utilities:** [intl](https://pub.dev/packages/intl), [path_provider](https://pub.dev/packages/path_provider), [Logger](https://pub.dev/packages/logger), [nb_utils](https://pub.dev/packages/nb_utils)

## 🏛️ Architecture Overview

The app follows Clean Architecture principles, separating concerns into distinct layers:

*   **Presentation Layer:** Contains UI elements (Screens, Widgets), state management (Riverpod Providers), and navigation logic.
*   **Domain Layer:** Defines core business logic, including Entities (business objects), Use Cases (specific operations like `SchedulePostUseCase`), and Repository interfaces (contracts for data access).
*   **Data Layer:** Implements the Repository interfaces, interacting with data sources like the Vouse backend API (via Retrofit `ServerApiClient`), local SQLite database (`LocalDbRepository`), Firebase services (Auth, Storage), and secure storage. Uses `DataState` to handle operation outcomes.
*   **Core Layer:** Provides shared utilities, configuration (`AppSecrets`), base classes (`UseCase`), and resources used across layers.

```
lib/
├── core/          # Shared utilities, config, base usecase
├── data/          # Repository implementations, API clients, data models, data sources
├── domain/        # Core business logic: Entities, Repository interfaces, Use Cases
├── presentation/  # UI: Screens, Widgets, Riverpod Providers, Theme, Navigation
└── main.dart      # App entry point & initialization
```

## ⚙️ Getting Started

### Prerequisites

*   Flutter SDK (check `pubspec.yaml` for specific version)
*   Dart SDK
*   Android Studio / VS Code with Flutter plugins
*   Firebase project configured (Auth, Storage, FCM)
*   Google Maps API Key (configured in `lib/core/config/app_secrets.dart`)
*   Vouse Server running and accessible

### Installation

1.  **Clone:** `git clone https://github.com/YuvalArbel1/Vouse.git && cd Vouse/vouse_flutter`
2.  **Install:** `flutter pub get`
3.  **Configure:**
   *   Ensure your Firebase project's `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are correctly placed.
   *   Update API keys in `lib/core/config/app_secrets.dart` if necessary.
   *   Ensure the Vouse Server API base URL is correctly configured (likely within the Dio setup in the data layer).
4.  **Run:** `flutter run`

## 🙏 Contributing

Contributions are welcome! Please follow standard fork-and-pull-request workflow.

1.  Fork the repository.
2.  Create your feature branch (`git checkout -b feature/amazing-feature`).
3.  Commit your changes (`git commit -m 'Add some amazing feature'`).
4.  Push to the branch (`git push origin feature/amazing-feature`).
5.  Open a Pull Request.

## 📄 License

All rights reserved. This project and its contents are proprietary.

---

⬅️ Go to [Vouse Server README](../vouse_server/README.md)
