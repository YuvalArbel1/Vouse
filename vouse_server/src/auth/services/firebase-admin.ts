// src/auth/services/firebase-admin.ts
import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import * as admin from 'firebase-admin';
import * as path from 'path';
import * as fs from 'fs';
import * as dotenv from 'dotenv';

interface FirebaseConfig {
  serviceAccountPath: string;
  projectId?: string;
}

@Injectable()
export class FirebaseAdminService implements OnModuleInit {
  private readonly logger = new Logger(FirebaseAdminService.name);
  private readonly config: FirebaseConfig;

  constructor() {
    // Ensure environment variables are loaded
    dotenv.config();

    // Get configuration from environment variables or use default path
    this.config = this.validateConfig({
      serviceAccountPath:
        process.env.FIREBASE_SERVICE_ACCOUNT_PATH ||
        path.join(
          process.cwd(),
          'vouse-4d2c0-firebase-adminsdk-fbsvc-0ae3a7c438.json',
        ),
      projectId: process.env.FIREBASE_PROJECT_ID,
    });
  }

  /**
   * Validate the Firebase configuration
   *
   * @param config - The Firebase configuration object
   * @returns The validated configuration
   * @throws Error if configuration is invalid
   */
  private validateConfig(config: FirebaseConfig): FirebaseConfig {
    if (!config.serviceAccountPath) {
      throw new Error('Firebase service account path is required');
    }

    return config;
  }

  /**
   * Initialize Firebase Admin SDK when the module is initialized
   */
  onModuleInit(): void {
    // Check if Firebase is already initialized to prevent multiple initializations
    if (!admin.apps.length) {
      try {
        // Check if we have environment variables for Firebase
        if (
          process.env.FIREBASE_PRIVATE_KEY &&
          process.env.FIREBASE_CLIENT_EMAIL &&
          process.env.FIREBASE_PROJECT_ID
        ) {
          this.logger.log(
            'Initializing Firebase Admin SDK using environment variables',
          );

          // Initialize Firebase Admin with environment variables
          admin.initializeApp({
            credential: admin.credential.cert({
              projectId: process.env.FIREBASE_PROJECT_ID,
              clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
              // The private key comes as a string with "\n" characters
              // We need to replace them with actual newlines
              privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(
                /\\n/g,
                '\n',
              ),
            }),
          });

          this.logger.log(
            'Firebase Admin SDK initialized successfully with environment variables',
          );
        }
        // Fallback to file-based initialization if service account path is provided
        else if (
          this.config.serviceAccountPath &&
          fs.existsSync(this.config.serviceAccountPath)
        ) {
          this.logger.log(
            `Loading Firebase credentials from: ${this.config.serviceAccountPath}`,
          );

          // Load the service account file
          const serviceAccount = JSON.parse(
            fs.readFileSync(this.config.serviceAccountPath, 'utf8'),
          ) as admin.ServiceAccount;

          // Initialize Firebase Admin with the service account
          admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
            projectId: this.config.projectId,
          });

          this.logger.log(
            'Firebase Admin SDK initialized successfully with service account file',
          );
        } else {
          throw new Error(
            'Firebase credentials not found in environment variables or service account file',
          );
        }
      } catch (error) {
        const typedError = error as Error;
        this.logger.error(
          'Failed to initialize Firebase Admin SDK',
          typedError.stack,
        );
        throw error;
      }
    }
  }

  /**
   * Verify a Firebase ID token
   *
   * @param token The token to verify
   * @returns The decoded token if valid
   * @throws Error if token verification fails
   */
  async verifyIdToken(token: string): Promise<admin.auth.DecodedIdToken> {
    try {
      return await admin.auth().verifyIdToken(token);
    } catch (error) {
      const typedError = error as Error;
      this.logger.error(
        `Error verifying token: ${typedError.message}`,
        typedError.stack,
      );
      throw error;
    }
  }

  /**
   * Get a user by their Firebase UID
   *
   * @param uid The user's UID
   * @returns The user record
   * @throws Error if user retrieval fails
   */
  async getUser(uid: string): Promise<admin.auth.UserRecord> {
    try {
      return await admin.auth().getUser(uid);
    } catch (error) {
      const typedError = error as Error;
      this.logger.error(
        `Error getting user ${uid}: ${typedError.message}`,
        typedError.stack,
      );
      throw error;
    }
  }
}
