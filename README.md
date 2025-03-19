# Vouse - Social Media Management Platform

<div align="center">
  <img src="vouse_flutter/assets/images/vouse_app_logo.png" alt="Vouse Logo" width="200">
  <h3>Manage your social presence with AI-powered simplicity</h3>
</div>

## About Vouse

Vouse is an integrated social media management platform that helps users streamline their content creation and publication across multiple social networks. Built with a modern tech stack, Vouse provides an intuitive mobile interface through Flutter and a robust backend using NestJS.

### Key Features

- **Cross-Platform Social Media Integration**: Seamlessly manage content across Twitter/X
- **AI-Assisted Content Creation**: Leverage Firebase VertexAI for smart content generation
- **Scheduled Posting**: Plan and schedule your social media content in advance
- **Analytics Dashboard**: Track engagement and performance metrics
- **Notification System**: Stay updated with real-time alerts
- **Location-Based Content**: Create and share location-tagged posts

## Repository Structure

This repository is organized into two main components:

1. **[vouse_flutter](vouse_flutter/)** - The mobile client application built with Flutter
2. **[vouse_server](vouse_server/)** - The backend server built with NestJS

## Tech Stack

### Frontend (Flutter)
- Flutter SDK
- Riverpod for state management
- Firebase Authentication
- Google Maps integration
- Retrofit for API communication

### Backend (NestJS)
- NestJS framework
- TypeORM for database operations
- PostgreSQL database
- Redis for caching
- Bull for queue processing
- Firebase Admin SDK

## Getting Started

For detailed installation and setup instructions, please refer to the individual READMEs:

- [Flutter Client Setup Guide](vouse_flutter/README.md)
- [Backend Server Setup Guide](vouse_server/README.md)

## Architecture

Vouse follows a clean architecture pattern with separation of concerns:

- **Frontend**: Feature-based organization with Riverpod for state management
- **Backend**: Modular architecture with domain-specific modules

## License

All rights reserved. This project and its contents are protected under copyright law.

## Contact

For any inquiries about Vouse, please reach out through GitHub issues.
