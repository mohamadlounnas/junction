import { PrismaClient, SettingType } from '../../generated/prisma';
import redis from './redis';

/**
 * Settings Service - Laravel-style settings management
 * Handles admin-configurable system settings with Redis caching
 */
class SettingsService {
  private prisma: PrismaClient;
  private cachePrefix = 'settings:';
  private cacheTTL = 3600; // 1 hour

  constructor() {
    this.prisma = new PrismaClient();
  }

  /**
   * Get setting value by key
   */
  public async get(key: string, defaultValue: any = null): Promise<any> {
    try {
      // Try cache first
      const cacheKey = `${this.cachePrefix}${key}`;
      const cachedValue = await redis.get(cacheKey);
      
      if (cachedValue !== null) {
        return cachedValue;
      }

      // Get from database
      const setting = await this.prisma.setting.findUnique({
        where: { key }
      });

      if (!setting) {
        return defaultValue;
      }

      // Parse value based on type
      const parsedValue = this.parseValue(setting.value, setting.type);
      
      // Cache the result
      await redis.set(cacheKey, parsedValue, this.cacheTTL);
      
      return parsedValue;
    } catch (error) {
      console.error('Settings get error:', error);
      return defaultValue;
    }
  }

  /**
   * Set setting value
   */
  public async set(key: string, value: any, type: SettingType = SettingType.STRING, category: string = 'system', description?: string): Promise<void> {
    try {
      const stringValue = typeof value === 'string' ? value : JSON.stringify(value);
      
      // Upsert setting
      await this.prisma.setting.upsert({
        where: { key },
        update: {
          value: stringValue,
          type,
          category,
          description,
          updatedAt: new Date()
        },
        create: {
          key,
          value: stringValue,
          type,
          category,
          description
        }
      });

      // Clear cache
      await this.clearCache(key);
    } catch (error) {
      console.error('Settings set error:', error);
      throw error;
    }
  }

  /**
   * Get all settings by category
   */
  public async getByCategory(category: string): Promise<Record<string, any>> {
    try {
      const cacheKey = `${this.cachePrefix}category:${category}`;
      const cachedValue = await redis.get(cacheKey);
      
      if (cachedValue !== null) {
        return cachedValue;
      }

      const settings = await this.prisma.setting.findMany({
        where: { category },
        orderBy: { key: 'asc' }
      });

      const result: Record<string, any> = {};
      
      for (const setting of settings) {
        result[setting.key] = this.parseValue(setting.value, setting.type);
      }

      // Cache the result
      await redis.set(cacheKey, result, this.cacheTTL);
      
      return result;
    } catch (error) {
      console.error('Settings getByCategory error:', error);
      return {};
    }
  }

  /**
   * Get all settings
   */
  public async getAll(): Promise<Record<string, any>> {
    try {
      const cacheKey = `${this.cachePrefix}all`;
      const cachedValue = await redis.get(cacheKey);
      
      if (cachedValue !== null) {
        return cachedValue;
      }

      const settings = await this.prisma.setting.findMany({
        orderBy: [{ category: 'asc' }, { key: 'asc' }]
      });

      const result: Record<string, any> = {};
      
      for (const setting of settings) {
        result[setting.key] = this.parseValue(setting.value, setting.type);
      }

      // Cache the result
      await redis.set(cacheKey, result, this.cacheTTL);
      
      return result;
    } catch (error) {
      console.error('Settings getAll error:', error);
      return {};
    }
  }

  /**
   * Delete setting
   */
  public async delete(key: string): Promise<void> {
    try {
      await this.prisma.setting.delete({
        where: { key }
      });

      // Clear cache
      await this.clearCache(key);
    } catch (error) {
      console.error('Settings delete error:', error);
      throw error;
    }
  }

  /**
   * Clear all settings cache
   */
  public async clearAllCache(): Promise<void> {
    try {
      const keys = await redis.getClient().keys(`${this.cachePrefix}*`);
      if (keys.length > 0) {
        await redis.getClient().del(...keys);
      }
    } catch (error) {
      console.error('Settings clearAllCache error:', error);
    }
  }

