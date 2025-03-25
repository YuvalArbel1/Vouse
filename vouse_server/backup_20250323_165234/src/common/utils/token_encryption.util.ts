// src/common/utils/token_encryption.util.ts
import * as crypto from 'crypto';
import * as dotenv from 'dotenv';
import { Injectable, Logger } from '@nestjs/common';

/**
 * Utility for encrypting and decrypting sensitive tokens using AES-256-GCM
 * Uses environment variable ENCRYPTION_KEY for the encryption key
 */
@Injectable()
export class TokenEncryption {
  private readonly algorithm = 'aes-256-gcm';
  private readonly key: Buffer;
  private readonly logger = new Logger(TokenEncryption.name);

  /**
   * Initialize the encryption utility with the key from environment variables
   * @throws Error if encryption key environment variable is missing
   */
  constructor() {
    // Ensure environment variables are loaded
    dotenv.config();

    // Get the encryption key from environment variables
    const encryptionKey = process.env.ENCRYPTION_KEY;

    if (!encryptionKey) {
      const errorMessage = 'ENCRYPTION_KEY environment variable is required';
      this.logger.error(errorMessage);
      throw new Error(errorMessage);
    }

    // Log the key length to verify it's correct
    this.logger.debug(`Encryption key length: ${encryptionKey.length}`);

    if (encryptionKey.length !== 32) {
      this.logger.warn(
        'Encryption key is not 32 characters - using SHA-256 hash instead',
      );
      // Create a SHA-256 hash for consistent key length
      const hash = crypto.createHash('sha256');
      hash.update(encryptionKey);
      const derivedKey = hash.digest('hex').substring(0, 32);
      this.key = Buffer.from(derivedKey, 'utf8');
    } else {
      this.key = Buffer.from(encryptionKey, 'utf8');
    }
  }

  /**
   * Encrypt a token string using AES-256-GCM
   *
   * @param token - The token to encrypt
   * @returns The encrypted token or null if encryption fails
   */
  encrypt(token: string | null): string | null {
    if (!token) {
      return null;
    }

    try {
      // Generate a random initialization vector
      const iv = crypto.randomBytes(16);

      // Create cipher
      const cipher = crypto.createCipheriv(this.algorithm, this.key, iv);

      // Encrypt the token
      let encrypted = cipher.update(token, 'utf8', 'hex');
      encrypted += cipher.final('hex');

      // Get the authentication tag
      const authTag = cipher.getAuthTag();

      // Return the IV, encrypted token, and authentication tag as a combined string
      return (
        iv.toString('hex') + ':' + encrypted + ':' + authTag.toString('hex')
      );
    } catch (error) {
      const typedError = error as Error;
      this.logger.error(
        `Encryption error: ${typedError.message}`,
        typedError.stack,
      );
      return null;
    }
  }

  /**
   * Decrypt an encrypted token string
   *
   * @param encryptedToken - The encrypted token to decrypt
   * @returns The decrypted token or null if decryption fails
   */
  decrypt(encryptedToken: string | null): string | null {
    if (!encryptedToken) {
      return null;
    }

    try {
      // Split the encrypted token into its components
      const parts = encryptedToken.split(':');
      if (parts.length !== 3) {
        throw new Error('Invalid encrypted token format');
      }

      const iv = Buffer.from(parts[0], 'hex');
      const encrypted = parts[1];
      const authTag = Buffer.from(parts[2], 'hex');

      // Create decipher
      const decipher = crypto.createDecipheriv(this.algorithm, this.key, iv);
      decipher.setAuthTag(authTag);

      // Decrypt the token
      let decrypted = decipher.update(encrypted, 'hex', 'utf8');
      decrypted += decipher.final('utf8');

      return decrypted;
    } catch (error) {
      const typedError = error as Error;
      this.logger.error(
        `Decryption error: ${typedError.message}`,
        typedError.stack,
      );
      return null;
    }
  }
}
