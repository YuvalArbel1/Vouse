# Vouse Server

<div align="center">
  <h1>Vouse Backend API</h1>
  <p>A modern NestJS backend for the Vouse social media management platform</p>
</div>

## Overview

The Vouse Server is a robust backend built with NestJS that powers the Vouse social media management platform. It provides RESTful APIs for user management, social media integration, post scheduling, analytics, and notifications.

## Features

- **Authentication**: Firebase-based authentication system
- **User Management**: Profile creation, management, and preferences
- **Social Media Integration**: Twitter/X API v2 integration
- **Post Management**: Creation, scheduling, and publishing of social media content
- **Queue Processing**: Background job processing with Bull and Redis
- **Database**: TypeORM integration with PostgreSQL
- **Push Notifications**: Firebase Cloud Messaging integration

## Technology Stack

- **Framework**: NestJS ^11.0.11
- **Runtime**: Node.js
- **Language**: TypeScript
- **Database**: PostgreSQL with TypeORM
- **Queue**: Bull with Redis
- **Authentication**: Firebase Admin SDK
- **Social Media**: Twitter API v2
- **Validation**: class-validator and class-transformer
- **Testing**: Jest

## Project Structure

```
src/
├── auth/                # Authentication module
├── common/              # Shared utilities and helpers
├── config/              # Application configuration
├── notifications/       # Push notification services
├── posts/               # Post management module
├── types/               # TypeScript type definitions
├── users/               # User management module
├── x/                   # Twitter API integration
├── app.module.ts        # Main application module
├── httpRequestMiddleware.ts # HTTP request logging
└── main.ts              # Application entry point
```

## Core Modules

### Auth Module

Handles user authentication using Firebase:
- Token validation
- User registration
- Session management

### Users Module

Manages user profiles and settings:
- Profile CRUD operations
- User preferences
- Social account connections

### Posts Module

Handles post creation, scheduling, and analytics:
- Post creation and editing
- Scheduling mechanism
- Engagement metrics

### X Module

Twitter API v2 integration:
- OAuth authentication
- Tweet management
- Twitter metrics

### Notifications Module

Push notification management:
- Firebase Cloud Messaging integration
- Notification templates
- Delivery tracking

## API Endpoints

### Authentication

- `POST /auth/login`: Authenticate a user
- `POST /auth/register`: Register a new user

### Users

- `GET /users/profile`: Get user profile
- `PUT /users/profile`: Update user profile
- `GET /users/me`: Get current user data

### Posts

- `GET /posts`: List user posts
- `POST /posts`: Create a new post
- `GET /posts/:id`: Get post details
- `PUT /posts/:id`: Update a post
- `DELETE /posts/:id`: Delete a post
- `POST /posts/:id/schedule`: Schedule a post
- `GET /posts/analytics`: Get post analytics

### X (Twitter)

- `POST /x/connect`: Connect Twitter account
- `GET /x/profile`: Get Twitter profile
- `POST /x/tweet`: Post a new tweet
- `GET /x/analytics`: Get Twitter engagement metrics

## Environment Configuration

The application requires the following environment variables:

```
# Server Configuration
PORT=3000
NODE_ENV=development

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=password
DB_DATABASE=vouse

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0

# Firebase Configuration
FIREBASE_PROJECT_ID=your-firebase-project
FIREBASE_PRIVATE_KEY=your-private-key
FIREBASE_CLIENT_EMAIL=your-client-email

# Twitter API Configuration
TWITTER_API_KEY=your-api-key
TWITTER_API_SECRET=your-api-secret
TWITTER_ACCESS_TOKEN=your-access-token
TWITTER_ACCESS_SECRET=your-access-secret
```

## Setup and Installation

### Prerequisites

- Node.js (v18+)
- npm or yarn
- PostgreSQL
- Redis

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/YuvalArbel1/Vouse.git
   cd Vouse/vouse_server
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Set up environment variables by creating a `.env` file (see Environment Configuration section)

4. Start the development server:
   ```bash
   npm run start:dev
   ```

### Database Setup

1. Create a PostgreSQL database:
   ```sql
   CREATE DATABASE vouse;
   ```

2. The ORM will handle schema creation when you start the application with the proper configuration.

## Running in Production

### Build the application:

```bash
npm run build
```

### Start in production mode:

```bash
npm run start:prod
```

### Using Docker (Recommended)

```bash
docker-compose up -d
```

## Testing

### Unit Tests

```bash
npm run test
```

### End-to-End Tests

```bash
npm run test:e2e
```

### Test Coverage

```bash
npm run test:cov
```

## Deployment

The application is designed to be deployed on:
- Docker containers
- Kubernetes clusters
- Cloud platforms (AWS, GCP, Azure)

## Development Guidelines

### Code Style

- Follow NestJS best practices
- Use meaningful variable and function names
- Document complex functions with JSDoc comments

### Architecture Principles

- Maintain a modular architecture
- Separate business logic from infrastructure
- Use dependency injection
- Write testable code

## Documentation

API documentation is available at `/api-docs` when running the server with Swagger enabled.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

All rights reserved. This project and its contents are proprietary.

---

For frontend documentation, see the [vouse_flutter README](../vouse_flutter/README.md).
