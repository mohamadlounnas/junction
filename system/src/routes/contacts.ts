import { Elysia, t } from 'elysia';
import { prisma } from '../config/database';
import { generateScoresFromContact, validateScoreVector } from '../services/score-generator';

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

      if (budgetMinNum !== undefined || budgetMaxNum !== undefined) {
        where.AND = [];
        if (budgetMinNum !== undefined) where.AND.push({ budgetMin: { gte: budgetMinNum } });
        if (budgetMaxNum !== undefined) where.AND.push({ budgetMax: { lte: budgetMaxNum } });
      }

      // Get contacts and total count
      const [contacts, total] = await Promise.all([
        prisma.contact.findMany({
          where,
          skip,
          take: limitNum,
          orderBy: { createdAt: 'desc' }
        }),
        prisma.contact.count({ where })
      ]);

      return {
        success: true,
        data: contacts,
        pagination: {
          page: pageNum,
          limit: limitNum,
          total,
          pages: Math.ceil(total / limitNum)
        },
        filters: { type, search, wilaya, transactionType, budgetMin: budgetMinNum, budgetMax: budgetMaxNum, hasChildren: hasChildrenBool }
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
      ], { description: 'Filter by transaction preference' })),
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
      summary: 'List contacts with advanced filtering',
      description: `
## Get All Contacts with Filtering and Pagination

Retrieve contacts with comprehensive filtering options for efficient searching and browsing.

### 🔍 Filter Options
- **Type**: BUYER, TENANT, INVESTOR
- **Search**: Name and email text search
- **Location**: Filter by Algerian wilayas
- **Budget**: Min/max price range in DZD
- **Transaction**: RENT or SALE preference
- **Family**: Has children or not
- **Status**: Active/inactive contacts

### 📄 Pagination
- Default: 10 results per page
- Maximum: 50 results per page
- Returns total count and page info

### 🇩🇿 Algeria-Specific Features
- All 48 wilayas supported
- DZD currency ranges
- Cultural family preferences
      `,
      responses: {
        '200': {
          description: 'Successful response with filtered contacts',
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  success: { type: 'boolean', example: true },
                  data: {
                    type: 'array',
                    items: {
                      type: 'object',
                      properties: {
                        id: { type: 'string', example: 'cmd8bvuwy0009m5y8bqjlgepr' },
                        email: { type: 'string', example: 'ahmed.benali@email.dz' },
                        name: { type: 'string', example: 'Ahmed Benali' },
                        type: { type: 'string', example: 'BUYER' },
                        budgetMin: { type: 'number', example: 15000000 },
                        budgetMax: { type: 'number', example: 25000000 },
                        locationWilayas: { type: 'array', items: { type: 'string' }, example: ['Algiers', 'Boumerdès'] },
                        transactionType: { type: 'string', example: 'SALE' },
                        hasChildren: { type: 'boolean', example: true },
                        scores: { type: 'array', items: { type: 'number' }, example: [0.1, 0.1, 0.1, 0.95, 0.8, 0.7, 0.9, 0.8, 0.6, 0.5, 0.3, 1.0] }
                      }
                    }
                  },
                  pagination: {
                    type: 'object',
                    properties: {
                      page: { type: 'number', example: 1 },
                      limit: { type: 'number', example: 10 },
                      total: { type: 'number', example: 5 },
                      pages: { type: 'number', example: 1 }
                    }
                  },
                  filters: {
                    type: 'object',
                    example: { type: 'BUYER', wilaya: 'Algiers', budgetMin: 15000000 }
                  }
                }
              },
              examples: {
                'all_contacts': {
                  summary: 'All active contacts',
                  value: {
                    success: true,
                    data: [
                      {
                        id: 'cmd8bvuwy0009m5y8bqjlgepr',
                        email: 'ahmed.benali@email.dz',
                        name: 'Ahmed Benali',
                        type: 'BUYER',
                        budgetMin: 15000000,
                        budgetMax: 25000000,
                        locationWilayas: ['Algiers'],
                        transactionType: 'SALE',
                        hasChildren: true,
                        scores: [0.1, 0.1, 0.1, 0.95, 0.8, 0.7, 0.9, 0.8, 0.6, 0.5, 0.3, 1.0]
                      }
                    ],
                    pagination: { page: 1, limit: 10, total: 5, pages: 1 },
                    filters: {}
                  }
                },
                'filtered_buyers': {
                  summary: 'Buyers in Algiers',
                  value: {
                    success: true,
                    data: [
                      {
                        id: 'cmd8bvuwy0009m5y8bqjlgepr',
                        name: 'Ahmed Benali',
                        type: 'BUYER',
                        locationWilayas: ['Algiers'],
                        budgetMin: 15000000,
                        budgetMax: 25000000
                      }
                    ],
                    pagination: { page: 1, limit: 10, total: 2, pages: 1 },
                    filters: { type: 'BUYER', wilaya: 'Algiers' }
                  }
                }
              }
            }
          }
        },
        '400': {
          description: 'Bad request - invalid parameters',
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  success: { type: 'boolean', example: false },
                  error: { type: 'string', example: 'Invalid page number' }
                }
              }
            }
          }
        },
        '500': {
          description: 'Internal server error',
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  success: { type: 'boolean', example: false },
                  error: { type: 'string', example: 'Failed to fetch contacts' }
                }
              }
            }
          }
        }
      }
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

  // Create new contact
  .post('/', async ({ body, set }) => {
    try {
      // Basic email validation
      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(body.email)) {
        set.status = 400;
        return {
          success: false,
          error: 'Invalid email format',
          message: 'Please provide a valid email address'
        };
      }

      // Generate scores automatically
      const scores = generateScoresFromContact(body);

      const contact = await prisma.contact.create({
        data: {
          ...(body as any),
          scores
        }
      });

      return {
        success: true,
        data: contact,
        message: 'Contact created successfully'
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
    }),
    detail: {
      tags: ['Contacts'],
      summary: 'Create new contact with AI scoring',
      description: `
## Create New Contact with Automatic 12D Vector Generation

Creates a new contact and automatically generates a 12-dimensional preference vector for AI recommendations.

### 🤖 AI Features
- **Automatic Scoring**: Generates 12D vector from preferences
- **Algeria Optimization**: Considers cultural and geographic factors
- **Budget Normalization**: Converts DZD amounts to 0-1 scale
- **Location Scoring**: Optimized for 48 Algerian wilayas

### 📋 Required Fields
- **email**: Valid email address (validated)
- **name**: Full name (minimum 2 characters)
- **type**: BUYER, TENANT, or INVESTOR
- **transactionType**: RENT or SALE
- **hasChildren**: Family status (boolean)
- **requiresParking**: Parking preference (boolean)
- **requiresSecurity**: Security preference (boolean)

### 🎯 12D Vector Dimensions
The system automatically generates scores for:
1. **Budget** - Price preference level
2. **Area** - Size requirements  
3. **Rooms** - Room count preference
4. **Location** - Wilaya desirability
5. **Property Type** - Villa, apartment, etc.
6. **Condition** - Property condition preference
7. **Features** - Amenities importance
8. **Family** - Family-friendliness needs
9. **Modern** - Modernity preference
10. **Investment** - Investment potential interest
11. **Urgency** - Decision timeline
12. **Transaction** - RENT (0) or SALE (1)
      `,
      responses: {
        '200': {
          description: 'Contact created successfully with AI scores',
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  success: { type: 'boolean', example: true },
                  data: {
                    type: 'object',
                    properties: {
                      id: { type: 'string', example: 'cmd8bvuwy0009m5y8bqjlgepr' },
                      email: { type: 'string', example: 'ahmed.benali@email.dz' },
                      name: { type: 'string', example: 'Ahmed Benali' },
                      type: { type: 'string', example: 'BUYER' },
                      budgetMin: { type: 'number', example: 15000000 },
                      budgetMax: { type: 'number', example: 25000000 },
                      locationWilayas: { type: 'array', items: { type: 'string' }, example: ['Algiers'] },
                      propertyTypes: { type: 'array', items: { type: 'string' }, example: ['VILLA', 'APARTMENT'] },
                      transactionType: { type: 'string', example: 'SALE' },
                      hasChildren: { type: 'boolean', example: true },
                      requiresParking: { type: 'boolean', example: true },
                      requiresSecurity: { type: 'boolean', example: true },
                      scores: { 
                        type: 'array', 
                        items: { type: 'number', minimum: 0, maximum: 1 },
                        example: [0.38, 0.5, 0.5, 0.95, 0.8, 0.7, 0.9, 0.8, 0.6, 0.5, 0.3, 1.0],
                        description: '12D preference vector (Budget, Area, Rooms, Location, PropertyType, Condition, Features, Family, Modern, Investment, Urgency, Transaction)'
                      },
                      createdAt: { type: 'string', format: 'date-time', example: '2025-07-18T04:37:51.306Z' }
                    }
                  },
                  message: { type: 'string', example: 'Contact created successfully' }
                }
              },
              examples: {
                'algerian_buyer': {
                  summary: 'Algerian Family Buyer',
                  description: 'Successful creation of a family buyer looking for a villa in Algiers',
                  value: {
                    success: true,
                    data: {
                      id: 'cmd8bvuwy0009m5y8bqjlgepr',
                      email: 'ahmed.benali@email.dz',
                      name: 'Ahmed Benali',
                      phone: '+213 555 123 456',
                      type: 'BUYER',
                      budgetMin: 15000000,
                      budgetMax: 25000000,
                      locationWilayas: ['Algiers'],
                      locationCities: ['Hydra'],
                      propertyTypes: ['VILLA', 'APARTMENT'],
                      transactionType: 'SALE',
                      familySize: 4,
                      hasChildren: true,
                      requiresParking: true,
                      requiresSecurity: true,
                      scores: [0.38, 0.5, 0.5, 0.95, 0.8, 0.7, 0.9, 0.8, 0.6, 0.5, 0.3, 1.0],
                      isActive: true,
                      createdAt: '2025-07-18T04:37:51.306Z'
                    },
                    message: 'Contact created successfully'
                  }
                },
                'student_tenant': {
                  summary: 'Student Tenant',
                  description: 'Student looking for a rental apartment in Oran',
                  value: {
                    success: true,
                    data: {
                      id: 'cmd8bvuwy0009m5y8bqjlgepr',
                      email: 'sara.student@univ-oran.dz',
                      name: 'Sara Koui',
                      type: 'TENANT',
                      budgetMin: 20000,
                      budgetMax: 50000,
                      locationWilayas: ['Oran'],
                      propertyTypes: ['APARTMENT'],
                      transactionType: 'RENT',
                      hasChildren: false,
                      requiresParking: false,
                      requiresSecurity: true,
                      scores: [0.15, 0.2, 0.3, 0.85, 0.9, 0.5, 0.4, 0.1, 0.8, 0.2, 0.8, 0.0]
                    },
                    message: 'Contact created successfully'
                  }
                }
              }
            }
          }
        },
        '400': {
          description: 'Validation error - invalid input data',
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  success: { type: 'boolean', example: false },
                  error: { type: 'string', example: 'Invalid email format' },
                  message: { type: 'string', example: 'Please provide a valid email address' }
                }
              },
              examples: {
                'invalid_email': {
                  summary: 'Invalid Email Format',
                  value: {
                    success: false,
                    error: 'Invalid email format',
                    message: 'Please provide a valid email address'
                  }
                },
                'missing_required': {
                  summary: 'Missing Required Fields',
                  value: {
                    success: false,
                    error: 'Validation failed',
                    message: 'Missing required fields: name, type, transactionType'
                  }
                }
              }
            }
          }
        },
        '500': {
          description: 'Internal server error',
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  success: { type: 'boolean', example: false },
                  error: { type: 'string', example: 'Failed to create contact' }
                }
              }
            }
          }
        }
      }
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
  }); 