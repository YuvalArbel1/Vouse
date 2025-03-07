// src/auth/services/firebase-admin.service.ts
import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import * as admin from 'firebase-admin';
import * as dotenv from 'dotenv';

dotenv.config();

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
        // Initialize the app with credentials from environment variables
        const projectId = process.env.FIREBASE_PROJECT_ID;
        const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
        const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(
          /\\n/g,
          '\n',
        );

        if (!projectId || !clientEmail || !privateKey) {
          this.logger.error(
            'Missing Firebase credentials in environment variables',
          );
          throw new Error('Missing Firebase credentials');
        }

        admin.initializeApp({
          credential: admin.credential.cert({
            projectId,
            clientEmail,
            privateKey,
          }),
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
