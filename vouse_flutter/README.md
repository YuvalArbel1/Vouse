# Vouse Flutter Client

<div align="center">
  <img src="assets/images/vouse_app_logo.png" alt="Vouse Logo" width="150">
  <h3>A modern social media management app built with Flutter</h3>
</div>

## Overview

The Vouse Flutter client is a cross-platform mobile application that provides an intuitive interface for managing social media accounts. It connects to the Vouse backend server to provide seamless social media integration, AI-powered content creation, and analytics.

## Features

- **User Authentication**: Secure login with Firebase Authentication
- **Social Media Integration**: Connect and manage Twitter/X accounts
- **Content Creation**: Create and edit posts with AI assistance
- **Media Management**: Upload and manage images for posts
- **Post Scheduling**: Schedule posts for automated publishing
- **Analytics Dashboard**: Track engagement metrics
- **Location Features**: Location-based posting and discovery
- **Push Notifications**: Real-time updates on account activities

## Project Structure

The project follows a clean architecture approach with the following organization:

```
lib/
├── core/               # Core utilities and constants
├── data/               # Data layer (repositories, data sources)
├── domain/             # Domain layer (entities, use cases)
├── presentation/       # UI layer (screens, widgets, state management)
└── main.dart           # Application entry point
```

### Key Directories

- **core**: Contains common utilities, constants, and helper classes
- **data**: Implements data repositories and API clients
- **domain**: Contains business logic models and entities
- **presentation**: UI components organized by feature

## Technology Stack

- **Flutter SDK**: ^3.6.1
- **State Management**: flutter_riverpod ^2.6.1
- **Networking**: retrofit ^4.4.2, dio ^5.8.0+1
- **Authentication**: firebase_auth ^5.4.2, google_sign_in ^6.2.2
- **Database**: sqflite ^2.4.1 (for local storage)
- **Location Services**: google_maps_flutter ^2.10.0, geocoding ^3.0.0
- **AI Integration**: firebase_vertexai ^1.2.0
- **Storage**: firebase_storage ^12.4.3
- **Push Notifications**: firebase_messaging, flutter_local_notifications

## Getting Started

### Prerequisites

- Flutter SDK 3.6.1 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / VS Code
- Firebase project configured
- Google Maps API key

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/YuvalArbel1/Vouse.git
   cd Vouse/vouse_flutter
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Create a `.env` file (or use Firebase configuration):
   ```
   API_BASE_URL=your_api_url
   GOOGLE_MAPS_API_KEY=your_api_key
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## Architecture

The app follows the principles of Clean Architecture with Riverpod for state management:

### Layers

1. **Presentation Layer**:
   - Screens/Pages: UI components that display content
   - Widgets: Reusable UI components
   - Providers: Riverpod state management

2. **Domain Layer**:
   - Entities: Core business objects
   - Use Cases: Business logic operations

3. **Data Layer**:
   - Repositories: Abstract data operations
   - Data Sources: API clients and local storage

## Key Features Implementation

### Authentication Flow

The app uses Firebase Authentication with custom token integration for the backend. The authentication flow includes:

1. Firebase sign-in (Email, Google)
2. Token retrieval and validation
3. User profile setup and management

### Social Media Integration

Twitter/X integration is handled through:
1. OAuth authentication
2. API client implementation
3. Tweet composition and scheduling

### AI Content Generation

AI features leverage Firebase VertexAI:
1. Content suggestions
2. Hashtag recommendations
3. Post optimization

## Development Guidelines

### Code Style

- Follow the [Flutter style guide](https://flutter.dev/docs/development/tools/formatting)
- Use meaningful variable and function names
- Document public APIs with dartdoc comments

### State Management

- Use Riverpod providers for state management
- Separate UI logic from business logic
- Use immutable state objects

### Testing

Run tests with:
```bash
flutter test
```

## Building for Production

### Android

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios --release
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

All rights reserved. This project and its contents are proprietary.

---

For backend documentation, see the [vouse_server README](../vouse_server/README.md).
