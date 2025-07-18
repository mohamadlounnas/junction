// Smart Contact API - Elysia Backend
//
// This backend is powered by Elysia.js and Prisma ORM.
//
// OpenAPI (Swagger) documentation is enabled via the @elysiajs/swagger plugin.
// Access the interactive API docs at: http://localhost:3001/swagger
//
// All endpoints are documented automatically.
//

import { Elysia, t } from 'elysia';
import { cors } from '@elysiajs/cors';
import { swagger } from '@elysiajs/swagger';
import { PrismaClient, UserType, PropertyType, FurnishingType, ConditionType, TransactionType, PropertyStatus } from '../generated/prisma';
import { adminSettingsController } from './controllers/admin-settings';
import settingsService from './services/settings';
import redis from './services/redis';
import algerianVectorGenerator from './services/vector-generator';

const app = new Elysia();
const prisma = new PrismaClient();

// Calculate cosine similarity between two vectors
function cosineSimilarity(vectorA: number[], vectorB: number[]): number {
  if (vectorA.length !== vectorB.length) {
    throw new Error('Vectors must have the same length');
  }
  
  let dotProduct = 0;
  let normA = 0;
  let normB = 0;
  
  for (let i = 0; i < vectorA.length; i++) {
    dotProduct += vectorA[i] * vectorB[i];
    normA += vectorA[i] * vectorA[i];
    normB += vectorB[i] * vectorB[i];
  }
  
  normA = Math.sqrt(normA);
  normB = Math.sqrt(normB);
  
  if (normA === 0 || normB === 0) {
    return 0;
  }
  
  return dotProduct / (normA * normB);
}

// Generate property score vector based on actual data
function generatePropertyScoreVector(
  price: number,
  area: number,
  rooms: number,
  location: string,
  propertyType: PropertyType,
  furnishing: FurnishingType,
  condition: ConditionType,
  transactionType: TransactionType
): number[] {
  // Normalize price (assuming range 2000-41000)
  const normalizedPrice = Math.min(Math.max((price - 2000) / (41000 - 2000), 0), 1);
  
  // Normalize area (assuming range 20-500)
  const normalizedArea = Math.min(Math.max((area - 20) / (500 - 20), 0), 1);
  
  // Normalize rooms (assuming max 5 rooms)
  const normalizedRooms = Math.min(rooms / 5, 1);
  
  // Location encoding (simple hash-based)
  const locationHash = location.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0);
  const normalizedLocation = (locationHash % 100) / 100;
  
  // Property type encoding
  const propertyTypeEncoding = {
    [PropertyType.APARTMENT]: 0.2,
    [PropertyType.VILLA]: 0.8,
    [PropertyType.OFFICE]: 0.5,
    [PropertyType.LAND]: 0.1
  };
  
  // Furnishing encoding
  const furnishingEncoding = {
    [FurnishingType.FURNISHED]: 1.0,
    [FurnishingType.SEMI_FURNISHED]: 0.5,
    [FurnishingType.UNFURNISHED]: 0.0
  };
  
  // Condition encoding
  const conditionEncoding = {
    [ConditionType.POOR]: 0.0,
    [ConditionType.FAIR]: 0.3,
    [ConditionType.GOOD]: 0.7,
    [ConditionType.EXCELLENT]: 1.0
  };
  
  // Transaction type encoding
  const transactionTypeEncoding = {
    [TransactionType.RENT]: 0.0,
    [TransactionType.SALE]: 1.0
  };
  
  return [
    normalizedPrice,
    normalizedArea,
    normalizedRooms,
    normalizedLocation,
    propertyTypeEncoding[propertyType],
    furnishingEncoding[furnishing],
    conditionEncoding[condition],
    transactionTypeEncoding[transactionType]
  ];
}

