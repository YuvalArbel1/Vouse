# Vouse Server 🚀

<div align="center">
  <img src="../vouse_flutter/assets/images/vouse_app_logo.png" alt="Vouse Logo" width="150"> 
  <br/>
  <strong>The robust NestJS backend powering the Vouse social media management platform.</strong>
  <br/>
  <br/>
  <!-- Badges -->
  <img src="https://img.shields.io/badge/framework-NestJS-red?style=for-the-badge&logo=nestjs" alt="NestJS">
  <img src="https://img.shields.io/badge/language-TypeScript-blue?style=for-the-badge&logo=typescript" alt="TypeScript">
  <img src="https://img.shields.io/badge/database-PostgreSQL-blue?style=for-the-badge&logo=postgresql" alt="PostgreSQL">
  <img src="https://img.shields.io/badge/queue-BullMQ-red?style=for-the-badge&logo=bull" alt="BullMQ">
  <img src="https://img.shields.io/badge/cache-Redis-red?style=for-the-badge&logo=redis" alt="Redis">
  <img src="https://img.shields.io/badge/auth-Firebase-orange?style=for-the-badge&logo=firebase" alt="Firebase">
  <img src="https://img.shields.io/badge/deployment-Neon-brightgreen?style=for-the-badge&logo=neon" alt="Neon DB">
  <img src="https://img.shields.io/badge/social-Twitter_API_v2-blue?style=for-the-badge&logo=twitter" alt="Twitter API v2">
  <!-- Add build status, license, etc. badges here if applicable -->
</div>

## ✨ Overview

Vouse Server provides the core API infrastructure for the Vouse platform, enabling users to connect their social media accounts (starting with Twitter/X), schedule posts, upload media, track engagement, and receive notifications. Built with NestJS, it follows a modular architecture and leverages modern technologies for scalability and reliability.

## 🚀 Key Features

*   🛡️ **Secure Authentication:** Firebase-based authentication ensuring secure user access.
*   🔗 **Twitter/X Integration:** Robust integration using Twitter API v2, including OAuth 2.0 with automatic token refresh.
*   ✍️ **Post Management:** Create, update, and delete posts with text, images, and location data.
*   ⏰ **Smart Scheduling:** Reliable post scheduling using BullMQ and Redis for background job processing.
*   📊 **Engagement Tracking:** Collects and stores detailed tweet metrics (likes, retweets, impressions) including hourly time-series data.
*   🔔 **Push Notifications:** Real-time updates via Firebase Cloud Messaging (FCM) when posts are published.
*   🔒 **Token Encryption:** Securely encrypts sensitive API tokens stored in the database.
*   🏗️ **Modular Architecture:** Cleanly organized codebase following NestJS best practices.
*   ☁️ **Cloud-Native Database:** Utilizes Neon serverless PostgreSQL for efficient data storage.

## 🛠️ Tech Stack