  /**
   * Clear cache for specific key
   */
  private async clearCache(key: string): Promise<void> {
    try {
      const keys = [
        `${this.cachePrefix}${key}`,
        `${this.cachePrefix}all`,
        `${this.cachePrefix}category:*`
      ];
      
      for (const cacheKey of keys) {
        if (cacheKey.includes('*')) {
          // Pattern matching for category cache
          const patternKeys = await redis.getClient().keys(cacheKey);
          if (patternKeys.length > 0) {
            await redis.getClient().del(...patternKeys);
          }
        } else {
          await redis.del(cacheKey);
        }
      }
    } catch (error) {
      console.error('Settings clearCache error:', error);
    }
  }

  /**
   * Parse value based on setting type
   */
  private parseValue(value: string, type: SettingType): any {
    try {
      switch (type) {
        case SettingType.NUMBER:
          return parseFloat(value);
        case SettingType.BOOLEAN:
          return value === 'true' || value === '1';
        case SettingType.JSON:
          return JSON.parse(value);
        case SettingType.STRING:
        default:
          return value;
      }
    } catch (error) {
      console.error('Settings parseValue error:', error);
      return value;
    }
  }

  /**
   * Initialize default settings
   */
  public async initializeDefaults(): Promise<void> {
    const defaultSettings = [
      // Algorithm settings
      {
        key: 'vector_weights',
        value: JSON.stringify({
          price: 0.25,
          area: 0.20,
          location: 0.15,
          property_type: 0.15,
          furnishing: 0.10,
          condition: 0.10,
          rooms: 0.05
        }),
        type: SettingType.JSON,
        category: 'algorithm',
        description: 'Weights for vector calculation in recommendation algorithm'
      },
      {
        key: 'recommendation_threshold',
        value: '0.3',
        type: SettingType.NUMBER,
        category: 'algorithm',
        description: 'Minimum similarity threshold for recommendations'
      },
      {
        key: 'max_recommendations',
        value: '50',
        type: SettingType.NUMBER,
        category: 'algorithm',
        description: 'Maximum number of recommendations to return'
      },
      {
        key: 'learning_rate',
        value: '0.1',
        type: SettingType.NUMBER,
        category: 'algorithm',
        description: 'Learning rate for user preference updates'
      },

      // Business rules
      {
        key: 'price_ranges',
        value: JSON.stringify({
          algiers: { min: 5000, max: 100000 },
          oran: { min: 3000, max: 80000 },
          constantine: { min: 2500, max: 70000 }
        }),
        type: SettingType.JSON,
        category: 'business',
        description: 'Price ranges by city for validation'
      },
      {
        key: 'area_limits',
        value: JSON.stringify({
          apartment: { min: 20, max: 300 },
          villa: { min: 100, max: 1000 },
          office: { min: 30, max: 500 },
          land: { min: 50, max: 2000 }
        }),
        type: SettingType.JSON,
        category: 'business',
        description: 'Area limits by property type'
      },

      // System settings
      {
        key: 'pagination_default_limit',
        value: '10',
        type: SettingType.NUMBER,
        category: 'system',
        description: 'Default pagination limit'
      },
      {
        key: 'pagination_max_limit',
        value: '100',
        type: SettingType.NUMBER,
        category: 'system',
        description: 'Maximum pagination limit'
      },
      {
        key: 'cache_ttl',
        value: '3600',
        type: SettingType.NUMBER,
        category: 'system',
        description: 'Cache TTL in seconds'
      },
      {
        key: 'api_rate_limit',
        value: '100',
        type: SettingType.NUMBER,
        category: 'system',
        description: 'API rate limit per minute'
      }
    ];

    for (const setting of defaultSettings) {
      await this.set(
        setting.key,
        this.parseValue(setting.value, setting.type),
        setting.type,
        setting.category,
        setting.description
      );
    }
  }
}

export default new SettingsService(); 