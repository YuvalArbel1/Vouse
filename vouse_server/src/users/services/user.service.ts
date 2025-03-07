// src/users/services/user.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
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
  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
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
    const user = this.userRepository.create(createUserDto);
    return this.userRepository.save(user);
  }

  /**
   * Create a user if they don't exist, or return the existing user
   */
  async findOrCreate(userId: string): Promise<User> {
    let user = await this.findOne(userId);

    if (!user) {
      user = await this.create({ userId });
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

    // In a real implementation, we would encrypt these tokens before storage
    user.accessToken = connectTwitterDto.accessToken;
    user.refreshToken = connectTwitterDto.refreshToken;
    user.isConnected = true;

    if (connectTwitterDto.tokenExpiresAt) {
      user.tokenExpiresAt = new Date(connectTwitterDto.tokenExpiresAt);
    }

    return this.userRepository.save(user);
  }

  /**
   * Remove Twitter tokens for a user
   */
  async disconnectTwitter(userId: string): Promise<User> {
    const user = await this.findOneOrFail(userId);

    // Use null instead of undefined
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

    return this.userRepository.save(user);
  }
}
