import Redis from 'ioredis';

/**
 * Redis Service for caching and session management
 * Laravel-style Redis service with connection management
 */
class RedisService {
  private client: Redis;
  private static instance: RedisService;

  constructor() {
    this.client = new Redis('redis://default:kgq7lDyxL9wTxBrNUmqj0xneZ0HJB68vmOXbnIHg0ZwuvB1Aj9klv9nvrs2mHAsq@95.179.193.54:7739/0', {
      maxRetriesPerRequest: 3,
      lazyConnect: true,
    });

    this.client.on('connect', () => {
      console.log('✅ Redis connected successfully');
    });

    this.client.on('error', (error) => {
      console.error('❌ Redis connection error:', error);
    });
  }

  /**
   * Get singleton instance
   */
  public static getInstance(): RedisService {
    if (!RedisService.instance) {
      RedisService.instance = new RedisService();
    }
    return RedisService.instance;
  }

  /**
   * Get Redis client
   */
  public getClient(): Redis {
    return this.client;
  }

  /**
   * Set cache with TTL
   */
  public async set(key: string, value: any, ttl: number = 3600): Promise<void> {
    try {
      const serializedValue = typeof value === 'string' ? value : JSON.stringify(value);
      await this.client.setex(key, ttl, serializedValue);
    } catch (error) {
      console.error('Redis set error:', error);
    }
  }

  /**
   * Get cache value
   */
  public async get(key: string): Promise<any> {
    try {
      const value = await this.client.get(key);
      if (!value) return null;
      
      try {
        return JSON.parse(value);
      } catch {
        return value;
      }
    } catch (error) {
      console.error('Redis get error:', error);
      return null;
    }
  }

  /**
   * Delete cache key
   */
  public async del(key: string): Promise<void> {
    try {
      await this.client.del(key);
    } catch (error) {
      console.error('Redis del error:', error);
    }
  }

  /**
   * Clear all cache
   */
  public async flush(): Promise<void> {
    try {
      await this.client.flushdb();
    } catch (error) {
      console.error('Redis flush error:', error);
    }
  }

  /**
   * Check if key exists
   */
  public async exists(key: string): Promise<boolean> {
    try {
      const result = await this.client.exists(key);
      return result === 1;
    } catch (error) {
      console.error('Redis exists error:', error);
      return false;
    }
  }

  /**
   * Set multiple cache keys
   */
  public async mset(keyValues: Record<string, any>, ttl: number = 3600): Promise<void> {
    try {
      const pipeline = this.client.pipeline();
      
      for (const [key, value] of Object.entries(keyValues)) {
        const serializedValue = typeof value === 'string' ? value : JSON.stringify(value);
        pipeline.setex(key, ttl, serializedValue);
      }
      
      await pipeline.exec();
    } catch (error) {
      console.error('Redis mset error:', error);
    }
  }

  /**
   * Get multiple cache keys
   */
  public async mget(keys: string[]): Promise<any[]> {
    try {
      const values = await this.client.mget(...keys);
      return values.map(value => {
        if (!value) return null;
        try {
          return JSON.parse(value);
        } catch {
          return value;
        }
      });
    } catch (error) {
      console.error('Redis mget error:', error);
      return keys.map(() => null);
    }
  }

  /**
   * Close Redis connection
   */
  public async close(): Promise<void> {
    try {
      await this.client.quit();
    } catch (error) {
      console.error('Redis close error:', error);
    }
  }
}

export default RedisService.getInstance(); 