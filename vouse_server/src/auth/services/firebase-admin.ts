// src/auth/services/firebase-admin.ts
import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import * as admin from 'firebase-admin';
import * as path from 'path';
import * as fs from 'fs';

@Injectable()
export class FirebaseAdminService implements OnModuleInit {
  private readonly logger = new Logger(FirebaseAdminService.name);

  /**
   * Initialize Firebase Admin SDK when the module is initialized
   */
  onModuleInit() {
    // Check if Firebase is already initialized to prevent multiple initializations
    if (!admin.apps.length) {
      try {
        // Path to the service account file at the project root
        const serviceAccountPath = path.join(
          process.cwd(),
          'vouse-4d2c0-firebase-adminsdk-fbsvc-0ae3a7c438.json',
        );

        this.logger.log(
          `Loading Firebase credentials from: ${serviceAccountPath}`,
        );

        // Check if the file exists
        if (!fs.existsSync(serviceAccountPath)) {
          this.logger.error(
            `Service account file not found at: ${serviceAccountPath}`,
          );
          throw new Error('Firebase service account file not found');
        }

        // Load the service account file
        const serviceAccount = JSON.parse(
          fs.readFileSync(serviceAccountPath, 'utf8'),
        );

        // Initialize Firebase Admin with the service account
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
        });

        this.logger.log('Firebase Admin SDK initialized successfully');
      } catch (error) {
        this.logger.error(
          'Failed to initialize Firebase Admin SDK',
          error.stack,
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
   */
  async verifyIdToken(token: string): Promise<admin.auth.DecodedIdToken> {
    try {
      return await admin.auth().verifyIdToken(token);
    } catch (error) {
      this.logger.error(`Error verifying token: ${error.message}`, error.stack);
      throw error;
    }
  }

  /**
   * Get a user by their Firebase UID
   *
   * @param uid The user's UID
   * @returns The user record
   */
  async getUser(uid: string): Promise<admin.auth.UserRecord> {
    try {
      return await admin.auth().getUser(uid);
    } catch (error) {
      this.logger.error(
        `Error getting user ${uid}: ${error.message}`,
        error.stack,
      );
      throw error;
    }
  }
}
