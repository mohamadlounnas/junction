import { Elysia, t } from 'elysia';
import { prisma } from '../config/database';
import { generateScoresFromProperty, validateScoreVector } from '../services/score-generator';
import { 
  generateRadiusQuery, 
  calculateDistance, 
  getLandmarkCoordinates,
  updatePropertyGeohash,
  isValidAlgeriaLocation,
  ALGERIA_LANDMARKS
} from '../services/geospatial';

export const propertiesRoutes = new Elysia({ prefix: '/properties' })
  // List properties with filtering and pagination
  .get('/', async ({ query }) => {
    try {
      const {
        page = 1,
        limit = 10,
        propertyType,
        transactionType,
        wilaya,
        city,
        priceMin,
        priceMax,
        areaMin,
        areaMax,
        rooms,
        condition,
        status = 'AVAILABLE',
        featured,
        search,
        // Geospatial search parameters
        latitude,
        longitude,
        radius,
        landmark,
        sortByDistance = false
      } = query;

      const pageNum = Math.max(1, Number(page));
      const limitNum = Math.min(50, Math.max(1, Number(limit)));
      const skip = (pageNum - 1) * limitNum;

      // Handle geospatial search
      let searchLat: number | undefined;
      let searchLon: number | undefined;
      let searchRadius: number | undefined;

      // Check for landmark-based search
      if (landmark) {
        const landmarkCoords = getLandmarkCoordinates(landmark);
        if (landmarkCoords) {
          searchLat = landmarkCoords.lat;
          searchLon = landmarkCoords.lon;
          searchRadius = radius ? Number(radius) : 5; // Default 5km radius
        }
      } else if (latitude && longitude) {
        searchLat = Number(latitude);
        searchLon = Number(longitude);
        searchRadius = radius ? Number(radius) : 5; // Default 5km radius
        
        // Validate coordinates are in Algeria
        if (!isValidAlgeriaLocation(searchLat, searchLon)) {
          return {
            success: false,
            error: 'Coordinates must be within Algeria'
          };
        }
      }

      // Build filters
      const where: any = {};
      
      if (propertyType) where.propertyType = propertyType;
      if (transactionType) where.transactionType = transactionType;
      if (wilaya) where.wilaya = wilaya;
      if (city) where.city = city;
      if (condition) where.condition = condition;
      if (status) where.status = status;
      if (featured !== undefined) where.featured = Boolean(featured);
      if (rooms) where.rooms = Number(rooms);

      if (search) {
        where.OR = [
          { title: { contains: search, mode: 'insensitive' } },
          { description: { contains: search, mode: 'insensitive' } },
          { address: { contains: search, mode: 'insensitive' } }
        ];
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

      // Add geospatial filtering if search coordinates provided
      if (searchLat && searchLon && searchRadius) {
        const radiusQuery = generateRadiusQuery(searchLat, searchLon, searchRadius);
        
        // Use geohash for efficient initial filtering based on precision
        if (radiusQuery.precision === 5) {
          where.geohashPrecision5 = { in: radiusQuery.geohashes };
        } else if (radiusQuery.precision === 6) {
          where.geohashPrecision6 = { in: radiusQuery.geohashes };
        } else if (radiusQuery.precision === 7) {
          where.geohashPrecision7 = { in: radiusQuery.geohashes };
        } else {
          where.geohash = { in: radiusQuery.geohashes };
        }
        
        // Also ensure we have valid coordinates for distance calculation
        where.latitude = { not: null };
        where.longitude = { not: null };
      }

      // Get properties and total count
      let properties: any[];
      let total: number;

      if (searchLat && searchLon && searchRadius) {
        // For radius search, get more results initially for distance filtering
        const initialLimit = Math.min(500, limitNum * 10);
        
        const [initialProperties, totalCount] = await Promise.all([
          prisma.property.findMany({
            where,
            take: initialLimit,
            orderBy: [
              { featured: 'desc' },
              { createdAt: 'desc' }
            ]
          }),
          prisma.property.count({ where })
        ]);

        // Calculate actual distances and filter by radius
        const propertiesWithDistance = initialProperties
          .map((property: any) => {
            if (!property.latitude || !property.longitude) return null;
            
            const distance = calculateDistance(
              searchLat!, searchLon!,
              property.latitude, property.longitude
            );
            
            return {
              ...property,
              distance: Math.round(distance * 100) / 100 // Round to 2 decimal places
            };
          })
          .filter((property: any) => property && property.distance <= searchRadius!)
          .sort((a: any, b: any) => {
            if (sortByDistance) {
              return a.distance - b.distance; // Sort by distance first
            } else {
              // Sort by featured first, then distance
              if (a.featured !== b.featured) return b.featured ? 1 : -1;
              return a.distance - b.distance;
            }
          });

        // Apply pagination to filtered results
        properties = propertiesWithDistance.slice(skip, skip + limitNum);
        total = propertiesWithDistance.length;
        
      } else {
        // Regular search without geospatial filtering
        [properties, total] = await Promise.all([
        prisma.property.findMany({
          where,
          skip,
          take: limitNum,
          orderBy: [
            { featured: 'desc' },
            { createdAt: 'desc' }
          ]
        }),
        prisma.property.count({ where })
      ]);
      }

      return {
        success: true,
        data: properties,
        pagination: {
          page: pageNum,
          limit: limitNum,
          total,
          pages: Math.ceil(total / limitNum)
        },
        filters: { 
          propertyType, transactionType, wilaya, city, 
          priceMin, priceMax, areaMin, areaMax, rooms, 
          condition, status, featured, search,
          latitude: searchLat, longitude: searchLon, radius: searchRadius, landmark
        },
        ...(searchLat && searchLon && {
          location: {
            searchCenter: { latitude: searchLat, longitude: searchLon },
            searchRadius: searchRadius,
            sortByDistance: Boolean(sortByDistance)
        }
        })
      };
    } catch (error) {
      console.error('Get properties error:', error);
      return {
        success: false,
        error: 'Failed to fetch properties'
      };
    }
  }, {
    detail: {
      tags: ['Properties'],
      summary: 'List properties with geospatial search',
      description: `
## Advanced Property Search with Location Intelligence

### 🌍 Standard Filtering
- Property type, price, area, wilaya, city
- Transaction type (rent/sale)
- Features and amenities

### 📍 Geospatial Search
- **Coordinate-based**: \`latitude=36.7538&longitude=3.0588&radius=5\`
- **Landmark-based**: \`landmark=algiers_center&radius=2\`
- **Distance sorting**: \`sortByDistance=true\`

### 🇩🇿 Algeria Landmarks
- \`algiers_center\`, \`houari_boumediene_airport\`
- \`oran_center\`, \`constantine_center\`
- \`university_algiers\`, \`hydra_algiers\`

### 🎯 Use Cases
- "Properties within 5km of my office"
- "Near Houari Boumediene Airport"
- "Walking distance to University of Algiers"
      `
    }
  })

  // Radius search endpoint
  .get('/radius/:landmark/:radius', async ({ params: { landmark, radius } }) => {
    try {
      const landmarkCoords = getLandmarkCoordinates(landmark);
      if (!landmarkCoords) {
        return {
          success: false,
          error: `Unknown landmark: ${landmark}. Available: ${Object.keys(ALGERIA_LANDMARKS).join(', ')}`
        };
      }

      const searchRadius = Number(radius);
      if (searchRadius <= 0 || searchRadius > 50) {
        return {
          success: false,
          error: 'Radius must be between 0.1 and 50 kilometers'
        };
      }

      const radiusQuery = generateRadiusQuery(landmarkCoords.lat, landmarkCoords.lon, searchRadius);
      
      // Use geohash for efficient search
      const where: any = {
        status: 'AVAILABLE',
        latitude: { not: null },
        longitude: { not: null }
      };
      
      // Add geohash filtering based on precision
      if (radiusQuery.precision === 5) {
        where.geohashPrecision5 = { in: radiusQuery.geohashes };
      } else if (radiusQuery.precision === 6) {
        where.geohashPrecision6 = { in: radiusQuery.geohashes };
      } else if (radiusQuery.precision === 7) {
        where.geohashPrecision7 = { in: radiusQuery.geohashes };
      } else {
        // Use main geohash field for other precisions
        where.geohash = { in: radiusQuery.geohashes };
      }

      const properties = await prisma.property.findMany({
        where,
        take: 100 // Limit for performance
      });

      // Calculate exact distances and filter
      const propertiesWithDistance = properties
        .map((property: any) => {
          if (!property.latitude || !property.longitude) return null;
          
          const distance = calculateDistance(
            landmarkCoords.lat, landmarkCoords.lon,
            property.latitude, property.longitude
          );
          
          return {
            ...property,
            distance: Math.round(distance * 100) / 100
          };
        })
        .filter((property: any) => property && property.distance <= searchRadius)
        .sort((a: any, b: any) => a.distance - b.distance);

      return {
        success: true,
        data: propertiesWithDistance,
        metadata: {
          landmark: landmarkCoords,
          searchRadius: searchRadius,
          resultsFound: propertiesWithDistance.length,
          searchType: 'radius',
          radiusUnit: 'kilometers'
        }
      };
    } catch (error) {
      console.error('Radius search error:', error);
      return {
        success: false,
        error: 'Failed to search properties by radius'
      };
    }
  }, {
    detail: {
      tags: ['Properties'],
      summary: 'Search properties by landmark and radius',
      description: `
## Landmark-Based Radius Search

Quick search for properties near famous Algeria landmarks.

### 🗺️ Available Landmarks
- **Algiers**: algiers_center, houari_boumediene_airport, university_algiers
- **Oran**: oran_center, oran_airport, university_oran  
- **Constantine**: constantine_center, constantine_airport
- **Business**: hydra_algiers, ben_aknoun, rouiba

### 📏 Radius Options
- 0.5km: Walking distance
- 2km: Cycling distance
- 5km: Short drive
- 10km: City area

### 📍 Example
\`GET /api/properties/radius/university_algiers/2\`
      `
    }
  })

  // Get property by ID
  .get('/:id', async ({ params: { id } }) => {
    try {
      const property = await prisma.property.findUnique({
        where: { id },
        include: {
          sales: {
            include: {
              contact: {
                select: { id: true, name: true, email: true, type: true }
              }
            }
          }
        }
      });

      if (!property) {
        return {
          success: false,
          error: 'Property not found'
        };
      }

      // Increment view count
      await prisma.property.update({
        where: { id },
        data: { viewCount: { increment: 1 } }
      });

      return {
        success: true,
        data: property
      };
    } catch (error) {
      console.error('Get property error:', error);
      return {
        success: false,
        error: 'Failed to fetch property'
      };
    }
  }, {
    detail: {
      tags: ['Properties'],
      summary: 'Get property by ID',
      description: 'Get a specific property with its sales history'
    }
  })

  // Create new property
  .post('/', async ({ body }) => {
    try {
      // Generate scores automatically
      const scores = generateScoresFromProperty(body);
      
      // Generate geohash data if coordinates provided
      const geohashData = updatePropertyGeohash(body);

      const property = await prisma.property.create({
        data: {
          ...(body as any),
          scores,
          ...geohashData
        }
      });

      return {
        success: true,
        data: property,
        message: 'Property created successfully'
      };
    } catch (error) {
      console.error('Create property error:', error);
      return {
        success: false,
        error: 'Failed to create property'
      };
    }
  }, {
    body: t.Object({
      title: t.String({ minLength: 5 }),
      description: t.Optional(t.String()),
      price: t.Number({ minimum: 0 }),
      area: t.Number({ minimum: 1 }),
      rooms: t.Number({ minimum: 0 }),
      bathrooms: t.Optional(t.Number({ minimum: 0 })),
      wilaya: t.String({ minLength: 2 }),
      city: t.String({ minLength: 2 }),
      address: t.Optional(t.String()),
      latitude: t.Optional(t.Number()),
      longitude: t.Optional(t.Number()),
      propertyType: t.Union([
        t.Literal('APARTMENT'), t.Literal('VILLA'), t.Literal('HOUSE'),
        t.Literal('OFFICE'), t.Literal('SHOP'), t.Literal('WAREHOUSE'),
        t.Literal('LAND'), t.Literal('GARAGE')
      ]),
      transactionType: t.Union([t.Literal('RENT'), t.Literal('SALE')]),
      furnishing: t.Union([
        t.Literal('FURNISHED'), t.Literal('SEMI_FURNISHED'), t.Literal('UNFURNISHED')
      ]),
      condition: t.Union([
        t.Literal('POOR'), t.Literal('FAIR'), t.Literal('GOOD'), t.Literal('EXCELLENT'), t.Literal('NEW')
      ]),
      hasParking: t.Boolean(),
      hasSecurity: t.Boolean(),
      hasElevator: t.Boolean(),
      hasGarden: t.Boolean(),
      hasBalcony: t.Boolean(),
      hasSwimmingPool: t.Boolean(),
      buildingAge: t.Optional(t.Number({ minimum: 0 })),
      floor: t.Optional(t.Number({ minimum: 0 })),
      totalFloors: t.Optional(t.Number({ minimum: 1 })),
      ownerId: t.Optional(t.String()),
      featured: t.Optional(t.Boolean())
    }),
    detail: {
      tags: ['Properties'],
      summary: 'Create property',
      description: 'Create a new property with automatic score generation'
    }
  })

  // Update property
  .put('/:id', async ({ params: { id }, body }) => {
    try {
      // Check if property exists
      const existingProperty = await prisma.property.findUnique({ where: { id } });
      if (!existingProperty) {
        return {
          success: false,
          error: 'Property not found'
        };
      }

      // Regenerate scores with updated data
      const updatedData = { ...existingProperty, ...(body as any) };
      const scores = generateScoresFromProperty(updatedData);

      const property = await prisma.property.update({
        where: { id },
        data: {
          ...(body as any),
          scores
        }
      });

      return {
        success: true,
        data: property,
        message: 'Property updated successfully'
      };
    } catch (error) {
      console.error('Update property error:', error);
      return {
        success: false,
        error: 'Failed to update property'
      };
    }
  }, {
    detail: {
      tags: ['Properties'],
      summary: 'Update property',
      description: 'Update property and regenerate scores'
    }
  })

  // Delete property
  .delete('/:id', async ({ params: { id } }) => {
    try {
      // Check if property exists
      const property = await prisma.property.findUnique({ where: { id } });
      if (!property) {
        return {
          success: false,
          error: 'Property not found'
        };
      }

      await prisma.property.delete({ where: { id } });

      return {
        success: true,
        message: 'Property deleted successfully'
      };
    } catch (error) {
      console.error('Delete property error:', error);
      return {
        success: false,
        error: 'Failed to delete property'
      };
    }
  }, {
    detail: {
      tags: ['Properties'],
      summary: 'Delete property',
      description: 'Delete a property permanently'
    }
  })

  // Get property scores
  .get('/:id/scores', async ({ params: { id } }) => {
    try {
      const property = await prisma.property.findUnique({
        where: { id },
        select: { id: true, title: true, scores: true }
      });

      if (!property) {
        return {
          success: false,
          error: 'Property not found'
        };
      }

      return {
        success: true,
        data: {
          propertyId: property.id,
          title: property.title,
          scores: property.scores,
          dimensions: [
            'Budget', 'Area', 'Rooms', 'Location', 'Property Type',
            'Condition', 'Features', 'Family', 'Modern', 'Investment', 'Urgency', 'Transaction'
          ]
        }
      };
    } catch (error) {
      console.error('Get property scores error:', error);
      return {
        success: false,
        error: 'Failed to fetch property scores'
      };
    }
  }, {
    detail: {
      tags: ['Properties'],
      summary: 'Get property scores',
      description: 'Get the 12D feature vector for a property'
    }
  })

  // Sync property scores (regenerate from data)
  .post('/:id/sync-scores', async ({ params: { id } }) => {
    try {
      const property = await prisma.property.findUnique({ where: { id } });
      if (!property) {
        return {
          success: false,
          error: 'Property not found'
        };
      }

      // Regenerate scores from current property data
      const scores = generateScoresFromProperty(property);

      const updatedProperty = await prisma.property.update({
        where: { id },
        data: { scores }
      });

      return {
        success: true,
        data: updatedProperty,
        message: 'Property scores synchronized successfully'
      };
    } catch (error) {
      console.error('Sync property scores error:', error);
      return {
        success: false,
        error: 'Failed to sync property scores'
      };
    }
  }, {
    detail: {
      tags: ['Properties'],
      summary: 'Sync property scores',
      description: 'Regenerate scores from current property data'
    }
  })

  // Bulk operations
  .post('/bulk', async ({ body }) => {
    try {
      const { properties } = body;
      
      if (!Array.isArray(properties) || properties.length === 0) {
        return {
          success: false,
          error: 'Properties array is required and cannot be empty'
        };
      }

      if (properties.length > 50) {
        return {
          success: false,
          error: 'Maximum 50 properties can be created at once'
        };
      }

      const createdProperties = [];
      const errors = [];

      for (const propertyData of properties) {
        try {
          // Generate scores automatically
          const scores = generateScoresFromProperty(propertyData);

          const property = await prisma.property.create({
            data: {
              ...propertyData,
              scores
            }
          });

          createdProperties.push(property);
        } catch (error) {
          errors.push({ title: propertyData.title, error: error instanceof Error ? error.message : String(error) });
        }
      }

      return {
        success: true,
        data: {
          created: createdProperties,
          errors,
          summary: {
            total: properties.length,
            created: createdProperties.length,
            failed: errors.length
          }
        },
        message: `Bulk operation completed. ${createdProperties.length} properties created, ${errors.length} failed.`
      };
    } catch (error) {
      console.error('Bulk create properties error:', error);
      return {
        success: false,
        error: 'Failed to create properties in bulk'
      };
    }
  }, {
    body: t.Object({
      properties: t.Array(t.Object({
        title: t.String({ minLength: 5 }),
        description: t.Optional(t.String()),
        price: t.Number({ minimum: 0 }),
        area: t.Number({ minimum: 1 }),
        rooms: t.Number({ minimum: 0 }),
        bathrooms: t.Optional(t.Number({ minimum: 0 })),
        wilaya: t.String({ minLength: 2 }),
        city: t.String({ minLength: 2 }),
        address: t.Optional(t.String()),
        latitude: t.Optional(t.Number()),
        longitude: t.Optional(t.Number()),
        propertyType: t.Union([
          t.Literal('APARTMENT'), t.Literal('VILLA'), t.Literal('HOUSE'),
          t.Literal('OFFICE'), t.Literal('SHOP'), t.Literal('WAREHOUSE'),
          t.Literal('LAND'), t.Literal('GARAGE')
        ]),
        transactionType: t.Union([t.Literal('RENT'), t.Literal('SALE')]),
        furnishing: t.Union([
          t.Literal('FURNISHED'), t.Literal('SEMI_FURNISHED'), t.Literal('UNFURNISHED')
        ]),
        condition: t.Union([
          t.Literal('POOR'), t.Literal('FAIR'), t.Literal('GOOD'), t.Literal('EXCELLENT'), t.Literal('NEW')
        ]),
        hasParking: t.Boolean(),
        hasSecurity: t.Boolean(),
        hasElevator: t.Boolean(),
        hasGarden: t.Boolean(),
        hasBalcony: t.Boolean(),
        hasSwimmingPool: t.Boolean(),
        buildingAge: t.Optional(t.Number({ minimum: 0 })),
        floor: t.Optional(t.Number({ minimum: 0 })),
        totalFloors: t.Optional(t.Number({ minimum: 1 })),
        ownerId: t.Optional(t.String()),
        featured: t.Optional(t.Boolean())
      }), { minItems: 1, maxItems: 50 })
    }),
    detail: {
      tags: ['Properties'],
      summary: 'Bulk create properties',
      description: 'Create multiple properties at once with automatic AI scoring'
    }
  })

  // Export properties
  .get('/export', async ({ query }) => {
    try {
      const { format = 'json', propertyType, wilaya, transactionType, status } = query;

      // Build filters
      const where: any = {};
      if (propertyType) where.propertyType = propertyType;
      if (wilaya) where.wilaya = wilaya;
      if (transactionType) where.transactionType = transactionType;
      if (status) where.status = status;

      const properties = await prisma.property.findMany({
        where,
        orderBy: { createdAt: 'desc' }
      });

      if (format === 'csv') {
        const csvHeaders = [
          'ID', 'Title', 'Description', 'Price', 'Area', 'Rooms', 'Bathrooms',
          'Wilaya', 'City', 'Address', 'Property Type', 'Transaction Type',
          'Furnishing', 'Condition', 'Has Parking', 'Has Security', 'Has Elevator',
          'Has Garden', 'Has Balcony', 'Has Swimming Pool', 'Building Age',
          'Floor', 'Total Floors', 'Status', 'Featured', 'Created At'
        ];

        const csvRows = properties.map(property => [
          property.id,
          property.title,
          property.description || '',
          property.price,
          property.area,
          property.rooms,
          property.bathrooms || '',
          property.wilaya,
          property.city,
          property.address || '',
          property.propertyType,
          property.transactionType,
          property.furnishing,
          property.condition,
          property.hasParking ? 'Yes' : 'No',
          property.hasSecurity ? 'Yes' : 'No',
          property.hasElevator ? 'Yes' : 'No',
          property.hasGarden ? 'Yes' : 'No',
          property.hasBalcony ? 'Yes' : 'No',
          property.hasSwimmingPool ? 'Yes' : 'No',
          property.buildingAge || '',
          property.floor || '',
          property.totalFloors || '',
          property.status,
          property.featured ? 'Yes' : 'No',
          property.createdAt
        ]);

        const csvContent = [csvHeaders, ...csvRows]
          .map(row => row.map(field => `"${field}"`).join(','))
          .join('\n');

        return {
          success: true,
          data: {
            format: 'csv',
            content: csvContent,
            count: properties.length,
            filename: `properties_export_${new Date().toISOString().split('T')[0]}.csv`
          }
        };
      }

      return {
        success: true,
        data: {
          format: 'json',
          properties,
          count: properties.length,
          exportedAt: new Date().toISOString()
        }
      };
    } catch (error) {
      console.error('Export properties error:', error);
      return {
        success: false,
        error: 'Failed to export properties'
      };
    }
  }, {
    query: t.Object({
      format: t.Optional(t.Union([t.Literal('json'), t.Literal('csv')])),
      propertyType: t.Optional(t.Union([
        t.Literal('APARTMENT'), t.Literal('VILLA'), t.Literal('HOUSE'),
        t.Literal('OFFICE'), t.Literal('SHOP'), t.Literal('WAREHOUSE'),
        t.Literal('LAND'), t.Literal('GARAGE')
      ])),
      wilaya: t.Optional(t.String()),
      transactionType: t.Optional(t.Union([t.Literal('RENT'), t.Literal('SALE')])),
      status: t.Optional(t.Union([t.Literal('AVAILABLE'), t.Literal('SOLD'), t.Literal('RENTED'), t.Literal('RESERVED')]))
    }),
    detail: {
      tags: ['Properties'],
      summary: 'Export properties',
      description: 'Export properties in JSON or CSV format with optional filtering'
    }
  })

  // Property analytics
  .get('/analytics', async () => {
    try {
      const [
        totalProperties,
        propertiesByType,
        propertiesByWilaya,
        propertiesByTransactionType,
        propertiesByStatus,
        recentProperties,
        priceStats
      ] = await Promise.all([
        prisma.property.count(),
        prisma.property.groupBy({
          by: ['propertyType'],
          _count: { propertyType: true }
        }),
        prisma.property.groupBy({
          by: ['wilaya'],
          _count: { wilaya: true }
        }),
        prisma.property.groupBy({
          by: ['transactionType'],
          _count: { transactionType: true }
        }),
        prisma.property.groupBy({
          by: ['status'],
          _count: { status: true }
        }),
        prisma.property.findMany({
          orderBy: { createdAt: 'desc' },
          take: 5,
          select: {
            id: true,
            title: true,
            propertyType: true,
            price: true,
            wilaya: true,
            createdAt: true
          }
        }),
        prisma.property.aggregate({
          _avg: { price: true },
          _min: { price: true },
          _max: { price: true },
          _count: { price: true }
        })
      ]);

      return {
        success: true,
        data: {
          overview: {
            totalProperties,
            availableProperties: await prisma.property.count({ where: { status: 'AVAILABLE' } }),
            soldProperties: await prisma.property.count({ where: { status: 'SOLD' } }),
            rentedProperties: await prisma.property.count({ where: { status: 'RENTED' } })
          },
          distribution: {
            byType: propertiesByType,
            byWilaya: propertiesByWilaya,
            byTransactionType: propertiesByTransactionType,
            byStatus: propertiesByStatus
          },
          pricing: {
            averagePrice: priceStats._avg.price,
            minPrice: priceStats._min.price,
            maxPrice: priceStats._max.price,
            totalProperties: priceStats._count.price
          },
          recent: {
            newProperties: recentProperties,
            lastWeek: await prisma.property.count({
              where: {
                createdAt: { gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) }
              }
            }),
            lastMonth: await prisma.property.count({
              where: {
                createdAt: { gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) }
              }
            })
          }
        }
      };
    } catch (error) {
      console.error('Property analytics error:', error);
      return {
        success: false,
        error: 'Failed to generate property analytics'
      };
    }
  }, {
    detail: {
      tags: ['Properties'],
      summary: 'Property analytics and insights',
      description: 'Get comprehensive analytics about properties including distribution, pricing, and trends'
    }
  })

  // Search properties with advanced filters
  .get('/search', async ({ query }) => {
    try {
      const {
        q,
        propertyType,
        transactionType,
        wilaya,
        city,
        priceMin,
        priceMax,
        areaMin,
        areaMax,
        rooms,
        hasParking,
        hasSecurity,
        hasElevator,
        hasGarden,
        hasBalcony,
        condition,
        furnishing,
        featured,
        page = 1,
        limit = 10,
        sortBy = 'createdAt',
        sortOrder = 'desc'
      } = query;

      const pageNum = Math.max(1, Number(page));
      const limitNum = Math.min(50, Math.max(1, Number(limit)));
      const skip = (pageNum - 1) * limitNum;

      // Build search filters
      const where: any = {};

      // Text search
      if (q) {
        where.OR = [
          { title: { contains: q, mode: 'insensitive' } },
          { description: { contains: q, mode: 'insensitive' } },
          { address: { contains: q, mode: 'insensitive' } }
        ];
      }

      // Property filters
      if (propertyType) where.propertyType = propertyType;
      if (transactionType) where.transactionType = transactionType;
      if (wilaya) where.wilaya = wilaya;
      if (city) where.city = { contains: city, mode: 'insensitive' };
      if (condition) where.condition = condition;
      if (furnishing) where.furnishing = furnishing;
      if (featured !== undefined) where.featured = featured === 'true';

      // Numeric filters
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

      if (rooms) where.rooms = Number(rooms);

      // Boolean filters
      if (hasParking !== undefined) where.hasParking = hasParking === 'true';
      if (hasSecurity !== undefined) where.hasSecurity = hasSecurity === 'true';
      if (hasElevator !== undefined) where.hasElevator = hasElevator === 'true';
      if (hasGarden !== undefined) where.hasGarden = hasGarden === 'true';
      if (hasBalcony !== undefined) where.hasBalcony = hasBalcony === 'true';

      // Sort options
      const orderBy: any = {};
      orderBy[sortBy] = sortOrder;

      const [properties, total] = await Promise.all([
        prisma.property.findMany({
          where,
          skip,
          take: limitNum,
          orderBy
        }),
        prisma.property.count({ where })
      ]);

      return {
        success: true,
        data: properties,
        pagination: {
          page: pageNum,
          limit: limitNum,
          total,
          pages: Math.ceil(total / limitNum)
        },
        search: {
          query: q,
          filters: {
            propertyType,
            transactionType,
            wilaya,
            city,
            priceMin,
            priceMax,
            areaMin,
            areaMax,
            rooms,
            hasParking,
            hasSecurity,
            hasElevator,
            hasGarden,
            hasBalcony,
            condition,
            furnishing,
            featured
          },
          sortBy,
          sortOrder
        }
      };
    } catch (error) {
      console.error('Search properties error:', error);
      return {
        success: false,
        error: 'Failed to search properties'
      };
    }
  }, {
    query: t.Object({
      q: t.Optional(t.String({ description: 'Search query for title, description, or address' })),
      propertyType: t.Optional(t.Union([
        t.Literal('APARTMENT'), t.Literal('VILLA'), t.Literal('HOUSE'),
        t.Literal('OFFICE'), t.Literal('SHOP'), t.Literal('WAREHOUSE'),
        t.Literal('LAND'), t.Literal('GARAGE')
      ])),
      transactionType: t.Optional(t.Union([t.Literal('RENT'), t.Literal('SALE')])),
      wilaya: t.Optional(t.String()),
      city: t.Optional(t.String()),
      priceMin: t.Optional(t.Union([t.Number(), t.String()])),
      priceMax: t.Optional(t.Union([t.Number(), t.String()])),
      areaMin: t.Optional(t.Union([t.Number(), t.String()])),
      areaMax: t.Optional(t.Union([t.Number(), t.String()])),
      rooms: t.Optional(t.Union([t.Number(), t.String()])),
      hasParking: t.Optional(t.Union([t.Boolean(), t.String()])),
      hasSecurity: t.Optional(t.Union([t.Boolean(), t.String()])),
      hasElevator: t.Optional(t.Union([t.Boolean(), t.String()])),
      hasGarden: t.Optional(t.Union([t.Boolean(), t.String()])),
      hasBalcony: t.Optional(t.Union([t.Boolean(), t.String()])),
      condition: t.Optional(t.Union([
        t.Literal('POOR'), t.Literal('FAIR'), t.Literal('GOOD'), t.Literal('EXCELLENT'), t.Literal('NEW')
      ])),
      furnishing: t.Optional(t.Union([
        t.Literal('FURNISHED'), t.Literal('SEMI_FURNISHED'), t.Literal('UNFURNISHED')
      ])),
      featured: t.Optional(t.Union([t.Boolean(), t.String()])),
      page: t.Optional(t.Union([t.Number(), t.String()])),
      limit: t.Optional(t.Union([t.Number(), t.String()])),
      sortBy: t.Optional(t.Union([
        t.Literal('createdAt'), t.Literal('price'), t.Literal('area'), t.Literal('title')
      ])),
      sortOrder: t.Optional(t.Union([t.Literal('asc'), t.Literal('desc')]))
    }),
    detail: {
      tags: ['Properties'],
      summary: 'Advanced property search',
      description: 'Search properties with comprehensive filtering and sorting options'
    }
  }); 