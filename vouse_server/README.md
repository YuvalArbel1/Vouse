# Vouse Server

A NestJS backend server for managing social media posts, metrics collection, and user authentication.

## Project Architecture

The application is structured as a modular NestJS application with the following components:

```
src/
├── auth/                  # Firebase authentication
├── common/                # Shared utilities and middleware
├── config/                # App configuration
├── notifications/         # Push notifications service
├── posts/                 # Post management and metrics
├── users/                 # User profile management
└── x/                     # Twitter API integration
```

### Core Modules

- **Auth Module**: Firebase authentication integration with guards and decorators
- **Common Module**: Shared utilities, middleware, and types
- **Users Module**: User profile management and connections
- **Posts Module**: Social media post scheduling and metrics tracking
- **Notifications Module**: Push notification service
- **X Module**: Twitter API v2 integration for posting and metrics collection

## Getting Started

### Prerequisites

- Node.js (v16+)
- PostgreSQL
- Redis (for queues and caching)
- Firebase project (for authentication)

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd vouse-server
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Configure environment variables in the existing `.env` file

5. Start the development server:
   ```bash
   npm run start:dev
   ```

## Recent Improvements

### Type Safety Enhancements

- Enabled TypeScript strict mode with proper type checking
- Added comprehensive type definitions for API responses
- Implemented type guards for safe type checking
- Enhanced error handling with proper typing

### Security Improvements

- Updated Firebase authentication with proper environment validation
- Enhanced token validation with claims verification
- Added AES-256-GCM encryption for sensitive data
- Implemented secure request logging with PII redaction

### Architecture Refinements

- Created a Common module for shared functionality
- Improved middleware organization
- Enhanced error handling patterns
- Added graceful shutdown handling

## Code Quality Tools

- **ESLint**: Enhanced typescript-eslint configuration
- **TypeScript**: Strict mode enabled
- **Helper Scripts**: Added utilities for type improvement

## Development Scripts

- `npm run start:dev`: Start development server with hot-reload
- `npm run lint`: Run ESLint checks
- `npm run test`: Run Jest tests
- `./scripts/update-typings.sh`: Identify and fix typing issues

## Ongoing Improvements

The following areas require further attention:

1. **Type Safety**: Replace remaining `any` types with proper interfaces
2. **API Documentation**: Add OpenAPI/Swagger documentation
3. **Error Handling**: Implement global exception filters
4. **Testing**: Increase unit and integration test coverage
5. **Performance**: Add response caching where appropriate

## Troubleshooting

If you encounter TypeScript errors after upgrading to strict mode:

1. Run the update-typings script:
   ```bash
   ./scripts/update-typings.sh
   ```

2. Address the most common issues:
   - Replace `any` types with specific interfaces from `common/types`
   - Add proper return types to all controller methods
   - Fix template literal expressions with proper type assertions
   - Use `asApiError` utility for error handling
   - Fix promise handling with proper async/await or void operator

## License

UNLICENSED