// Validation schemas
const UserCreateSchema = t.Object({
  email: t.String({ format: 'email' }),
  name: t.String({ minLength: 2, maxLength: 100 }),
  phone: t.Optional(t.String({ pattern: '^\\+?[0-9\\s-]+$' })),
  userType: t.Union([t.Literal('BUYER'), t.Literal('TENANT'), t.Literal('AGENT')]),
  scoreVector: t.Optional(t.Array(t.Number(), { minItems: 12, maxItems: 12 })),
  // Algeria-specific preference fields
  budget: t.Optional(t.Number()),
  preferredLocation: t.Optional(t.String()),
  roomsNeeded: t.Optional(t.Number()),
  familySize: t.Optional(t.Number()),
  hasChildren: t.Optional(t.Boolean()),
  workLocation: t.Optional(t.String()),
  transportNeeded: t.Optional(t.Boolean()),
  isFirstTimeBuyer: t.Optional(t.Boolean())
});

const UserUpdateSchema = t.Object({
  email: t.Optional(t.String({ format: 'email' })),
  name: t.Optional(t.String({ minLength: 2, maxLength: 100 })),
  phone: t.Optional(t.String({ pattern: '^\\+?[0-9\\s-]+$' })),
  userType: t.Optional(t.Union([t.Literal('BUYER'), t.Literal('TENANT'), t.Literal('AGENT')])),
  scoreVector: t.Optional(t.Array(t.Number(), { minItems: 12, maxItems: 12 }))
});

const PropertyCreateSchema = t.Object({
  title: t.String({ minLength: 5, maxLength: 200 }),
  description: t.Optional(t.String({ maxLength: 1000 })),
  price: t.Number({ minimum: 0 }),
  area: t.Number({ minimum: 1 }),
  rooms: t.Number({ minimum: 1, maximum: 10 }),
  location: t.String({ minLength: 2, maxLength: 100 }),
  propertyType: t.Union([t.Literal('APARTMENT'), t.Literal('VILLA'), t.Literal('OFFICE'), t.Literal('LAND')]),
  furnishing: t.Union([t.Literal('FURNISHED'), t.Literal('UNFURNISHED'), t.Literal('SEMI_FURNISHED')]),
  condition: t.Union([t.Literal('POOR'), t.Literal('FAIR'), t.Literal('GOOD'), t.Literal('EXCELLENT')]),
  transactionType: t.Union([t.Literal('RENT'), t.Literal('SALE')]),
  agentId: t.Optional(t.String()),
  isResidentialComplex: t.Optional(t.Boolean()),
  hasParking: t.Optional(t.Boolean()),
  hasSecurity: t.Optional(t.Boolean()),
  // Algeria-specific location features
  hasElevator: t.Optional(t.Boolean()),
  nearMosque: t.Optional(t.Boolean()),
  nearSchool: t.Optional(t.Boolean()),
  nearTransport: t.Optional(t.Boolean())
});

const PropertyUpdateSchema = t.Object({
  title: t.Optional(t.String({ minLength: 5, maxLength: 200 })),
  description: t.Optional(t.String({ maxLength: 1000 })),
  price: t.Optional(t.Number({ minimum: 0 })),
  area: t.Optional(t.Number({ minimum: 1 })),
  rooms: t.Optional(t.Number({ minimum: 1, maximum: 10 })),
  location: t.Optional(t.String({ minLength: 2, maxLength: 100 })),
  propertyType: t.Optional(t.Union([t.Literal('APARTMENT'), t.Literal('VILLA'), t.Literal('OFFICE'), t.Literal('LAND')])),
  furnishing: t.Optional(t.Union([t.Literal('FURNISHED'), t.Literal('UNFURNISHED'), t.Literal('SEMI_FURNISHED')])),
  condition: t.Optional(t.Union([t.Literal('POOR'), t.Literal('FAIR'), t.Literal('GOOD'), t.Literal('EXCELLENT')])),
  transactionType: t.Optional(t.Union([t.Literal('RENT'), t.Literal('SALE')])),
  agentId: t.Optional(t.String()),
  status: t.Optional(t.Union([t.Literal('ACTIVE'), t.Literal('INACTIVE'), t.Literal('SOLD')])),
  isResidentialComplex: t.Optional(t.Boolean()),
  hasParking: t.Optional(t.Boolean()),
  hasSecurity: t.Optional(t.Boolean())
});

