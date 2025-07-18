import { Elysia, t } from 'elysia';
import { adminMiddleware } from '../middleware/admin';
import settingsService from '../services/settings';
import { SettingType } from '../../generated/prisma';

/**
 * Admin Settings Controller - Laravel-style resource controller
 * Handles CRUD operations for system settings
 */
export const adminSettingsController = new Elysia()
  .use(adminMiddleware)
  .group('/api/admin/settings', app => app
    // Index - Get all settings
    .get('/', async () => {
      try {
        const settings = await settingsService.getAll();
        
        return {
          success: true,
          data: settings,
          message: 'Settings retrieved successfully'
        };
      } catch (error) {
        return {
          success: false,
          error: 'Failed to retrieve settings',
          message: error instanceof Error ? error.message : 'Unknown error'
        };
      }
    })

    // Show - Get setting by key
    .get('/:key', async ({ params: { key } }) => {
      try {
        const value = await settingsService.get(key);
        
        if (value === null) {
          return {
            success: false,
            error: 'Setting not found',
            message: `Setting with key '${key}' does not exist`
          };
        }

        return {
          success: true,
          data: {
            key,
            value
          },
          message: 'Setting retrieved successfully'
        };
      } catch (error) {
        return {
          success: false,
          error: 'Failed to retrieve setting',
          message: error instanceof Error ? error.message : 'Unknown error'
        };
      }
    }, {
      params: t.Object({
        key: t.String()
      })
    })

    // Store - Create new setting
    .post('/', async ({ body }) => {
      try {
        await settingsService.set(
          body.key,
          body.value,
          body.type || SettingType.STRING,
          body.category || 'system',
          body.description
        );

        return {
          success: true,
          message: 'Setting created successfully',
          data: {
            key: body.key,
            value: body.value
          }
        };
      } catch (error) {
        return {
          success: false,
          error: 'Failed to create setting',
          message: error instanceof Error ? error.message : 'Unknown error'
        };
      }
    }, {
      body: t.Object({
        key: t.String(),
        value: t.Any(),
        type: t.Optional(t.Union([
          t.Literal('STRING'),
          t.Literal('NUMBER'),
          t.Literal('BOOLEAN'),
          t.Literal('JSON')
        ])),
        category: t.Optional(t.String()),
        description: t.Optional(t.String())
      })
    })

    // Update - Update setting
    .put('/:key', async ({ params: { key }, body }) => {
      try {
        await settingsService.set(
          key,
          body.value,
          body.type || SettingType.STRING,
          body.category || 'system',
          body.description
        );

        return {
          success: true,
          message: 'Setting updated successfully',
          data: {
            key,
            value: body.value
          }
        };
      } catch (error) {
        return {
          success: false,
          error: 'Failed to update setting',
          message: error instanceof Error ? error.message : 'Unknown error'
        };
      }
    }, {
      params: t.Object({
        key: t.String()
      }),
      body: t.Object({
        value: t.Any(),
        type: t.Optional(t.Union([
          t.Literal('STRING'),
          t.Literal('NUMBER'),
          t.Literal('BOOLEAN'),
          t.Literal('JSON')
        ])),
        category: t.Optional(t.String()),
        description: t.Optional(t.String())
      })
    })

    // Destroy - Delete setting
    .delete('/:key', async ({ params: { key } }) => {
      try {
        await settingsService.delete(key);

        return {
          success: true,
          message: 'Setting deleted successfully'
        };
      } catch (error) {
        return {
          success: false,
          error: 'Failed to delete setting',
          message: error instanceof Error ? error.message : 'Unknown error'
        };
      }
    }, {
      params: t.Object({
        key: t.String()
      })
    })

    // Get settings by category
    .get('/category/:category', async ({ params: { category } }) => {
      try {
        const settings = await settingsService.getByCategory(category);

        return {
          success: true,
          data: settings,
          message: `Settings for category '${category}' retrieved successfully`
        };
      } catch (error) {
        return {
          success: false,
          error: 'Failed to retrieve settings by category',
          message: error instanceof Error ? error.message : 'Unknown error'
        };
      }
    }, {
      params: t.Object({
        category: t.String()
      })
    })

    // Bulk update settings
    .post('/bulk', async ({ body }) => {
      try {
        const { settings } = body;
        const results = [];

        for (const setting of settings) {
          try {
            await settingsService.set(
              setting.key,
              setting.value,
              setting.type || SettingType.STRING,
              setting.category || 'system',
              setting.description
            );
            results.push({ key: setting.key, status: 'success' });
          } catch (error) {
            results.push({ 
              key: setting.key, 
              status: 'error', 
              message: error instanceof Error ? error.message : 'Unknown error' 
            });
          }
        }

        return {
          success: true,
          message: 'Bulk update completed',
          data: results
        };
      } catch (error) {
        return {
          success: false,
          error: 'Failed to perform bulk update',
          message: error instanceof Error ? error.message : 'Unknown error'
        };
      }
    }, {
      body: t.Object({
        settings: t.Array(t.Object({
          key: t.String(),
          value: t.Any(),
          type: t.Optional(t.Union([
            t.Literal('STRING'),
            t.Literal('NUMBER'),
            t.Literal('BOOLEAN'),
            t.Literal('JSON')
          ])),
          category: t.Optional(t.String()),
          description: t.Optional(t.String())
        }))
      })
    })

    // Reset to defaults
    .post('/reset', async () => {
      try {
        await settingsService.initializeDefaults();

        return {
          success: true,
          message: 'Settings reset to defaults successfully'
        };
      } catch (error) {
        return {
          success: false,
          error: 'Failed to reset settings',
          message: error instanceof Error ? error.message : 'Unknown error'
        };
      }
    })

    // Clear cache
    .post('/clear-cache', async () => {
      try {
        await settingsService.clearAllCache();

        return {
          success: true,
          message: 'Settings cache cleared successfully'
        };
      } catch (error) {
        return {
          success: false,
          error: 'Failed to clear cache',
          message: error instanceof Error ? error.message : 'Unknown error'
        };
      }
    })
  ); 