import { Elysia, t } from 'elysia';
import { prisma } from '../config/database';
import { cache, CACHE_KEYS, CACHE_TTL } from '../config/database';

export const settingsRoutes = new Elysia({ prefix: '/settings' })
  // List all settings
  .get('/', async ({ query }) => {
    try {
      const { category, isPublic } = query;

      // Build filters
      const where: any = {};
      if (category) where.category = category;
      if (isPublic !== undefined) where.isPublic = Boolean(isPublic);

      const settings = await prisma.setting.findMany({
        where,
        orderBy: [
          { category: 'asc' },
          { key: 'asc' }
        ]
      });

      return {
        success: true,
        data: settings
      };
    } catch (error) {
      console.error('Get settings error:', error);
      return {
        success: false,
        error: 'Failed to fetch settings'
      };
    }
  }, {
    detail: {
      tags: ['Settings'],
      summary: 'List settings',
      description: 'Get all system settings with optional filtering'
    }
  })

  // Get setting by key
  .get('/:key', async ({ params: { key } }) => {
    try {
      // Check cache first
      const cacheKey = `${CACHE_KEYS.SETTINGS}${key}`;
      const cached = await cache.get(cacheKey);
      
      if (cached) {
        return {
          success: true,
          data: JSON.parse(cached),
          cached: true
        };
      }

      const setting = await prisma.setting.findUnique({
        where: { key }
      });

      if (!setting) {
        return {
          success: false,
          error: 'Setting not found'
        };
      }

      // Cache the result
      await cache.set(cacheKey, JSON.stringify(setting), CACHE_TTL.SETTINGS);

      return {
        success: true,
        data: setting
      };
    } catch (error) {
      console.error('Get setting error:', error);
      return {
        success: false,
        error: 'Failed to fetch setting'
      };
    }
  }, {
    detail: {
      tags: ['Settings'],
      summary: 'Get setting by key',
      description: 'Get a specific setting by its key'
    }
  })

  // Create or update setting
  .post('/', async ({ body }) => {
    try {
      const { key, value, type, category, description, isPublic } = body;

      const setting = await prisma.setting.upsert({
        where: { key },
        update: {
          value: String(value),
          type,
          category,
          description,
          isPublic
        },
        create: {
          key,
          value: String(value),
          type,
          category,
          description,
          isPublic
        }
      });

      // Clear cache
      const cacheKey = `${CACHE_KEYS.SETTINGS}${key}`;
      await cache.del(cacheKey);

      return {
        success: true,
        data: setting,
        message: 'Setting saved successfully'
      };
    } catch (error) {
      console.error('Create setting error:', error);
      return {
        success: false,
        error: 'Failed to save setting'
      };
    }
  }, {
    body: t.Object({
      key: t.String({ minLength: 1 }),
      value: t.Union([t.String(), t.Number(), t.Boolean()]),
      type: t.Union([t.Literal('STRING'), t.Literal('NUMBER'), t.Literal('BOOLEAN'), t.Literal('JSON')]),
      category: t.String({ minLength: 1 }),
      description: t.Optional(t.String()),
      isPublic: t.Optional(t.Boolean())
    }),
    detail: {
      tags: ['Settings'],
      summary: 'Create or update setting',
      description: 'Create a new setting or update existing one'
    }
  })

  // Update setting value
  .put('/:key', async ({ params: { key }, body }) => {
    try {
      const setting = await prisma.setting.findUnique({ where: { key } });
      if (!setting) {
        return {
          success: false,
          error: 'Setting not found'
        };
      }

      const updatedSetting = await prisma.setting.update({
        where: { key },
        data: {
          value: String((body as any).value),
          ...((body as any).type && { type: (body as any).type }),
          ...((body as any).description && { description: (body as any).description }),
          ...((body as any).isPublic !== undefined && { isPublic: (body as any).isPublic })
        }
      });

      // Clear cache
      const cacheKey = `${CACHE_KEYS.SETTINGS}${key}`;
      await cache.del(cacheKey);

      return {
        success: true,
        data: updatedSetting,
        message: 'Setting updated successfully'
      };
    } catch (error) {
      console.error('Update setting error:', error);
      return {
        success: false,
        error: 'Failed to update setting'
      };
    }
  }, {
    detail: {
      tags: ['Settings'],
      summary: 'Update setting',
      description: 'Update an existing setting'
    }
  })

  // Delete setting
  .delete('/:key', async ({ params: { key } }) => {
    try {
      const setting = await prisma.setting.findUnique({ where: { key } });
      if (!setting) {
        return {
          success: false,
          error: 'Setting not found'
        };
      }

      await prisma.setting.delete({ where: { key } });

      // Clear cache
      const cacheKey = `${CACHE_KEYS.SETTINGS}${key}`;
      await cache.del(cacheKey);

      return {
        success: true,
        message: 'Setting deleted successfully'
      };
    } catch (error) {
      console.error('Delete setting error:', error);
      return {
        success: false,
        error: 'Failed to delete setting'
      };
    }
  }, {
    detail: {
      tags: ['Settings'],
      summary: 'Delete setting',
      description: 'Delete a setting permanently'
    }
  })

  // Get settings by category
  .get('/category/:category', async ({ params: { category } }) => {
    try {
      const settings = await prisma.setting.findMany({
        where: { category },
        orderBy: { key: 'asc' }
      });

      return {
        success: true,
        data: settings,
        category
      };
    } catch (error) {
      console.error('Get settings by category error:', error);
      return {
        success: false,
        error: 'Failed to fetch settings'
      };
    }
  }, {
    detail: {
      tags: ['Settings'],
      summary: 'Get settings by category',
      description: 'Get all settings in a specific category'
    }
  })

  // Bulk update settings
  .post('/bulk', async ({ body }) => {
    try {
      const { settings } = body;

      const results = await Promise.all(
        settings.map(async (setting: any) => {
          try {
            const result = await prisma.setting.upsert({
              where: { key: setting.key },
              update: {
                value: String(setting.value),
                type: setting.type,
                category: setting.category,
                description: setting.description,
                isPublic: setting.isPublic
              },
              create: {
                key: setting.key,
                value: String(setting.value),
                type: setting.type,
                category: setting.category,
                description: setting.description,
                isPublic: setting.isPublic
              }
            });

            // Clear cache
            const cacheKey = `${CACHE_KEYS.SETTINGS}${setting.key}`;
            await cache.del(cacheKey);

            return { success: true, key: setting.key, data: result };
          } catch (error) {
            return { success: false, key: setting.key, error: (error as Error).message };
          }
        })
      );

      const successCount = results.filter((r: any) => r.success).length;
      const errorCount = results.filter((r: any) => !r.success).length;

      return {
        success: true,
        data: results,
        summary: {
          total: settings.length,
          successful: successCount,
          failed: errorCount
        },
        message: `Bulk update completed: ${successCount} successful, ${errorCount} failed`
      };
    } catch (error) {
      console.error('Bulk update settings error:', error);
      return {
        success: false,
        error: 'Failed to bulk update settings'
      };
    }
  }, {
    body: t.Object({
      settings: t.Array(t.Object({
        key: t.String(),
        value: t.Union([t.String(), t.Number(), t.Boolean()]),
        type: t.Union([t.Literal('STRING'), t.Literal('NUMBER'), t.Literal('BOOLEAN'), t.Literal('JSON')]),
        category: t.String(),
        description: t.Optional(t.String()),
        isPublic: t.Optional(t.Boolean())
      }))
    }),
    detail: {
      tags: ['Settings'],
      summary: 'Bulk update settings',
      description: 'Update multiple settings at once'
    }
  })

  // Reset to defaults
  .post('/reset', async () => {
    try {
      // Delete all existing settings
      await prisma.setting.deleteMany();

      // Clear cache
      await cache.clear();

      // Create default settings
      const defaultSettings = [
        {
          key: 'recommendation_threshold',
          value: '0.3',
          type: 'NUMBER' as const,
          category: 'algorithm',
          description: 'Minimum similarity threshold for recommendations',
          isPublic: false
        },
        {
          key: 'max_recommendations',
          value: '50',
          type: 'NUMBER' as const,
          category: 'algorithm',
          description: 'Maximum number of recommendations to return',
          isPublic: false
        },
        {
          key: 'learning_rate',
          value: '0.1',
          type: 'NUMBER' as const,
          category: 'algorithm',
          description: 'Learning rate for preference updates',
          isPublic: false
        },
        {
          key: 'cache_ttl_recommendations',
          value: '600',
          type: 'NUMBER' as const,
          category: 'system',
          description: 'Cache TTL for recommendations in seconds',
          isPublic: false
        },
        {
          key: 'enable_learning',
          value: 'true',
          type: 'BOOLEAN' as const,
          category: 'algorithm',
          description: 'Enable learning from successful sales',
          isPublic: false
        }
      ];

      const createdSettings = await Promise.all(
        defaultSettings.map((setting: any) =>
          prisma.setting.create({ data: setting })
        )
      );

      return {
        success: true,
        data: createdSettings,
        message: 'Settings reset to defaults successfully'
      };
    } catch (error) {
      console.error('Reset settings error:', error);
      return {
        success: false,
        error: 'Failed to reset settings'
      };
    }
  }, {
    detail: {
      tags: ['Settings'],
      summary: 'Reset to defaults',
      description: 'Reset all settings to default values'
    }
  })

  // Clear cache
  .post('/clear-cache', async () => {
    try {
      await cache.clear();
      
      return {
        success: true,
        message: 'Settings cache cleared successfully'
      };
    } catch (error) {
      console.error('Clear cache error:', error);
      return {
        success: false,
        error: 'Failed to clear cache'
      };
    }
  }, {
    detail: {
      tags: ['Settings'],
      summary: 'Clear cache',
      description: 'Clear all cached settings'
    }
  }); 