// Create Elysia app with CORS and Swagger
const server = new Elysia()
  .use(cors())
  .use(swagger({
    documentation: {
      info: {
        title: 'Smart Contact API',
        version: '1.0.0',
        description: 'AI-powered real estate recommendation system API with OpenAPI documentation.'
      }
    },
    path: '/swagger'
  }))
  .onError(({ code, error, set }) => {
    switch (code) {
      case 'VALIDATION':
        set.status = 400;
        return {
          success: false,
          error: 'Validation failed',
          details: error.message
        };
      case 'NOT_FOUND':
        set.status = 404;
        return {
          success: false,
          error: 'Resource not found'
        };
      default:
        set.status = 500;
        return {
          success: false,
          error: 'Internal server error'
        };
    }
  });

// Health check
server.get('/api/health', () => ({
  success: true,
  message: 'Smart Contact API is running',
  timestamp: new Date().toISOString()
}));

// Users API
server.group('/api/users', app => app
  // Get all users with pagination and filters
  .get('/', ({ query }) => {
    const { 
      page = 1, 
      limit = 10, 
      userType, 
      search,
      // Score-based search parameters
      similarityVector,
      minSimilarity = 0.3,
      scoreIndex,
      scoreMin,
      scoreMax
    } = query;
    
    const skip = (Number(page) - 1) * Number(limit);
    
    const where: any = {};
    
    if (userType) {
      where.userType = userType;
    }
    
    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { email: { contains: search, mode: 'insensitive' } }
      ];
    }
    
    // Score range filtering will be applied after fetching data
    
    return prisma.user.findMany({
      where,
      select: {
        id: true,
        email: true,
        name: true,
        phone: true,
        userType: true,
        scoreVector: true,
        createdAt: true,
        updatedAt: true
      },
      skip,
      take: Number(limit),
      orderBy: { createdAt: 'desc' }
    }).then(async (users) => {
      let filteredUsers = users;
      let total = await prisma.user.count({ where });
      
      // Apply score-based filtering if scoreIndex is provided
      if (scoreIndex !== undefined && (scoreMin !== undefined || scoreMax !== undefined)) {
        const scoreIndexNum = Number(scoreIndex);
        if (scoreIndexNum >= 0 && scoreIndexNum < 12) {
          filteredUsers = filteredUsers.filter(user => {
            const score = user.scoreVector[scoreIndexNum];
            if (scoreMin !== undefined && scoreMax !== undefined) {
              return score >= Number(scoreMin) && score <= Number(scoreMax);
            } else if (scoreMin !== undefined) {
              return score >= Number(scoreMin);
            } else if (scoreMax !== undefined) {
              return score <= Number(scoreMax);
            }
            return true;
          });
          
          // Recalculate total for pagination
          const allUsers = await prisma.user.findMany({ where });
          const allFilteredUsers = allUsers.filter(user => {
            const score = user.scoreVector[scoreIndexNum];
            if (scoreMin !== undefined && scoreMax !== undefined) {
              return score >= Number(scoreMin) && score <= Number(scoreMax);
            } else if (scoreMin !== undefined) {
              return score >= Number(scoreMin);
            } else if (scoreMax !== undefined) {
              return score <= Number(scoreMax);
            }
            return true;
          });
          
          total = allFilteredUsers.length;
        }
      }
      
      // Apply similarity filtering if similarityVector is provided
      if (similarityVector) {
        try {
          const targetVector = JSON.parse(similarityVector as string);
          if (Array.isArray(targetVector) && targetVector.length === 12) {
            // Calculate similarity for each user and filter
            filteredUsers = filteredUsers
              .map(user => ({
                ...user,
                similarity: cosineSimilarity(targetVector, user.scoreVector)
              }))
              .filter(user => user.similarity >= Number(minSimilarity))
              .sort((a, b) => b.similarity - a.similarity);
            
            // Recalculate total for pagination
            const allUsers = await prisma.user.findMany({ where });
            const allFilteredUsers = allUsers
              .map(user => ({
                ...user,
                similarity: cosineSimilarity(targetVector, user.scoreVector)
              }))
              .filter(user => user.similarity >= Number(minSimilarity));
            
            total = allFilteredUsers.length;
          }
        } catch (error) {
          console.error('Error parsing similarity vector:', error);
        }
      }
      
      return {
        success: true,
        data: filteredUsers,
        pagination: {
          page: Number(page),
          limit: Number(limit),
          total,
          pages: Math.ceil(total / Number(limit))
        },
        filters: {
          userType,
          search,
          similarityVector: similarityVector ? 'provided' : undefined,
          minSimilarity: similarityVector ? Number(minSimilarity) : undefined,
          scoreIndex: scoreIndex ? Number(scoreIndex) : undefined,
          scoreMin: scoreMin ? Number(scoreMin) : undefined,
          scoreMax: scoreMax ? Number(scoreMax) : undefined
        }
      };
    });
  }, {
    query: t.Object({
      page: t.Optional(t.String()),
      limit: t.Optional(t.String()),
      userType: t.Optional(t.Union([t.Literal('BUYER'), t.Literal('TENANT'), t.Literal('AGENT')])),
      search: t.Optional(t.String()),
      // Score-based search parameters
      similarityVector: t.Optional(t.String()),
      minSimilarity: t.Optional(t.String()),
      scoreIndex: t.Optional(t.String()),
      scoreMin: t.Optional(t.String()),
      scoreMax: t.Optional(t.String())
    })
  })

  // Get user by ID
  .get('/:id', ({ params: { id } }) => {
    return prisma.user.findUnique({
      where: { id },
      include: {
        properties: {
          select: {
            id: true,
            title: true,
            location: true,
            price: true,
            status: true
          }
        }
      }
    }).then(user => {
      if (!user) {
        throw new Error('User not found');
      }
      
      return {
        success: true,
        data: user
      };
    });
  }, {
    params: t.Object({
      id: t.String()
    })
  })

  // Create new user
  .post('/', async ({ body }) => {
    const scoreVector = body.scoreVector || await algerianVectorGenerator.generateUserVector({
      userType: body.userType,
      budget: body.budget,
      preferredLocation: body.preferredLocation,
      roomsNeeded: body.roomsNeeded,
      familySize: body.familySize,
      hasChildren: body.hasChildren,
      workLocation: body.workLocation,
      transportNeeded: body.transportNeeded,
      isFirstTimeBuyer: body.isFirstTimeBuyer
    });
    
    return prisma.user.create({
      data: {
        email: body.email,
        name: body.name,
        phone: body.phone,
        userType: body.userType,
        scoreVector
      },
      select: {
        id: true,
        email: true,
        name: true,
        phone: true,
        userType: true,
        scoreVector: true,
        createdAt: true,
        updatedAt: true
      }
    }).then(user => ({
      success: true,
      data: user,
      message: 'User created successfully'
    }));
  }, {
    body: UserCreateSchema
  })

  // Update user
  .put('/:id', ({ params: { id }, body }) => {
    return prisma.user.update({
      where: { id },
      data: body,
      select: {
        id: true,
        email: true,
        name: true,
        phone: true,
        userType: true,
        scoreVector: true,
        createdAt: true,
        updatedAt: true
      }
    }).then(user => ({
      success: true,
      data: user,
      message: 'User updated successfully'
    }));
  }, {
    params: t.Object({
      id: t.String()
    }),
    body: UserUpdateSchema
  })

  // Delete user
  .delete('/:id', ({ params: { id } }) => {
    return prisma.user.delete({
      where: { id }
    }).then(() => ({
      success: true,
      message: 'User deleted successfully'
    }));
  }, {
    params: t.Object({
      id: t.String()
    })
  })

  // Get user score vector
  .get('/:id/score', ({ params: { id } }) => {
    return prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        name: true,
        scoreVector: true
      }
    }).then(user => {
      if (!user) {
        throw new Error('User not found');
      }
      
      return {
        success: true,
        data: {
          userId: user.id,
          userName: user.name,
          scoreVector: user.scoreVector
        }
      };
    });
  }, {
    params: t.Object({
      id: t.String()
    })
  })

  // Update user score vector
  .put('/:id/score', ({ params: { id }, body }) => {
    return prisma.user.update({
      where: { id },
      data: {
        scoreVector: body.scoreVector
      },
      select: {
        id: true,
        name: true,
        scoreVector: true,
        updatedAt: true
      }
    }).then(user => ({
      success: true,
      data: {
        userId: user.id,
        userName: user.name,
        scoreVector: user.scoreVector,
        updatedAt: user.updatedAt
      },
      message: 'User score updated successfully'
    }));
  }, {
    params: t.Object({
      id: t.String()
    }),
    body: t.Object({
      scoreVector: t.Array(t.Number(), { minItems: 12, maxItems: 12 })
    })
  })
);

