import { Elysia, t } from 'elysia';
import { prisma } from '../config/database';
import { generateScoresFromContact, generateAllScoresFromContact, validateScoreVector, calculateSimilarity } from '../services/score-generator';

export const contactsRoutes = new Elysia({ prefix: '/contacts' })
  // List contacts with filtering and pagination
  .get('/', async ({ query }) => {
    try {
      const {
        page = 1,
        limit = 10,
        type,
        search,
        wilaya,
        transactionType,
        transactionTypes,
        primaryTransactionType,
        budgetMin,
        budgetMax,
        hasChildren,
        isActive = true
      } = query;

      // Convert string values to proper types
      const pageNum = Math.max(1, Number(page));
      const limitNum = Math.min(50, Math.max(1, Number(limit)));
      const skip = (pageNum - 1) * limitNum;
      
      // Convert boolean strings to actual booleans
      const isActiveBool = typeof isActive === 'string' ? isActive.toLowerCase() === 'true' : Boolean(isActive);
      const hasChildrenBool = hasChildren !== undefined ? 
        (typeof hasChildren === 'string' ? hasChildren.toLowerCase() === 'true' : Boolean(hasChildren)) : 
        undefined;
      
      // Convert number strings to actual numbers
      const budgetMinNum = budgetMin !== undefined ? Number(budgetMin) : undefined;
      const budgetMaxNum = budgetMax !== undefined ? Number(budgetMax) : undefined;

      // Build filters
      const where: any = {};
      
      if (isActiveBool !== undefined) where.isActive = isActiveBool;
      if (type) where.type = type;
      if (transactionType) where.transactionType = transactionType;
      if (primaryTransactionType) where.primaryTransactionType = primaryTransactionType;
      if (transactionTypes) {
        // Support filtering by multiple transaction types
        where.transactionTypes = { hasSome: Array.isArray(transactionTypes) ? transactionTypes : [transactionTypes] };
      }
      if (hasChildrenBool !== undefined) where.hasChildren = hasChildrenBool;
      
      if (search) {
        where.OR = [
          { name: { contains: search, mode: 'insensitive' } },
          { email: { contains: search, mode: 'insensitive' } }
        ];
      }

      if (wilaya) {
        where.locationWilayas = { has: wilaya };
      }

      if (budgetMinNum !== undefined) {
        where.budgetMin = { gte: budgetMinNum };
      }

      if (budgetMaxNum !== undefined) {
        where.budgetMax = { lte: budgetMaxNum };
      }

      // Get total count for pagination
      const total = await prisma.contact.count({ where });

      // Get contacts with pagination
      const contacts = await prisma.contact.findMany({
        where,
        skip,
        take: limitNum,
        orderBy: { createdAt: 'desc' }
      });

      return {
        success: true,
        data: contacts,
        pagination: {
          page: pageNum,
          limit: limitNum,
          total,
          pages: Math.ceil(total / limitNum)
        },
        filters: { 
          type, 
          search, 
          wilaya, 
          transactionType, 
          transactionTypes,
          primaryTransactionType,
          budgetMin: budgetMinNum, 
          budgetMax: budgetMaxNum, 
          hasChildren: hasChildrenBool 
        }
      };
    } catch (error) {
      console.error('Get contacts error:', error);
      return {
        success: false,
        error: 'Failed to fetch contacts'
      };
    }
  }, {
    query: t.Object({
      page: t.Optional(t.Union([
        t.Number({ minimum: 1, default: 1, description: 'Page number for pagination' }),
        t.String({ description: 'Page number as string' })
      ])),
      limit: t.Optional(t.Union([
        t.Number({ minimum: 1, maximum: 50, default: 10, description: 'Number of results per page (max 50)' }),
        t.String({ description: 'Limit as string' })
      ])),
      type: t.Optional(t.Union([
        t.Literal('BUYER'),
        t.Literal('TENANT'), 
        t.Literal('INVESTOR')
      ], { description: 'Filter by contact type' })),
      search: t.Optional(t.String({ description: 'Search in name and email fields' })),
      wilaya: t.Optional(t.String({ description: 'Filter by preferred wilaya (e.g., Algiers, Oran, Constantine)' })),
      transactionType: t.Optional(t.Union([
        t.Literal('RENT'),
        t.Literal('SALE')
      ], { description: 'Filter by transaction preference (legacy)' })),
      transactionTypes: t.Optional(t.Union([
        t.Array(t.Union([t.Literal('RENT'), t.Literal('SALE')])),
        t.String({ description: 'Filter by multiple transaction types' })
      ], { description: 'Filter by multiple transaction types' })),
      primaryTransactionType: t.Optional(t.Union([
        t.Literal('RENT'),
        t.Literal('SALE')
      ], { description: 'Filter by primary transaction type' })),
      budgetMin: t.Optional(t.Union([
        t.Number({ minimum: 0, description: 'Minimum budget in DZD' }),
        t.String({ description: 'Minimum budget as string' })
      ])),
      budgetMax: t.Optional(t.Union([
        t.Number({ minimum: 0, description: 'Maximum budget in DZD' }),
        t.String({ description: 'Maximum budget as string' })
      ])),
      hasChildren: t.Optional(t.Union([
        t.Boolean({ description: 'Filter by family status' }),
        t.String({ description: 'Has children as string' })
      ])),
      isActive: t.Optional(t.Union([
        t.Boolean({ default: true, description: 'Filter by active status' }),
        t.String({ description: 'Active status as string' })
      ]))
    }),
    detail: {
      tags: ['Contacts'],
      summary: 'List contacts with enhanced filtering',
      description: `
## Enhanced Contact Listing with Dual Transaction Support

List contacts with comprehensive filtering options including the new dual transaction type support.

### 🔄 Dual Transaction Support
- **Legacy**: Filter by single transactionType (RENT/SALE)
- **Enhanced**: Filter by multiple transactionTypes or primaryTransactionType
- **Flexibility**: Support for contacts interested in both RENT and SALE

### 📋 Filter Options
- **Type**: BUYER, TENANT, INVESTOR
- **Transaction**: Single or multiple transaction types
- **Location**: Wilaya-based filtering
- **Budget**: Min/max budget ranges
- **Family**: Children status
- **Search**: Name and email search

### 🎯 Use Cases
- Find flexible buyers open to both renting and buying
- Target investors with specific transaction preferences
- Segment contacts by primary vs secondary transaction interests
        `
    }
  })

  // Get contact by ID
  .get('/:id', async ({ params: { id } }) => {
    try {
      const contact = await prisma.contact.findUnique({
        where: { id },
        include: {
          sales: {
            include: {
              property: {
                select: { id: true, title: true, price: true }
              }
            }
          }
        }
      });

      if (!contact) {
        return {
          success: false,
          error: 'Contact not found'
        };
      }

      return {
        success: true,
        data: contact
      };
    } catch (error) {
      console.error('Get contact error:', error);
      return {
        success: false,
        error: 'Failed to fetch contact'
      };
    }
  }, {
    detail: {
      tags: ['Contacts'],
      summary: 'Get contact by ID',
      description: 'Get a specific contact with their sales history'
    }
  })

  // Create new contact with enhanced dual transaction support
  .post('/', async ({ body, set }) => {
    try {
      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(body.email)) {
        set.status = 400;
        return {
          success: false,
          error: 'Invalid email format',
          message: 'Please provide a valid email address'
        };
      }

      // Generate enhanced scores with dual transaction support
      const allScores = generateAllScoresFromContact(body);
      
      // Prepare contact data with backward compatibility
      const contactData = {
        ...body,
        scores: allScores.scores,
        transactionScores: allScores.transactionScores,
        // Ensure legacy field is set for backward compatibility
        transactionType: (body.primaryTransactionType || body.transactionTypes?.[0] || body.transactionType) as 'RENT' | 'SALE'
      };

      const contact = await prisma.contact.create({
        data: contactData
      });

      return {
        success: true,
        data: contact,
        message: 'Contact created successfully with enhanced transaction support'
      };
    } catch (error) {
      console.error('Create contact error:', error);
      set.status = 500;
      return {
        success: false,
        error: 'Failed to create contact'
      };
    }
  }, {
    body: t.Object({
      email: t.String({ minLength: 5 }),
      name: t.String({ minLength: 2 }),
      phone: t.Optional(t.String()),
      type: t.Union([t.Literal('BUYER'), t.Literal('TENANT'), t.Literal('INVESTOR')]),
      budgetMin: t.Optional(t.Number({ minimum: 0 })),
      budgetMax: t.Optional(t.Number({ minimum: 0 })),
      locationWilayas: t.Array(t.String()),
      locationCities: t.Array(t.String()),
      propertyTypes: t.Array(t.Union([
        t.Literal('APARTMENT'), t.Literal('VILLA'), t.Literal('HOUSE'),
        t.Literal('OFFICE'), t.Literal('SHOP'), t.Literal('WAREHOUSE'),
        t.Literal('LAND'), t.Literal('GARAGE')
      ])),
      // Enhanced transaction type support
      transactionType: t.Optional(t.Union([t.Literal('RENT'), t.Literal('SALE')])), // Legacy support
      transactionTypes: t.Optional(t.Array(t.Union([t.Literal('RENT'), t.Literal('SALE')]))),
      primaryTransactionType: t.Optional(t.Union([t.Literal('RENT'), t.Literal('SALE')])),
      transactionFlexibility: t.Optional(t.Number({ minimum: 0, maximum: 1 })),
      familySize: t.Optional(t.Number({ minimum: 1 })),
      hasChildren: t.Boolean(),
      minRooms: t.Optional(t.Number({ minimum: 1 })),
      maxRooms: t.Optional(t.Number({ minimum: 1 })),
      minArea: t.Optional(t.Number({ minimum: 1 })),
      maxArea: t.Optional(t.Number({ minimum: 1 })),
      furnishingType: t.Optional(t.Union([
        t.Literal('FURNISHED'),
        t.Literal('SEMI_FURNISHED'),
        t.Literal('UNFURNISHED')
      ])),
      preferredCondition: t.Optional(t.Union([
        t.Literal('POOR'),
        t.Literal('FAIR'),
        t.Literal('GOOD'),
        t.Literal('EXCELLENT'),
        t.Literal('NEW')
      ])),
      requiresParking: t.Boolean(),
      requiresSecurity: t.Boolean(),
      notes: t.Optional(t.String())
    }),
    detail: {
      tags: ['Contacts'],
      summary: 'Create new contact with enhanced dual transaction support',
      description: `
## Create New Contact with Enhanced Dual Transaction Support

Creates a new contact with support for multiple transaction types and automatic AI scoring.

### 🔄 Enhanced Transaction Support
- **Legacy**: Single transactionType (RENT/SALE)
- **Enhanced**: Multiple transactionTypes with primary preference
- **Flexibility**: Transaction flexibility score (0-1)
- **Backward Compatible**: Works with existing single transaction type

### 🤖 AI Features
- **Dual Scoring**: Generates both main 12D vector and transaction scores
- **Flexibility Scoring**: Considers transaction flexibility in recommendations
- **Primary Preference**: Prioritizes primary transaction type in matching

### 📋 Required Fields
- **email**: Valid email address
- **name**: Full name (minimum 2 characters)
- **type**: BUYER, TENANT, or INVESTOR
- **hasChildren**: Family status (boolean)
- **requiresParking**: Parking preference (boolean)
- **requiresSecurity**: Security preference (boolean)

### 🎯 Transaction Configuration
- **transactionTypes**: Array of interested transaction types ['RENT', 'SALE']
- **primaryTransactionType**: Main preference (optional, defaults to first in array)
- **transactionFlexibility**: 0-1 score for flexibility (optional, defaults to 0.5)

### 💡 Example Usage
\`\`\`json
{
  "email": "flexible.buyer@example.dz",
  "name": "Ahmed Flexible",
  "type": "BUYER",
  "transactionTypes": ["SALE", "RENT"],
  "primaryTransactionType": "SALE",
  "transactionFlexibility": 0.7,
  "budgetMin": 10000000,
  "budgetMax": 20000000
}
\`\`\`
        `
    }
  })

  // Update contact
  .put('/:id', async ({ params: { id }, body }) => {
    try {
      // Check if contact exists
      const existingContact = await prisma.contact.findUnique({ where: { id } });
      if (!existingContact) {
        return {
          success: false,
          error: 'Contact not found'
        };
      }

      // Regenerate scores with updated data
      const updatedData = { ...existingContact, ...(body as any) };
      const scores = generateScoresFromContact(updatedData);

      const contact = await prisma.contact.update({
        where: { id },
        data: {
          ...(body as any),
          scores
        }
      });

      return {
        success: true,
        data: contact,
        message: 'Contact updated successfully'
      };
    } catch (error) {
      console.error('Update contact error:', error);
      return {
        success: false,
        error: 'Failed to update contact'
      };
    }
  }, {
    detail: {
      tags: ['Contacts'],
      summary: 'Update contact',
      description: 'Update contact and regenerate scores'
    }
  })

  // Delete contact
  .delete('/:id', async ({ params: { id } }) => {
    try {
      // Check if contact exists
      const contact = await prisma.contact.findUnique({ where: { id } });
      if (!contact) {
        return {
          success: false,
          error: 'Contact not found'
        };
      }

      await prisma.contact.delete({ where: { id } });

      return {
        success: true,
        message: 'Contact deleted successfully'
      };
    } catch (error) {
      console.error('Delete contact error:', error);
      return {
        success: false,
        error: 'Failed to delete contact'
      };
    }
  }, {
    detail: {
      tags: ['Contacts'],
      summary: 'Delete contact',
      description: 'Delete a contact permanently'
    }
  })

  // Get contact scores
  .get('/:id/scores', async ({ params: { id } }) => {
    try {
      const contact = await prisma.contact.findUnique({
        where: { id },
        select: { id: true, name: true, scores: true }
      });

      if (!contact) {
        return {
          success: false,
          error: 'Contact not found'
        };
      }

      return {
        success: true,
        data: {
          contactId: contact.id,
          name: contact.name,
          scores: contact.scores,
          dimensions: [
            'Budget', 'Area', 'Rooms', 'Location', 'Property Type',
            'Condition', 'Features', 'Family', 'Modern', 'Investment', 'Urgency', 'Transaction'
          ]
        }
      };
    } catch (error) {
      console.error('Get contact scores error:', error);
      return {
        success: false,
        error: 'Failed to fetch contact scores'
      };
    }
  }, {
    detail: {
      tags: ['Contacts'],
      summary: 'Get contact AI scores (12D vector)',
      description: `
## Get Contact's 12-Dimensional Preference Vector

Retrieve the AI-generated 12D vector that represents this contact's preferences for property matching.

### 🤖 Vector Analysis
Each dimension is scored 0.0 to 1.0:
- **0.0-0.3**: Low importance/preference
- **0.3-0.7**: Medium importance/preference  
- **0.7-1.0**: High importance/preference

### 📊 Dimension Explanations
1. **Budget** (0-1): Price sensitivity and range
2. **Area** (0-1): Size requirements importance
3. **Rooms** (0-1): Room count preference strength
4. **Location** (0-1): Geographic preference (Algeria-optimized)
5. **Property Type** (0-1): Villa, apartment, house preference
6. **Condition** (0-1): Property condition importance
7. **Features** (0-1): Amenities and facilities importance
8. **Family** (0-1): Family-friendliness needs
9. **Modern** (0-1): Modernity vs traditional preference
10. **Investment** (0-1): Investment potential interest
11. **Urgency** (0-1): Decision timeline pressure
12. **Transaction** (0/1): Binary - RENT (0) or SALE (1)

### 🇩🇿 Algeria Optimization
- Wilaya preferences automatically scored
- Cultural factors included in family dimension
- DZD budget ranges properly normalized
      `,
      responses: {
        '200': {
          description: 'Contact scores retrieved successfully',
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  success: { type: 'boolean', example: true },
                  data: {
                    type: 'object',
                    properties: {
                      contactId: { type: 'string', example: 'cmd8bvuwy0009m5y8bqjlgepr' },
                      name: { type: 'string', example: 'Ahmed Benali' },
                      scores: { 
                        type: 'array', 
                        items: { type: 'number', minimum: 0, maximum: 1 },
                        example: [0.38, 0.5, 0.5, 0.95, 0.8, 0.7, 0.9, 0.8, 0.6, 0.5, 0.3, 1.0],
                        description: '12D preference vector'
                      },
                      dimensions: {
                        type: 'array',
                        items: { type: 'string' },
                        example: ['Budget', 'Area', 'Rooms', 'Location', 'Property Type', 'Condition', 'Features', 'Family', 'Modern', 'Investment', 'Urgency', 'Transaction']
                      }
                    }
                  }
                }
              },
              examples: {
                'algerian_buyer_scores': {
                  summary: 'Algerian Family Buyer Scores',
                  description: 'High location preference (Algiers=0.95), family needs (0.8), wants to buy (1.0)',
                  value: {
                    success: true,
                    data: {
                      contactId: 'cmd8bvuwy0009m5y8bqjlgepr',
                      name: 'Ahmed Benali',
                      scores: [0.38, 0.5, 0.5, 0.95, 0.8, 0.7, 0.9, 0.8, 0.6, 0.5, 0.3, 1.0],
                      dimensions: ['Budget', 'Area', 'Rooms', 'Location', 'Property Type', 'Condition', 'Features', 'Family', 'Modern', 'Investment', 'Urgency', 'Transaction']
                    }
                  }
                },
                'student_tenant_scores': {
                  summary: 'Student Tenant Scores',
                  description: 'Budget-conscious (0.15), apartment preference (0.9), renting (0.0)',
                  value: {
                    success: true,
                    data: {
                      contactId: 'cmd8bvuwy0009m5y8bqjlgepr',
                      name: 'Sara Koui',
                      scores: [0.15, 0.2, 0.3, 0.85, 0.9, 0.5, 0.4, 0.1, 0.8, 0.2, 0.8, 0.0],
                      dimensions: ['Budget', 'Area', 'Rooms', 'Location', 'Property Type', 'Condition', 'Features', 'Family', 'Modern', 'Investment', 'Urgency', 'Transaction']
                    }
                  }
                }
              }
            }
          }
        },
        '404': {
          description: 'Contact not found',
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  success: { type: 'boolean', example: false },
                  error: { type: 'string', example: 'Contact not found' }
                }
              }
            }
          }
        }
      }
    }
  })

  // Update contact scores manually (for testing)
  .put('/:id/scores', async ({ params: { id }, body }) => {
    try {
      const { scores } = body;

      // Validate scores
      if (!validateScoreVector(scores)) {
        return {
          success: false,
          error: 'Invalid score vector - must be 12 numbers between 0 and 1'
        };
      }

      const contact = await prisma.contact.update({
        where: { id },
        data: { scores }
      });

      return {
        success: true,
        data: contact,
        message: 'Contact scores updated successfully'
      };
    } catch (error) {
      console.error('Update contact scores error:', error);
      return {
        success: false,
        error: 'Failed to update contact scores'
      };
    }
  }, {
    body: t.Object({
      scores: t.Array(t.Number({ minimum: 0, maximum: 1 }), { minItems: 12, maxItems: 12 })
    }),
    detail: {
      tags: ['Contacts'],
      summary: 'Update contact scores',
      description: 'Manually update the 12D preference vector'
    }
  })

  // Bulk operations
  .post('/bulk', async ({ body }) => {
    try {
      const { contacts } = body;
      
      if (!Array.isArray(contacts) || contacts.length === 0) {
        return {
          success: false,
          error: 'Contacts array is required and cannot be empty'
        };
      }

      if (contacts.length > 100) {
        return {
          success: false,
          error: 'Maximum 100 contacts can be created at once'
        };
      }

      const createdContacts = [];
      const errors = [];

      for (const contactData of contacts) {
        try {
          // Basic email validation
          if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(contactData.email)) {
            errors.push({ email: contactData.email, error: 'Invalid email format' });
            continue;
          }

          // Generate scores automatically
          const scores = generateScoresFromContact(contactData);

          const contact = await prisma.contact.create({
            data: {
              ...contactData,
              scores
            }
          });

          createdContacts.push(contact);
        } catch (error) {
          errors.push({ email: contactData.email, error: error instanceof Error ? error.message : String(error) });
        }
      }

      return {
        success: true,
        data: {
          created: createdContacts,
          errors,
          summary: {
            total: contacts.length,
            created: createdContacts.length,
            failed: errors.length
          }
        },
        message: `Bulk operation completed. ${createdContacts.length} contacts created, ${errors.length} failed.`
      };
    } catch (error) {
      console.error('Bulk create contacts error:', error);
      return {
        success: false,
        error: 'Failed to create contacts in bulk'
      };
    }
  }, {
    body: t.Object({
      contacts: t.Array(t.Object({
        email: t.String({ minLength: 5 }),
        name: t.String({ minLength: 2 }),
        phone: t.Optional(t.String()),
        type: t.Union([t.Literal('BUYER'), t.Literal('TENANT'), t.Literal('INVESTOR')]),
        budgetMin: t.Optional(t.Number({ minimum: 0 })),
        budgetMax: t.Optional(t.Number({ minimum: 0 })),
        locationWilayas: t.Array(t.String()),
        locationCities: t.Array(t.String()),
        propertyTypes: t.Array(t.Union([
          t.Literal('APARTMENT'), t.Literal('VILLA'), t.Literal('HOUSE'),
          t.Literal('OFFICE'), t.Literal('SHOP'), t.Literal('WAREHOUSE'),
          t.Literal('LAND'), t.Literal('GARAGE')
        ])),
        transactionType: t.Union([t.Literal('RENT'), t.Literal('SALE')]),
        familySize: t.Optional(t.Number({ minimum: 1 })),
        hasChildren: t.Boolean(),
        minRooms: t.Optional(t.Number({ minimum: 1 })),
        maxRooms: t.Optional(t.Number({ minimum: 1 })),
        minArea: t.Optional(t.Number({ minimum: 1 })),
        maxArea: t.Optional(t.Number({ minimum: 1 })),
        furnishingType: t.Optional(t.Union([
          t.Literal('FURNISHED'), t.Literal('SEMI_FURNISHED'), t.Literal('UNFURNISHED')
        ])),
        preferredCondition: t.Optional(t.Union([
          t.Literal('POOR'), t.Literal('FAIR'), t.Literal('GOOD'), t.Literal('EXCELLENT'), t.Literal('NEW')
        ])),
        requiresParking: t.Boolean(),
        requiresSecurity: t.Boolean(),
        notes: t.Optional(t.String())
      }), { minItems: 1, maxItems: 100 })
    }),
    detail: {
      tags: ['Contacts'],
      summary: 'Bulk create contacts',
      description: 'Create multiple contacts at once with automatic AI scoring'
    }
  })

  // Export contacts
  .get('/export', async ({ query }) => {
    try {
      const { format = 'json', type, wilaya, transactionType } = query;

      // Build filters
      const where: any = { isActive: true };
      if (type) where.type = type;
      if (wilaya) where.locationWilayas = { has: wilaya };
      if (transactionType) where.transactionType = transactionType;

      const contacts = await prisma.contact.findMany({
        where,
        orderBy: { createdAt: 'desc' }
      });

      if (format === 'csv') {
        const csvHeaders = [
          'ID', 'Name', 'Email', 'Phone', 'Type', 'Budget Min', 'Budget Max',
          'Wilayas', 'Cities', 'Property Types', 'Transaction Type', 'Family Size',
          'Has Children', 'Min Rooms', 'Max Rooms', 'Min Area', 'Max Area',
          'Requires Parking', 'Requires Security', 'Created At'
        ];

        const csvRows = contacts.map(contact => [
          contact.id,
          contact.name,
          contact.email,
          contact.phone || '',
          contact.type,
          contact.budgetMin || '',
          contact.budgetMax || '',
          contact.locationWilayas.join(';'),
          contact.locationCities.join(';'),
          contact.propertyTypes.join(';'),
          contact.transactionType,
          contact.familySize || '',
          contact.hasChildren ? 'Yes' : 'No',
          contact.minRooms || '',
          contact.maxRooms || '',
          contact.minArea || '',
          contact.maxArea || '',
          contact.requiresParking ? 'Yes' : 'No',
          contact.requiresSecurity ? 'Yes' : 'No',
          contact.createdAt
        ]);

        const csvContent = [csvHeaders, ...csvRows]
          .map(row => row.map(field => `"${field}"`).join(','))
          .join('\n');

        return {
          success: true,
          data: {
            format: 'csv',
            content: csvContent,
            count: contacts.length,
            filename: `contacts_export_${new Date().toISOString().split('T')[0]}.csv`
          }
        };
      }

      return {
        success: true,
        data: {
          format: 'json',
          contacts,
          count: contacts.length,
          exportedAt: new Date().toISOString()
        }
      };
    } catch (error) {
      console.error('Export contacts error:', error);
      return {
        success: false,
        error: 'Failed to export contacts'
      };
    }
  }, {
    query: t.Object({
      format: t.Optional(t.Union([t.Literal('json'), t.Literal('csv')])),
      type: t.Optional(t.Union([t.Literal('BUYER'), t.Literal('TENANT'), t.Literal('INVESTOR')])),
      wilaya: t.Optional(t.String()),
      transactionType: t.Optional(t.Union([t.Literal('RENT'), t.Literal('SALE')]))
    }),
    detail: {
      tags: ['Contacts'],
      summary: 'Export contacts',
      description: 'Export contacts in JSON or CSV format with optional filtering'
    }
  })

  // Contact analytics
  .get('/analytics', async () => {
    try {
      const [
        totalContacts,
        contactsByType,
        contactsByWilaya,
        contactsByTransactionType,
        recentContacts,
        topWilayas
      ] = await Promise.all([
        prisma.contact.count({ where: { isActive: true } }),
        prisma.contact.groupBy({
          by: ['type'],
          _count: { type: true },
          where: { isActive: true }
        }),
        prisma.contact.groupBy({
          by: ['locationWilayas'],
          _count: { locationWilayas: true },
          where: { isActive: true }
        }),
        prisma.contact.groupBy({
          by: ['transactionType'],
          _count: { transactionType: true },
          where: { isActive: true }
        }),
        prisma.contact.findMany({
          where: { isActive: true },
          orderBy: { createdAt: 'desc' },
          take: 5,
          select: {
            id: true,
            name: true,
            type: true,
            createdAt: true
          }
        }),
        prisma.contact.findMany({
          where: { isActive: true },
          select: { locationWilayas: true }
        })
      ]);

      // Process wilaya data
      const wilayaCounts: { [key: string]: number } = {};
      contactsByWilaya.forEach(item => {
        item.locationWilayas.forEach((wilaya: string) => {
          wilayaCounts[wilaya] = (wilayaCounts[wilaya] || 0) + item._count.locationWilayas;
        });
      });

      const topWilayasList = Object.entries(wilayaCounts)
        .sort(([,a], [,b]) => b - a)
        .slice(0, 10)
        .map(([wilaya, count]) => ({ wilaya, count }));

      return {
        success: true,
        data: {
          overview: {
            totalContacts,
            activeContacts: totalContacts,
            inactiveContacts: await prisma.contact.count({ where: { isActive: false } })
          },
          distribution: {
            byType: contactsByType,
            byTransactionType: contactsByTransactionType,
            byWilaya: topWilayasList
          },
          recent: {
            newContacts: recentContacts,
            lastWeek: await prisma.contact.count({
              where: {
                isActive: true,
                createdAt: { gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) }
              }
            }),
            lastMonth: await prisma.contact.count({
              where: {
                isActive: true,
                createdAt: { gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) }
              }
            })
          }
        }
      };
    } catch (error) {
      console.error('Contact analytics error:', error);
      return {
        success: false,
        error: 'Failed to generate contact analytics'
      };
    }
  }, {
    detail: {
      tags: ['Contacts'],
      summary: 'Contact analytics and insights',
      description: 'Get comprehensive analytics about contacts including distribution and trends'
    }
  })

  // Vector-based contact search
  .post('/vector-search', async ({ body }) => {
    try {
      const {
        vector,
        minSimilarity = 0.3,
        limit = 10,
        // Optional traditional filters
        type,
        transactionType,
        transactionTypes,
        primaryTransactionType,
        wilaya,
        budgetMin,
        budgetMax,
        hasChildren,
        isActive = true
      } = body;

      // Validate vector
      if (!Array.isArray(vector) || vector.length !== 12) {
        return {
          success: false,
          error: 'Vector must be an array of 12 numbers'
        };
      }

      // Validate vector values
      if (!vector.every(v => typeof v === 'number' && v >= 0 && v <= 1)) {
        return {
          success: false,
          error: 'All vector values must be numbers between 0 and 1'
        };
      }

      const limitNum = Math.min(50, Math.max(1, Number(limit)));
      const minSim = Math.max(0, Math.min(1, Number(minSimilarity)));

      // Build optional filters
      const where: any = {};
      if (isActive !== undefined) where.isActive = Boolean(isActive);
      if (type) where.type = type;
      if (transactionType) where.transactionType = transactionType;
      if (primaryTransactionType) where.primaryTransactionType = primaryTransactionType;
      if (transactionTypes) {
        where.transactionTypes = { hasSome: Array.isArray(transactionTypes) ? transactionTypes : [transactionTypes] };
      }

      if (wilaya) {
        where.locationWilayas = { has: wilaya };
      }

      if (budgetMin || budgetMax) {
        where.AND = [];
        if (budgetMin) {
          where.AND.push({
            OR: [
              { budgetMin: { gte: Number(budgetMin) } },
              { budgetMin: null }
            ]
          });
        }
        if (budgetMax) {
          where.AND.push({
            OR: [
              { budgetMax: { lte: Number(budgetMax) } },
              { budgetMax: null }
            ]
          });
        }
      }

      if (hasChildren !== undefined) {
        where.hasChildren = Boolean(hasChildren);
      }

      // Get contacts with optional filters (get more for vector filtering)
      const contacts = await prisma.contact.findMany({
        where,
        take: limitNum * 5, // Get more to allow for similarity filtering
        orderBy: { createdAt: 'desc' },
        include: {
          sales: {
            select: { successScore: true }
          }
        }
      });

      // Calculate similarities and filter
      const results = contacts
        .map((contact: any) => {
          const similarity = calculateSimilarity(vector, contact.scores);
          
          // Calculate average success score for this contact
          const avgSuccessScore = contact.sales.length > 0
            ? contact.sales.reduce((sum: number, sale: any) => sum + sale.successScore, 0) / contact.sales.length
            : 0.5;

          return {
            contact: {
              id: contact.id,
              name: contact.name,
              email: contact.email,
              phone: contact.phone,
              type: contact.type,
              budgetMin: contact.budgetMin,
              budgetMax: contact.budgetMax,
              locationWilayas: contact.locationWilayas,
              transactionType: contact.transactionType,
              transactionTypes: contact.transactionTypes,
              primaryTransactionType: contact.primaryTransactionType,
              transactionFlexibility: contact.transactionFlexibility,
              familySize: contact.familySize,
              hasChildren: contact.hasChildren,
              isActive: contact.isActive,
              createdAt: contact.createdAt
            },
            similarity,
            avgSuccessScore,
            combinedScore: similarity * 0.8 + avgSuccessScore * 0.2,
            contactVector: contact.scores
          };
        })
        .filter((result: any) => result.similarity >= minSim)
        .sort((a: any, b: any) => b.combinedScore - a.combinedScore)
        .slice(0, limitNum)
        .map((result: any) => ({
          ...result.contact,
          similarity: Math.round(result.similarity * 1000) / 1000,
          combinedScore: Math.round(result.combinedScore * 1000) / 1000,
          matchExplanation: generateContactVectorMatchExplanation(vector, result.contactVector, result.similarity)
        }));

      return {
        success: true,
        data: results,
        metadata: {
          searchVector: vector,
          resultsFound: results.length,
          totalContactsScanned: contacts.length,
          minSimilarity: minSim,
          searchType: 'vector-similarity',
          algorithm: '12D Cosine Similarity with Success History'
        }
      };
    } catch (error) {
      console.error('Contact vector search error:', error);
      return {
        success: false,
        error: 'Failed to perform contact vector search'
      };
    }
  }, {
    body: t.Object({
      vector: t.Array(t.Number({ minimum: 0, maximum: 1 }), {
        minItems: 12,
        maxItems: 12,
        description: '12D preference vector: [budget, area, rooms, location, propertyType, condition, features, family, modern, investment, urgency, transaction]'
      }),
      minSimilarity: t.Optional(t.Number({ minimum: 0, maximum: 1, default: 0.3 })),
      limit: t.Optional(t.Number({ minimum: 1, maximum: 50, default: 10 })),
      // Optional traditional filters
      type: t.Optional(t.Union([
        t.Literal('BUYER'), t.Literal('TENANT'), t.Literal('INVESTOR')
      ])),
      transactionType: t.Optional(t.Union([t.Literal('RENT'), t.Literal('SALE')])),
      transactionTypes: t.Optional(t.Array(t.Union([t.Literal('RENT'), t.Literal('SALE')]))),
      primaryTransactionType: t.Optional(t.Union([t.Literal('RENT'), t.Literal('SALE')])),
      wilaya: t.Optional(t.String()),
      budgetMin: t.Optional(t.Number({ minimum: 0 })),
      budgetMax: t.Optional(t.Number({ minimum: 0 })),
      hasChildren: t.Optional(t.Boolean()),
      isActive: t.Optional(t.Boolean({ default: true }))
    }),
    detail: {
      tags: ['Contacts'],
      summary: 'Vector-based contact search',
      description: `
## AI-Powered Vector Contact Search

Search contacts using a 12-dimensional preference vector for intelligent matching.

### 🤖 Vector Format
\`\`\`json
{
  "vector": [0.69, 0.6, 0.8, 0.95, 0.6, 0.5, 0.65, 0.8, 0.5, 0.3, 0.5, 1.0]
}
\`\`\`

### 📊 Vector Dimensions (0.0-1.0)
0. **Budget**: Price level preference
1. **Area**: Size requirements 
2. **Rooms**: Room count preference
3. **Location**: Geographic desirability (Algeria-optimized)
4. **Property Type**: Villa, apartment, etc.
5. **Condition**: Property condition importance
6. **Features**: Amenities importance
7. **Family**: Family-friendliness needs
8. **Modern**: Modernity preference
9. **Investment**: Investment potential interest
10. **Urgency**: Decision timeline
11. **Transaction**: RENT (0.0) vs SALE (1.0)

### 🎯 Use Cases
- **Property Reverse Search**: Find contacts interested in a specific property profile
- **Market Analysis**: Identify potential buyers/tenants for property types
- **Lead Generation**: Find contacts with similar preferences to successful clients
- **Preference Matching**: Match contacts to property listing patterns

### 💡 Enhanced Features
- **Success History**: Combines vector similarity with past success scores
- **Transaction Flexibility**: Supports dual transaction type filtering
- **Cultural Factors**: Algeria-specific family and cultural preferences
- **Explainable Results**: Detailed match explanations

### 📝 Example Request
\`\`\`json
{
  "vector": [0.69, 0.6, 0.8, 0.95, 0.6, 0.5, 0.65, 0.8, 0.5, 0.3, 0.5, 1.0],
  "minSimilarity": 0.7,
  "limit": 20,
  "type": "BUYER",
  "wilaya": "Algiers",
  "isActive": true
}
\`\`\`

### 🔄 Combined Scoring
- **80%** Vector similarity (preference alignment)
- **20%** Success history (past performance)
      `
    }
  }); 

// Helper function to generate contact match explanation
function generateContactVectorMatchExplanation(searchVector: number[], contactVector: number[], similarity: number): string {
  const dimensions = [
    'Budget', 'Area', 'Rooms', 'Location', 'Property Type',
    'Condition', 'Features', 'Family', 'Modern', 'Investment', 'Urgency', 'Transaction'
  ];

  const strongMatches = [];
  const weakMatches = [];

  for (let i = 0; i < 12; i++) {
    const diff = Math.abs(searchVector[i] - contactVector[i]);
    if (diff < 0.2) {
      strongMatches.push(dimensions[i]);
    } else if (diff > 0.5) {
      weakMatches.push(dimensions[i]);
    }
  }

  let explanation = `${Math.round(similarity * 100)}% preference match. `;
  
  if (strongMatches.length > 0) {
    explanation += `Strong alignment: ${strongMatches.slice(0, 3).join(', ')}. `;
  }
  
  if (weakMatches.length > 0) {
    explanation += `Different preferences: ${weakMatches.slice(0, 2).join(', ')}.`;
  }

  return explanation.trim();
} 