*   **Framework:** [NestJS](https://nestjs.com/)
*   **Language:** [TypeScript](https://www.typescriptlang.org/)
*   **Runtime:** [Node.js](https://nodejs.org/)
*   **Database:** [PostgreSQL](https://www.postgresql.org/) with [TypeORM](https://typeorm.io/)
*   **Database Hosting:** [Neon](https://neon.tech/) (Serverless Postgres)
*   **Queue System:** [BullMQ](https://bullmq.io/)
*   **Cache/Queue Broker:** [Redis](https://redis.io/)
*   **Authentication:** [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
*   **Cloud Storage:** [Firebase Storage](https://firebase.google.com/docs/storage) (Used by client, URLs consumed by server)
*   **Social Media API:** [Twitter API v2](https://developer.twitter.com/en/docs/twitter-api/early-access) & v1.1 (for media uploads)
*   **HTTP Client:** [Axios](https://axios-http.com/)
*   **Validation:** [class-validator](https://github.com/typestack/class-validator), [class-transformer](https://github.com/typestack/class-transformer)

## 🏛️ Architecture Overview

The server follows a standard NestJS modular architecture:

*   **Core Modules:** `Auth`, `Users`, `Posts`, `X` (Twitter), `Notifications`, `Common`.
*   **Database Interaction:** Uses TypeORM repositories to interact with the PostgreSQL database (hosted on Neon). Entities define the data structure (`User`, `Post`, `Engagement`, `DeviceToken`).
*   **Background Jobs:** BullMQ queues (`post-publish`, `metrics-collector`) backed by Redis handle asynchronous tasks like publishing scheduled posts and collecting metrics. Queue processors contain the business logic for these tasks.
*   **API Layer:** Controllers expose RESTful endpoints, protected by Guards (`FirebaseAuthGuard`). DTOs define the shape of request/response data.
*   **Configuration:** Uses `.env` files and dedicated config services (`typeorm.config`, `redis.config`, `twitter.config`).
*   **Security:** Firebase ID tokens are used for authentication. Sensitive tokens (e.g., Twitter refresh tokens) are encrypted before database storage.
*   **Image Handling:** Client uploads images to Firebase Storage; server receives and stores the URLs, then downloads images from these URLs when publishing to Twitter.

```mermaid
graph TD
    A[Flutter App] --> C;
    A --> S[Firebase Storage];

    subgraph Vouse API
        direction LR
        C{Controllers};
        C -- Uses --> D{Services};
        D -- Interacts --> E[TypeORM];
        D -- Interacts --> F[BullMQ];
        D -- Interacts --> G[Firebase Admin];
        D -- Interacts --> H[Twitter API Client];
        D -- Downloads From --> S;
    end

    E --> I[(PostgreSQL)];
    F --> J[(Redis)];
    G --> K[Firebase Auth];
    G --> L[FCM];
    H --> M[Twitter API];

    style I fill:#c55,stroke:#333,color:#000 
    style J fill:#c55,stroke:#333,color:#000 
    style K fill:#f80,stroke:#333,color:#000 
    style L fill:#f80,stroke:#333,color:#000 
    style M fill:#1DA1F2,stroke:#333,color:#000 
    style S fill:#f80,stroke:#333,color:#000 
```

```
src/
├── auth/           # Firebase Authentication (Guard, Service)
├── common/         # Shared utilities (Middleware, Encryption)
├── config/         # Environment/Service configurations
├── notifications/  # FCM Push Notifications (Service, Controller, Entity)
├── posts/          # Post Management & Scheduling (Service, Controller, Entity, Processor)
├── types/          # Shared TypeScript types
├── users/          # User Profile & Twitter Token Management (Service, Controller, Entity)
├── x/              # Twitter API Interaction (Client Service, Auth Service, Controller)
├── app.module.ts   # Root application module
└── main.ts         # Application entry point
```

## ⚙️ Getting Started

### Prerequisites

*   Node.js (v18+)
*   npm or yarn
*   PostgreSQL Instance (e.g., local or a Neon free tier)
*   Redis Instance
*   Firebase Project + Service Account Credentials
*   Twitter Developer App Credentials (API Key/Secret)

### Installation

1.  **Clone:** `git clone https://github.com/YuvalArbel1/Vouse.git && cd Vouse/vouse_server`
2.  **Install:** `npm install`
3.  **Configure:** Create a `.env` file based on the environment variables listed below. Ensure Firebase service account JSON and Twitter API keys are correctly set.
    ```env
    # Server
    PORT=3000
    NODE_ENV=development

    # Database (Neon Example - replace with your details)
    DATABASE_URL=postgresql://user:password@host/dbname?sslmode=require 

    # Redis
    REDIS_HOST=localhost
    REDIS_PORT=6379
    # REDIS_PASSWORD=
    # REDIS_TLS_ENABLED=false

    # Firebase (Use EITHER file path OR individual vars)
    # FIREBASE_SERVICE_ACCOUNT_PATH=./path/to/your-service-account.json
    FIREBASE_PROJECT_ID=your-firebase-project-id
    FIREBASE_CLIENT_EMAIL=your-service-account-email@project-id.iam.gserviceaccount.com
    FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\\nYOUR_KEY_HERE\\n-----END PRIVATE KEY-----\\n" # Ensure newlines are escaped as \\n

    # Twitter API v2 (Ensure your app has v2 access)
    TWITTER_API_KEY=your_consumer_key
    TWITTER_API_SECRET=your_consumer_secret
    # TWITTER_BEARER_TOKEN=your_bearer_token (Optional, might be needed for some endpoints)
    # Access Token/Secret are stored per user, not globally needed here

    # Encryption Key (Generate a secure 32-byte key using e.g., openssl rand -base64 32)
    ENCRYPTION_KEY=your_32_byte_random_encryption_key 
    ```
4.  **Run:** `npm run start:dev`

The server will start, and TypeORM will synchronize the database schema if `synchronize: true` is set in `typeorm.config.ts`.

## 📚 API Documentation (Swagger UI)

Interactive API documentation is available via Swagger UI at the deployed server URL:

[https://vouse.onrender.com/api-docs](https://vouse.onrender.com/api-docs)

This interface allows you to explore all available API endpoints, view their request/response schemas, and even test them directly from your browser against the live API.

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

➡️ Go to [Vouse Flutter Client README](../vouse_flutter/README.md)