// Properties API
server.group('/api/properties', app => app
  // Get all properties with pagination and filters
  .get('/', ({ query }) => {
    const { 
      page = 1, 
      limit = 10, 
      location, 
      propertyType, 
      transactionType, 
      priceMin, 
      priceMax,
      areaMin,
      areaMax,
      rooms,
      furnishing,
      condition,
      status,
      search
    } = query;
    
    const skip = (Number(page) - 1) * Number(limit);
    
    const where: any = {};
    
    if (location) {
      where.location = { contains: location, mode: 'insensitive' };
    }
    
    if (propertyType) {
      where.propertyType = propertyType;
    }
    
    if (transactionType) {
      where.transactionType = transactionType;
    }
    
    if (priceMin || priceMax) {
      where.price = {};
      if (priceMin) where.price.gte = Number(priceMin);
      if (priceMax) where.price.lte = Number(priceMax);
    }
    
    if (areaMin || areaMax) {
      where.area = {};
      if (areaMin) where.area.gte = Number(areaMin);
      if (areaMax) where.area.lte = Number(areaMax);
    }
    
    if (rooms) {
      where.rooms = Number(rooms);
    }
    
    if (furnishing) {
      where.furnishing = furnishing;
    }
    
    if (condition) {
      where.condition = condition;
    }
    
    if (status) {
      where.status = status;
    }
    
    if (search) {
      where.OR = [
        { title: { contains: search, mode: 'insensitive' } },
        { description: { contains: search, mode: 'insensitive' } },
        { location: { contains: search, mode: 'insensitive' } }
      ];
    }
    
    return prisma.property.findMany({
      where,
      include: {
        agent: {
          select: {
            id: true,
            name: true,
            email: true
          }
        }
      },
      skip,
      take: Number(limit),
      orderBy: { createdAt: 'desc' }
    }).then(async (properties) => {
      const total = await prisma.property.count({ where });
      
      return {
        success: true,
        data: properties,
        pagination: {
          page: Number(page),
          limit: Number(limit),
          total,
          pages: Math.ceil(total / Number(limit))
        }
      };
    });
  }, {
    query: t.Object({
      page: t.Optional(t.String()),
      limit: t.Optional(t.String()),
      location: t.Optional(t.String()),
      propertyType: t.Optional(t.Union([t.Literal('APARTMENT'), t.Literal('VILLA'), t.Literal('OFFICE'), t.Literal('LAND')])),
      transactionType: t.Optional(t.Union([t.Literal('RENT'), t.Literal('SALE')])),
      priceMin: t.Optional(t.String()),
      priceMax: t.Optional(t.String()),
      areaMin: t.Optional(t.String()),
      areaMax: t.Optional(t.String()),
      rooms: t.Optional(t.String()),
      furnishing: t.Optional(t.Union([t.Literal('FURNISHED'), t.Literal('UNFURNISHED'), t.Literal('SEMI_FURNISHED')])),
      condition: t.Optional(t.Union([t.Literal('POOR'), t.Literal('FAIR'), t.Literal('GOOD'), t.Literal('EXCELLENT')])),
      status: t.Optional(t.Union([t.Literal('ACTIVE'), t.Literal('INACTIVE'), t.Literal('SOLD')])),
      search: t.Optional(t.String())
    })
  })

  // Get property by ID
  .get('/:id', ({ params: { id } }) => {
    return prisma.property.findUnique({
      where: { id },
      include: {
        agent: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true
          }
        }
      }
    }).then(property => {
      if (!property) {
        throw new Error('Property not found');
      }
      
      return {
        success: true,
        data: property
      };
    });
  }, {
    params: t.Object({
      id: t.String()
    })
  })

  // Create new property
  .post('/', ({ body }) => {
    const scoreVector = algerianVectorGenerator.generatePropertyVector({
      price: body.price,
      area: body.area,
      rooms: body.rooms,
      location: body.location,
      propertyType: body.propertyType,
      furnishing: body.furnishing,
      condition: body.condition,
      transactionType: body.transactionType,
      hasParking: body.hasParking,
      hasSecurity: body.hasSecurity,
      hasElevator: body.hasElevator || false,
      nearMosque: body.nearMosque || false,
      nearSchool: body.nearSchool || false,
      nearTransport: body.nearTransport || false
    });
    
    return prisma.property.create({
      data: {
        title: body.title,
        description: body.description,
        price: body.price,
        area: body.area,
        rooms: body.rooms,
        location: body.location,
        propertyType: body.propertyType,
        furnishing: body.furnishing,
        condition: body.condition,
        transactionType: body.transactionType,
        scoreVector,
        agentId: body.agentId,
        isResidentialComplex: body.isResidentialComplex || false,
        hasParking: body.hasParking || false,
        hasSecurity: body.hasSecurity || false
      },
      include: {
        agent: {
          select: {
            id: true,
            name: true,
            email: true
          }
        }
      }
    }).then(property => ({
      success: true,
      data: property,
      message: 'Property created successfully'
    }));
  }, {
    body: PropertyCreateSchema
  })

  // Update property
  .put('/:id', ({ params: { id }, body }) => {
    // If any property features changed, recalculate score vector
    const needsScoreUpdate = body.price !== undefined || 
                            body.area !== undefined || 
                            body.rooms !== undefined || 
                            body.location !== undefined || 
                            body.propertyType !== undefined || 
                            body.furnishing !== undefined || 
                            body.condition !== undefined || 
                            body.transactionType !== undefined;
    
    if (needsScoreUpdate) {
      // Get current property to calculate new score
      return prisma.property.findUnique({
        where: { id }
      }).then(async (currentProperty) => {
        if (!currentProperty) {
          throw new Error('Property not found');
        }
        
        const updatedData = {
          ...body,
          scoreVector: algerianVectorGenerator.generatePropertyVector({
            price: body.price ?? currentProperty.price,
            area: body.area ?? currentProperty.area,
            rooms: body.rooms ?? currentProperty.rooms,
            location: body.location ?? currentProperty.location,
            propertyType: body.propertyType ?? currentProperty.propertyType,
            furnishing: body.furnishing ?? currentProperty.furnishing,
            condition: body.condition ?? currentProperty.condition,
            transactionType: body.transactionType ?? currentProperty.transactionType,
            hasParking: body.hasParking ?? currentProperty.hasParking,
            hasSecurity: body.hasSecurity ?? currentProperty.hasSecurity,
            hasElevator: false, // Default for existing properties
            nearMosque: false,  // Default for existing properties
            nearSchool: false,  // Default for existing properties
            nearTransport: false // Default for existing properties
          })
        };
        
        return prisma.property.update({
          where: { id },
          data: updatedData,
          include: {
            agent: {
              select: {
                id: true,
                name: true,
                email: true
              }
            }
          }
        }).then(property => ({
          success: true,
          data: property,
          message: 'Property updated successfully (score recalculated)'
        }));
      });
    } else {
      // No score update needed
      return prisma.property.update({
        where: { id },
        data: body,
        include: {
          agent: {
            select: {
              id: true,
              name: true,
              email: true
            }
          }
        }
      }).then(property => ({
        success: true,
        data: property,
        message: 'Property updated successfully'
      }));
    }
  }, {
    params: t.Object({
      id: t.String()
    }),
    body: PropertyUpdateSchema
  })

  // Delete property
  .delete('/:id', ({ params: { id } }) => {
    return prisma.property.delete({
      where: { id }
    }).then(() => ({
      success: true,
      message: 'Property deleted successfully'
    }));
  }, {
    params: t.Object({
      id: t.String()
    })
  })

  // Get property score vector
  .get('/:id/score', ({ params: { id } }) => {
    return prisma.property.findUnique({
      where: { id },
      select: {
        id: true,
        title: true,
        scoreVector: true
      }
    }).then(property => {
      if (!property) {
        throw new Error('Property not found');
      }
      
      return {
        success: true,
        data: {
          propertyId: property.id,
          propertyTitle: property.title,
          scoreVector: property.scoreVector
        }
      };
    });
  }, {
    params: t.Object({
      id: t.String()
    })
  })

  // Sync property score (recalculate)
  .post('/:id/sync-score', ({ params: { id } }) => {
    return prisma.property.findUnique({
      where: { id }
    }).then(async (property) => {
      if (!property) {
        throw new Error('Property not found');
      }
      
      const newScoreVector = algerianVectorGenerator.generatePropertyVector({
        price: property.price,
        area: property.area,
        rooms: property.rooms,
        location: property.location,
        propertyType: property.propertyType,
        furnishing: property.furnishing,
        condition: property.condition,
        transactionType: property.transactionType,
        hasParking: property.hasParking,
        hasSecurity: property.hasSecurity,
        hasElevator: false, // Default for existing properties
        nearMosque: false,  // Default for existing properties
        nearSchool: false,  // Default for existing properties
        nearTransport: false // Default for existing properties
      });
      
      return prisma.property.update({
        where: { id },
        data: {
          scoreVector: newScoreVector
        },
        select: {
          id: true,
          title: true,
          scoreVector: true,
          updatedAt: true
        }
      }).then(updatedProperty => ({
        success: true,
        data: {
          propertyId: updatedProperty.id,
          propertyTitle: updatedProperty.title,
          scoreVector: updatedProperty.scoreVector,
          updatedAt: updatedProperty.updatedAt
        },
        message: 'Property score synchronized successfully'
      }));
    });
  }, {
    params: t.Object({
      id: t.String()
    })
  })
);

