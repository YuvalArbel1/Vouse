// src/users/services/user.service.ts
import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../entities/user.entity';
import {
  CreateUserDto,
  ConnectTwitterDto,
  UpdateConnectionStatusDto,
} from '../dto/user.dto';

/**
 * Service for managing user operations
 */
@Injectable()
export class UserService {
  private readonly logger = new Logger(UserService.name);
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
  ) {}

  /**
   * Find a user by their Firebase userId
   */
  async findOne(userId: string): Promise<User | null> {
    return this.userRepository.findOne({ where: { userId } });
  }

  /**
   * Find a user or throw an exception if not found
   */
  async findOneOrFail(userId: string): Promise<User> {
    const user = await this.findOne(userId);
    if (!user) {
      throw new NotFoundException(`User with ID ${userId} not found`);
    }
    return user;
  }

  /**
   * Create a new user
   */
  async create(createUserDto: CreateUserDto): Promise<User> {
    this.logger.log(
      `Attempting to create user record for ${createUserDto.userId}`,
    );
    const user = this.userRepository.create(createUserDto);
    try {
      const savedUser = await this.userRepository.save(user);
      this.logger.log(
        `Successfully created and saved user record for ${savedUser.userId}`,
      );
      return savedUser;
    } catch (error) {
      this.logger.error(
        `Failed to save new user record for ${createUserDto.userId}: ${error.message}`,
        error.stack,
      );
      throw error; // Re-throw the error to be handled upstream
    }
  }

  /**
   * Create a user if they don't exist, or return the existing user
   */
  async findOrCreate(userId: string): Promise<User> {
    this.logger.log(`findOrCreate called for user ${userId}`);
    let user = await this.findOne(userId);

    if (!user) {
      this.logger.log(`User ${userId} not found, attempting to create...`);
      try {
        user = await this.create({ userId });
        this.logger.log(`User ${userId} created successfully by findOrCreate.`);
      } catch (creationError) {
        this.logger.error(
          `User creation failed within findOrCreate for ${userId}: ${creationError.message}`,
        );
        // Attempt to find the user again in case of a race condition
        user = await this.findOne(userId);
        if (!user) {
          this.logger.error(
            `User ${userId} still not found after creation attempt failed.`,
          );
          throw new Error(`Failed to find or create user ${userId}.`);
        } else {
          this.logger.warn(
            `User ${userId} found after failed creation attempt (possible race condition).`,
          );
        }
      }
    } else {
      this.logger.log(`User ${userId} found in database.`);
    }

    return user;
  }

  /**
   * Store Twitter tokens for a user
   */
  async connectTwitter(
    userId: string,
    connectTwitterDto: ConnectTwitterDto,
  ): Promise<User> {
    const user = await this.findOneOrFail(userId);

    // Set token values
    user.accessToken = connectTwitterDto.accessToken;
    // Handle optional refreshToken
    user.refreshToken = connectTwitterDto.refreshToken ?? user.refreshToken;
    user.isConnected = true;

    if (connectTwitterDto.tokenExpiresAt) {
      user.tokenExpiresAt = new Date(connectTwitterDto.tokenExpiresAt);
    } else {
      user.tokenExpiresAt = null;
    }

    this.logger.log(
      `Attempting to save tokens for user ${userId}. AccessToken provided: ${!!connectTwitterDto.accessToken}, RefreshToken provided: ${!!connectTwitterDto.refreshToken}`,
    );
    this.logger.debug(`Saving user data: ${JSON.stringify(user)}`); // Log the user object before saving

    try {
      const savedUser = await this.userRepository.save(user);
      this.logger.log(
        `Successfully saved tokens for user ${userId}. TypeORM returned isConnected: ${savedUser.isConnected}, AccessToken exists: ${!!savedUser.accessToken}, RefreshToken exists: ${!!savedUser.refreshToken}`,
      );

      // Verification Step: Re-fetch directly from DB immediately after save
      const userFromDbAfterSave = await this.findOne(userId);
      if (userFromDbAfterSave) {
        this.logger.log(
          `Verification fetch for user ${userId}. DB isConnected: ${userFromDbAfterSave.isConnected}, DB AccessToken exists: ${!!userFromDbAfterSave.accessToken}, DB RefreshToken exists: ${!!userFromDbAfterSave.refreshToken}`,
        );
        this.logger.debug(
          `Verification fetch data: ${JSON.stringify(userFromDbAfterSave)}`,
        );
      } else {
        this.logger.error(
          `Verification fetch failed for user ${userId} - user not found after save!`,
        );
      }
      // End Verification Step

      return savedUser; // Still return the entity TypeORM provided from save()
    } catch (error) {
      this.logger.error(
        `Failed to save tokens for user ${userId}: ${error.message}`,
        error.stack,
      );
      throw error; // Re-throw error
    }
  }

  /**
   * Remove Twitter tokens for a user
   */
  async disconnectTwitter(userId: string): Promise<User> {
    const user = await this.findOneOrFail(userId);

    // Clear token values
    user.accessToken = null;
    user.refreshToken = null;
    user.isConnected = false;
    user.tokenExpiresAt = null;

    return this.userRepository.save(user);
  }

  /**
   * Update a user's Twitter connection status
   */
  async updateConnectionStatus(
    userId: string,
    updateConnectionStatusDto: UpdateConnectionStatusDto,
  ): Promise<User> {
    const user = await this.findOneOrFail(userId);

    user.isConnected = updateConnectionStatusDto.isConnected;

    // If connection status is set to false, also clear tokens
    if (!updateConnectionStatusDto.isConnected) {
      user.accessToken = null;
      user.refreshToken = null;
      user.tokenExpiresAt = null;
    }

    return this.userRepository.save(user);
  }
}
