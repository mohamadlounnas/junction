/**
 * Database Configuration
 * Handles Prisma client and Redis connections
 */

import { PrismaClient } from '@prisma/client';
// Redis will be available after npm install
// import { createClient } from 'redis';

// Environment configuration
const DATABASE_URL = "postgres://postgres:PLXmyyPpWrtJZM99UdOiupWvFoSp1U1jpXEF1ofiVsUwz3SOQvlRkTJowRkaUsO3@95.179.193.54:9834/postgres";
const REDIS_URL = "redis://default:kgq7lDyxL9wTxBrNUmqj0xneZ0HJB68vmOXbnIHg0ZwuvB1Aj9klv9nvrs2mHAsq@95.179.193.54:7739/0";

// Prisma Client Instance
export const prisma = new PrismaClient({
  log: ['query', 'info', 'warn', 'error'],
  datasources: {
    db: {
      url: DATABASE_URL
    }
  }
});

// Redis Client Instance (will be initialized after package install)
export let redis: any = null;

// Redis Connection Management
let redisConnected = false;

export async function connectRedis() {
  if (!redisConnected && redis) {
    try {
      await redis.connect();
      redisConnected = true;
      console.log('✅ Redis connected successfully');
    } catch (error) {
      console.error('❌ Redis connection failed:', error);
      throw error;
    }
  }
  return redis;
}

export async function disconnectRedis() {
  if (redisConnected && redis) {
    await redis.disconnect();
    redisConnected = false;
    console.log('Redis disconnected');
  }
}

// Initialize Redis client (call this after packages are installed)
export function initializeRedis() {
  try {
    const { createClient } = require('redis');
    redis = createClient({
      url: REDIS_URL,
      socket: {
        reconnectStrategy: (retries: number) => Math.min(retries * 50, 500),
      },
    });
    console.log('Redis client initialized');
  } catch (error) {
    console.warn('Redis package not available, caching disabled');
  }
}

// Database Connection Test
export async function testDatabaseConnection() {
  try {
    await prisma.$connect();
    console.log('✅ PostgreSQL connected successfully');
    return true;
  } catch (error) {
    console.error('❌ PostgreSQL connection failed:', error);
    return false;
  }
}

// Graceful Shutdown
export async function closeConnections() {
  await Promise.all([
    prisma.$disconnect(),
    disconnectRedis()
  ]);
  console.log('All database connections closed');
}

// Cache Helper Functions
export const cache = {
  async get(key: string): Promise<string | null> {
    try {
      if (!redisConnected) await connectRedis();
      return await redis.get(key);
    } catch (error) {
      console.error('Cache get error:', error);
      return null;
    }
  },

  async set(key: string, value: string, ttl?: number): Promise<boolean> {
    try {
      if (!redisConnected) await connectRedis();
      if (ttl) {
        await redis.setEx(key, ttl, value);
      } else {
        await redis.set(key, value);
      }
      return true;
    } catch (error) {
      console.error('Cache set error:', error);
      return false;
    }
  },

  async del(key: string): Promise<boolean> {
    try {
      if (!redisConnected) await connectRedis();
      await redis.del(key);
      return true;
    } catch (error) {
      console.error('Cache delete error:', error);
      return false;
    }
  },

  async clear(): Promise<boolean> {
    try {
      if (!redisConnected) await connectRedis();
      await redis.flushAll();
      return true;
    } catch (error) {
      console.error('Cache clear error:', error);
      return false;
    }
  }
};

// Cache Keys
export const CACHE_KEYS = {
  SETTINGS: 'settings:',
  CONTACT_SCORES: 'contact_scores:',
  PROPERTY_SCORES: 'property_scores:',
  RECOMMENDATIONS: 'recommendations:',
  SEARCH_RESULTS: 'search:'
} as const;

// Cache TTL (in seconds)
export const CACHE_TTL = {
  SETTINGS: 3600,       // 1 hour
  SCORES: 1800,         // 30 minutes
  RECOMMENDATIONS: 600,  // 10 minutes
  SEARCH: 300           // 5 minutes
} as const; 