// Recommendations API
server.group('/api/recommendations', app => app
  // Get property recommendations for a user
  .get('/user/:id', ({ params: { id }, query }) => {
    const { limit = 10, minScore = 0.3, ...filters } = query;
    
    return prisma.user.findUnique({
      where: { id }
    }).then(async (user) => {
      if (!user) {
        throw new Error('User not found');
      }
      
      // Build property filters
      const where: any = {
        status: 'ACTIVE'
      };
      
      if (filters.location) {
        where.location = { contains: filters.location, mode: 'insensitive' };
      }
      
      if (filters.propertyType) {
        where.propertyType = filters.propertyType;
      }
      
      if (filters.transactionType) {
        where.transactionType = filters.transactionType;
      }
      
      if (filters.priceMin || filters.priceMax) {
        where.price = {};
        if (filters.priceMin) where.price.gte = Number(filters.priceMin);
        if (filters.priceMax) where.price.lte = Number(filters.priceMax);
      }
      
      if (filters.areaMin || filters.areaMax) {
        where.area = {};
        if (filters.areaMin) where.area.gte = Number(filters.areaMin);
        if (filters.areaMax) where.area.lte = Number(filters.areaMax);
      }
      
      if (filters.rooms) {
        where.rooms = Number(filters.rooms);
      }
      
      if (filters.furnishing) {
        where.furnishing = filters.furnishing;
      }
      
      if (filters.condition) {
        where.condition = filters.condition;
      }
      
      const properties = await prisma.property.findMany({
        where,
        include: {
          agent: {
            select: {
              id: true,
              name: true,
              email: true
            }
          }
        }
      });
      
      // Calculate similarities
      const recommendations = properties.map(property => {
        const similarity = cosineSimilarity(user.scoreVector, property.scoreVector);
        return {
          property,
          similarity
        };
      });
      
      // Filter by minimum score and sort
      const filteredRecommendations = recommendations
        .filter(rec => rec.similarity >= Number(minScore))
        .sort((a, b) => b.similarity - a.similarity)
        .slice(0, Number(limit));
      
      return {
        success: true,
        data: filteredRecommendations,
        user: {
          id: user.id,
          name: user.name,
          userType: user.userType
        },
        filters: Object.keys(filters).length > 0 ? filters : null
      };
    });
  }, {
    params: t.Object({
      id: t.String()
    }),
    query: t.Object({
      limit: t.Optional(t.String()),
      minScore: t.Optional(t.String()),
      location: t.Optional(t.String()),
      propertyType: t.Optional(t.Union([t.Literal('APARTMENT'), t.Literal('VILLA'), t.Literal('OFFICE'), t.Literal('LAND')])),
      transactionType: t.Optional(t.Union([t.Literal('RENT'), t.Literal('SALE')])),
      priceMin: t.Optional(t.String()),
      priceMax: t.Optional(t.String()),
      areaMin: t.Optional(t.String()),
      areaMax: t.Optional(t.String()),
      rooms: t.Optional(t.String()),
      furnishing: t.Optional(t.Union([t.Literal('FURNISHED'), t.Literal('UNFURNISHED'), t.Literal('SEMI_FURNISHED')])),
      condition: t.Optional(t.Union([t.Literal('POOR'), t.Literal('FAIR'), t.Literal('GOOD'), t.Literal('EXCELLENT')]))
    })
  })

  // Get user recommendations for a property
  .get('/property/:id', ({ params: { id }, query }) => {
    const { limit = 10, minScore = 0.3, userType } = query;
    
    return prisma.property.findUnique({
      where: { id }
    }).then(async (property) => {
      if (!property) {
        throw new Error('Property not found');
      }
      
      const where: any = {};
      
      if (userType) {
        where.userType = userType;
      } else {
        // Default to buyers and tenants
        where.userType = {
          in: ['BUYER', 'TENANT']
        };
      }
      
      const users = await prisma.user.findMany({
        where,
        select: {
          id: true,
          name: true,
          email: true,
          userType: true,
          scoreVector: true
        }
      });
      
      // Calculate similarities
      const recommendations = users.map(user => {
        const similarity = cosineSimilarity(property.scoreVector, user.scoreVector);
        return {
          user: {
            id: user.id,
            name: user.name,
            email: user.email,
            userType: user.userType
          },
          similarity
        };
      });
      
      // Filter by minimum score and sort
      const filteredRecommendations = recommendations
        .filter(rec => rec.similarity >= Number(minScore))
        .sort((a, b) => b.similarity - a.similarity)
        .slice(0, Number(limit));
      
      return {
        success: true,
        data: filteredRecommendations,
        property: {
          id: property.id,
          title: property.title,
          location: property.location
        }
      };
    });
  }, {
    params: t.Object({
      id: t.String()
    }),
    query: t.Object({
      limit: t.Optional(t.String()),
      minScore: t.Optional(t.String()),
      userType: t.Optional(t.Union([t.Literal('BUYER'), t.Literal('TENANT'), t.Literal('AGENT')]))
    })
  })
);

