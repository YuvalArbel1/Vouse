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
        this.logger.log(
          `Loading Firebase credentials from: ${this.config.serviceAccountPath}`,
        );

        // Check if the file exists
        if (!fs.existsSync(this.config.serviceAccountPath)) {
          this.logger.error(
            `Service account file not found at: ${this.config.serviceAccountPath}`,
          );
          throw new Error('Firebase service account file not found');
        }

        // Load the service account file
        const serviceAccount = JSON.parse(
          fs.readFileSync(this.config.serviceAccountPath, 'utf8'),
        ) as admin.ServiceAccount;

        // Initialize Firebase Admin with the service account
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
          projectId: this.config.projectId,
        });

        this.logger.log('Firebase Admin SDK initialized successfully');
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