// Statistics API
server.get('/api/stats', async () => {
  const userStats = await prisma.user.groupBy({
    by: ['userType'],
    _count: true
  });
  
  const propertyStats = await prisma.property.groupBy({
    by: ['transactionType'],
    _count: true
  });
  
  const totalUsers = await prisma.user.count();
  const totalProperties = await prisma.property.count();
  
  return {
    success: true,
    data: {
      users: {
        total: totalUsers,
        byType: userStats
      },
      properties: {
        total: totalProperties,
        byTransactionType: propertyStats
      }
    }
  };
});

// Admin Settings API
server.use(adminSettingsController);

// Initialize settings and start server
const PORT = process.env.PORT || 3001;

// Initialize default settings and start server
async function initializeServer() {
  try {
    console.log('🔄 Initializing default settings...');
    await settingsService.initializeDefaults();
    console.log('✅ Default settings initialized');
    
    console.log('🔄 Testing Redis connection...');
    await redis.set('test', 'connection', 60);
    const testValue = await redis.get('test');
    if (testValue === 'connection') {
      console.log('✅ Redis connection successful');
    } else {
      console.log('⚠️ Redis connection test failed');
    }
    
    server.listen(PORT, () => {
      console.log(`🚀 Smart Contact API server running on port ${PORT}`);
      console.log(`📊 Health check: http://localhost:${PORT}/api/health`);
      console.log(`👥 Users: http://localhost:${PORT}/api/users`);
      console.log(`🏠 Properties: http://localhost:${PORT}/api/properties`);
      console.log(`📈 Stats: http://localhost:${PORT}/api/stats`);
      console.log(`⚙️ Admin Settings: http://localhost:${PORT}/api/admin/settings`);
      console.log(`📚 Swagger Docs: http://localhost:${PORT}/swagger`);
    });
  } catch (error) {
    console.error('❌ Server initialization failed:', error);
    process.exit(1);
  }
}

initializeServer();

export default server; 