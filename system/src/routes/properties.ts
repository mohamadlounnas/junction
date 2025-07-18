import { Elysia, t } from 'elysia';
import { prisma } from '../config/database';
import { generateScoresFromProperty, validateScoreVector, calculateSimilarity } from '../services/score-generator';
import { 
  generateRadiusQuery, 
  calculateDistance, 
  getLandmarkCoordinates,
  updatePropertyGeohash,
  isValidAlgeriaLocation,
  ALGERIA_LANDMARKS
} from '../services/geospatial';
import { existsSync } from 'fs';
import { mkdir, writeFile } from 'fs/promises';
import path from 'path';
import { randomUUID } from 'crypto';

// Helper function to handle file upload
async function saveUploadedFile(file: File): Promise<string> {
  try {
    // Ensure uploads directory exists
    const uploadsDir = path.join(process.cwd(), 'uploads');
    if (!existsSync(uploadsDir)) {
      await mkdir(uploadsDir, { recursive: true });
    }

    // Generate unique filename
    const fileExtension = path.extname(file.name);
    const fileName = `${randomUUID()}${fileExtension}`;
    const filePath = path.join(uploadsDir, fileName);

    // Save file
    const buffer = await file.arrayBuffer();
    await writeFile(filePath, new Uint8Array(buffer));

    // Return URL
    return `/uploads/${fileName}`;
  } catch (error) {
    console.error('File upload error:', error);
    throw new Error('Failed to save uploaded file');
  }
}

// Helper function to handle multiple files
async function saveUploadedFiles(files: File[]): Promise<string[]> {
  const urls: string[] = [];
  for (const file of files) {
    const url = await saveUploadedFile(file);
    urls.push(url);
  }
  return urls;
}

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
      let imageUrl: string | undefined;
      let imageUrls: string[] = [];

      // Handle image_url or imageFile
      if ((body as any).imageFile) {
        imageUrl = await saveUploadedFile((body as any).imageFile);
      } else if ((body as any).image_url) {
        imageUrl = (body as any).image_url;
      }

      // Handle images array (can be URLs or files)
      if ((body as any).imageFiles && Array.isArray((body as any).imageFiles)) {
        imageUrls = await saveUploadedFiles((body as any).imageFiles);
      } else if ((body as any).images && Array.isArray((body as any).images)) {
        imageUrls = (body as any).images;
      }

      // Create property data without file fields
      const propertyData = { ...(body as any) };
      delete propertyData.imageFile;
      delete propertyData.imageFiles;
      
      // Add processed image data
      if (imageUrl) propertyData.image_url = imageUrl;
      if (imageUrls.length > 0) propertyData.images = imageUrls;

      // Generate scores automatically
      const scores = generateScoresFromProperty(propertyData);
      
      // Generate geohash data if coordinates provided
      const geohashData = updatePropertyGeohash(propertyData);

      const property = await prisma.property.create({
        data: {
          ...propertyData,
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
      image_url: t.Optional(t.String({ description: 'Direct image URL' })),
      images: t.Optional(t.Array(t.String(), { description: 'Array of image URLs' })),
      imageFile: t.Optional(t.File({ description: 'Single image file to upload' })),
      imageFiles: t.Optional(t.Array(t.File(), { description: 'Multiple image files to upload' })),
      ownerId: t.Optional(t.String()),
      featured: t.Optional(t.Boolean())
    }),
    detail: {
      tags: ['Properties'],
      summary: 'Create property with image upload support',
      description: `
## Create Property with Images

Create a new property with automatic AI scoring and optional image uploads.

### 🖼️ Image Upload Options
- **Direct URL**: Use \`image_url\` field for single image
- **URL Array**: Use \`images\` field for multiple image URLs  
- **File Upload**: Use \`imageFile\` for single file upload
- **Multiple Files**: Use \`imageFiles\` for multiple file uploads

### 📝 Examples

**With Direct Image URL:**
\`\`\`json
{
  "title": "Beautiful Villa in Algiers",
  "price": 25000000,
  "area": 200,
  "rooms": 4,
  "wilaya": "Algiers",
  "city": "Hydra",
  "image_url": "https://example.com/villa.jpg"
}
\`\`\`

**With Multiple Image URLs:**
\`\`\`json
{
  "title": "Modern Apartment",
  "price": 15000000,
  "area": 120,
  "rooms": 3,
  "wilaya": "Algiers", 
  "city": "Bab Ezzouar",
  "images": ["https://example.com/apt1.jpg", "https://example.com/apt2.jpg"]
}
\`\`\`

### 📤 File Upload
Use \`multipart/form-data\` for file uploads with \`imageFile\` or \`imageFiles\` fields.

### ✨ Features
- **Auto AI Scoring**: 12D vector generated automatically
- **Geospatial Index**: Location-based search optimization
- **Image Processing**: Secure upload with UUID naming
- **URL Generation**: Automatic image URL generation
      `,
      responses: {
        '200': {
          description: 'Property created successfully with images',
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  success: { type: 'boolean', example: true },
                  data: {
                    type: 'object',
                    properties: {
                      id: { type: 'string', example: 'cuid123...' },
                      title: { type: 'string', example: 'Beautiful Villa in Algiers' },
                      image_url: { type: 'string', example: '/uploads/uuid-image.jpg' },
                      images: { 
                        type: 'array', 
                        items: { type: 'string' },
                        example: ['/uploads/uuid-img1.jpg', '/uploads/uuid-img2.jpg']
                      }
                    }
                  },
                  message: { type: 'string', example: 'Property created successfully' }
                }
              }
            }
          }
        }
      }
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
        image_url: t.Optional(t.String()),
        images: t.Optional(t.Array(t.String())),
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
  })

  // Vector-based property search
  .post('/vector-search', async ({ body }) => {
    try {
      const {
        vector,
        minSimilarity = 0.3,
        limit = 10,
        // Optional traditional filters
        propertyType,
        transactionType,
        wilaya,
        city,
        priceMin,
        priceMax,
        areaMin,
        areaMax,
        status = 'AVAILABLE'
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
      if (status) where.status = status;
      if (propertyType) where.propertyType = propertyType;
      if (transactionType) where.transactionType = transactionType;
      if (wilaya) where.wilaya = wilaya;
      if (city) where.city = city;

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

      // Get properties with optional filters (get more for vector filtering)
      const properties = await prisma.property.findMany({
        where,
        take: limitNum * 5, // Get more to allow for similarity filtering
        orderBy: { createdAt: 'desc' }
      });

      // Calculate similarities and filter
      const results = properties
        .map((property: any) => ({
          property: {
            id: property.id,
            title: property.title,
            description: property.description,
            price: property.price,
            area: property.area,
            rooms: property.rooms,
            wilaya: property.wilaya,
            city: property.city,
            propertyType: property.propertyType,
            transactionType: property.transactionType,
            condition: property.condition,
            hasParking: property.hasParking,
            hasSecurity: property.hasSecurity,
            featured: property.featured,
            createdAt: property.createdAt
          },
          similarity: calculateSimilarity(vector, property.scores),
          propertyVector: property.scores
        }))
        .filter((result: any) => result.similarity >= minSim)
        .sort((a: any, b: any) => b.similarity - a.similarity)
        .slice(0, limitNum)
        .map((result: any) => ({
          ...result.property,
          similarity: Math.round(result.similarity * 1000) / 1000,
          matchExplanation: generateVectorMatchExplanation(vector, result.propertyVector, result.similarity)
        }));

      return {
        success: true,
        data: results,
        metadata: {
          searchVector: vector,
          resultsFound: results.length,
          totalPropertiesScanned: properties.length,
          minSimilarity: minSim,
          searchType: 'vector-similarity',
          algorithm: '12D Cosine Similarity'
        }
      };
    } catch (error) {
      console.error('Vector search error:', error);
      return {
        success: false,
        error: 'Failed to perform vector search'
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
      propertyType: t.Optional(t.Union([
        t.Literal('APARTMENT'), t.Literal('VILLA'), t.Literal('HOUSE'),
        t.Literal('OFFICE'), t.Literal('SHOP'), t.Literal('WAREHOUSE'),
        t.Literal('LAND'), t.Literal('GARAGE')
      ])),
      transactionType: t.Optional(t.Union([t.Literal('RENT'), t.Literal('SALE')])),
      wilaya: t.Optional(t.String()),
      city: t.Optional(t.String()),
      priceMin: t.Optional(t.Number({ minimum: 0 })),
      priceMax: t.Optional(t.Number({ minimum: 0 })),
      areaMin: t.Optional(t.Number({ minimum: 0 })),
      areaMax: t.Optional(t.Number({ minimum: 0 })),
      status: t.Optional(t.Union([
        t.Literal('AVAILABLE'), t.Literal('SOLD'), t.Literal('RENTED'), t.Literal('RESERVED')
      ]))
    }),
    detail: {
      tags: ['Properties'],
      summary: 'Vector-based property search',
      description: `
## AI-Powered Vector Property Search

Search properties using a 12-dimensional preference vector for intelligent matching.

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
- **AI Assistant Integration**: Convert user preferences to vector
- **Similarity Search**: Find properties matching a preference profile
- **Recommendation Testing**: Test vectors before creating contacts
- **Preference Analysis**: Understand what makes properties similar

### 💡 Advantages
- **Semantic Matching**: Goes beyond keyword filtering
- **Cultural Awareness**: Algeria-optimized scoring
- **Flexible Filtering**: Combine vector search with traditional filters
- **Explainable AI**: Get similarity scores and explanations

### 📝 Example Request
\`\`\`json
{
  "vector": [0.69, 0.6, 0.8, 0.95, 0.6, 0.5, 0.65, 0.8, 0.5, 0.3, 0.5, 1.0],
  "minSimilarity": 0.7,
  "limit": 20,
  "wilaya": "Algiers",
  "transactionType": "SALE"
}
\`\`\`
      `
    }
  })

  // Property Comparison Endpoint - PROFESSIONAL VERSION
  .post('/compare', async ({ body }) => {
    try {
      const { property1Id, property2Id, contactId } = body;

      if (!property1Id || !property2Id) {
        return {
          success: false,
          error: 'Both property1Id and property2Id are required'
        };
      }

      if (property1Id === property2Id) {
        return {
          success: false,
          error: 'Cannot compare property with itself'
        };
      }

      // Use the new professional comparison system
      const { generateProfessionalComparison } = await import('../services/market-analysis');
      const professionalComparison = await generateProfessionalComparison(property1Id, property2Id, contactId);

      return {
        success: true,
        comparison: {
          property1: {
            id: professionalComparison.property1.id,
            title: professionalComparison.property1.title,
            price: professionalComparison.property1.price,
            area: professionalComparison.property1.area,
            rooms: professionalComparison.property1.rooms,
            wilaya: professionalComparison.property1.wilaya,
            city: professionalComparison.property1.city,
            condition: professionalComparison.property1.condition,
            propertyType: professionalComparison.property1.propertyType,
            transactionType: professionalComparison.property1.transactionType,
            marketAnalysis: professionalComparison.property1.analysis
          },
          property2: {
            id: professionalComparison.property2.id,
            title: professionalComparison.property2.title,
            price: professionalComparison.property2.price,
            area: professionalComparison.property2.area,
            rooms: professionalComparison.property2.rooms,
            wilaya: professionalComparison.property2.wilaya,
            city: professionalComparison.property2.city,
            condition: professionalComparison.property2.condition,
            propertyType: professionalComparison.property2.propertyType,
            transactionType: professionalComparison.property2.transactionType,
            marketAnalysis: professionalComparison.property2.analysis
          },
          
          // Professional Analysis Sections
          executiveSummary: professionalComparison.comparison.executiveSummary,
          
          financialAnalysis: professionalComparison.comparison.financialAnalysis,
          
          investmentAnalysis: professionalComparison.comparison.investmentAnalysis,
          
          locationAnalysis: professionalComparison.comparison.locationAnalysis,
          
          marketAnalysis: professionalComparison.comparison.marketAnalysis,
          
          riskAssessment: professionalComparison.comparison.riskAssessment,
          
          professionalRecommendation: professionalComparison.comparison.professionalRecommendation,
          
          // Generate comprehensive recommendation text
          overallRecommendation: generateComprehensiveRecommendation(professionalComparison),
          
          // Metadata
          generatedAt: new Date(),
          analysisType: 'PROFESSIONAL',
          confidenceLevel: professionalComparison.comparison.professionalRecommendation.confidenceLevel
        }
      };

    } catch (error) {
      console.error('Professional property comparison error:', error);
      return {
        success: false,
        error: 'Failed to generate professional property comparison'
      };
    }
  }, {
    body: t.Object({
      property1Id: t.String(),
      property2Id: t.String(),
      contactId: t.Optional(t.String())
    }),
    detail: {
      tags: ['Properties'],
      summary: 'Professional Property Comparison Analysis',
      description: `
## 🏆 Professional Property Comparison System

**Advanced market analysis and investment intelligence for professional real estate agents**

This endpoint provides comprehensive property comparison with professional-grade analytics including market intelligence, investment analysis, location scoring, and strategic recommendations.

### 🎯 Professional Features

#### **📊 Market Intelligence**
- **Price Analysis**: Current pricing vs market averages with positioning analysis
- **Market Trends**: Historical price movements and future forecasts
- **Comparable Sales**: Recent transactions with similarity scoring
- **Supply/Demand**: Market conditions and negotiation leverage assessment

#### **💰 Investment Analysis**
- **ROI Calculations**: Expected return on investment with multi-year projections
- **Rental Yield**: Current rental market analysis and income potential
- **Appreciation Forecasts**: 1, 3, and 5-year value projections
- **Investment Grading**: Professional A+ to D rating system
- **Total Cost Analysis**: Complete ownership cost including fees and taxes

#### **📍 Location Intelligence**
- **Neighborhood Scoring**: Comprehensive location factor analysis
- **Amenity Assessment**: Schools, healthcare, transport, safety scoring
- **Ranking Analysis**: Top 10%, 25%, 50% neighborhood classifications
- **Future Development**: Infrastructure and growth potential

#### **⚖️ Risk Assessment**
- **Market Risk Factors**: Identified risks and mitigation strategies
- **Liquidity Analysis**: Resale potential and market conditions
- **Investment Risk Grading**: Professional risk assessment
- **Opportunity Identification**: Market opportunities and advantages

#### **🎯 Strategic Recommendations**
- **Investment Strategy**: Buy/hold/pass recommendations with reasoning
- **Negotiation Strategy**: Leverage analysis and pricing recommendations
- **Action Plan**: Step-by-step implementation guidance
- **Priority Scoring**: Confidence levels and decision matrices

### 🇩🇿 Algeria Market Expertise

#### **Local Market Intelligence**
- **48 Wilayas Coverage**: Complete Algeria market data
- **DZD Pricing Analysis**: Local currency with inflation adjustments
- **Regional Variations**: Wilaya-specific growth rates and trends
- **Cultural Factors**: Family preferences and local market dynamics

#### **Professional Standards**
- **Real Estate Law Compliance**: Algerian regulations and requirements
- **Market Benchmarking**: Against regional and national averages
- **Professional Terminology**: Industry-standard language and metrics
- **Documentation Standards**: Suitable for client presentations

### 📋 Analysis Sections

#### **1. Executive Summary**
- Key advantages of each property
- Primary recommendation drivers
- Critical decision factors

#### **2. Financial Comparison**
- Price per square meter analysis
- Total cost of ownership
- Market positioning assessment
- Value-for-money calculations

#### **3. Investment Analysis**
- Expected ROI comparison
- Rental yield potential
- Long-term appreciation forecasts
- Investment grade assignments

#### **4. Location Intelligence**
- Overall location scoring
- Factor-by-factor comparison
- Neighborhood ranking analysis
- Amenity accessibility

#### **5. Market Analysis**
- Current market conditions
- Negotiation leverage assessment
- Market volume and liquidity
- Timing considerations

#### **6. Risk Assessment**
- Identified risk factors for each property
- Risk level comparison
- Mitigation strategies
- Market timing risks

#### **7. Professional Recommendation**
- Recommended property with confidence level
- Detailed reasoning and justification
- Action plan and next steps
- Strategic implementation guidance

### 📊 Response Structure

\`\`\`json
{
  "success": true,
  "comparison": {
    "property1": {
      "basic_info": "...",
      "marketAnalysis": {
        "priceAnalysis": { "currentPricePerSqm": 180000, "marketAveragePricePerSqm": 180000, "pricePositioning": "Market Rate" },
        "investmentAnalysis": { "expectedROI": 0.11, "rentalYield": 0.05, "investmentGrade": "A" },
        "locationIntelligence": { "overallScore": 0.85, "neighborhoodRanking": "Top 25%" },
        "professionalInsights": { "marketPosition": "...", "recommendedStrategy": "..." }
      }
    },
    "property2": { "..." },
    "executiveSummary": { "property1Advantages": [], "property2Advantages": [] },
    "financialAnalysis": { "pricePerSqm": { "advantage": "property1" } },
    "investmentAnalysis": { "expectedROI": { "advantage": "property2" } },
    "locationAnalysis": { "overallScore": { "advantage": "property1" } },
    "riskAssessment": { "lowerRisk": "property1" },
    "professionalRecommendation": {
      "recommendedProperty": "property1",
      "confidenceLevel": "High",
      "reasoning": "...",
      "actionPlan": ["...", "..."],
      "nextSteps": "..."
    }
  }
}
\`\`\`

### 🎯 Use Cases

#### **For Real Estate Agents**
- Client consultation materials
- Investment advisory services
- Market positioning analysis
- Competitive intelligence
- Professional presentations

#### **For Property Investors**
- Due diligence analysis
- Portfolio optimization
- Risk assessment
- ROI maximization
- Market timing decisions

#### **For Property Developers**
- Market research analysis
- Competitive positioning
- Pricing strategy development
- Investment feasibility studies
- Market opportunity identification

### 🚀 Professional Advantages

- **Time Saving**: Comprehensive analysis in seconds vs hours of manual research
- **Data-Driven**: Objective analysis removes emotional bias
- **Market Intelligence**: Access to Algeria-wide market data and trends
- **Professional Credibility**: Industry-standard analysis and terminology
- **Client Confidence**: Detailed justification for all recommendations
- **Competitive Advantage**: Advanced analytics not available elsewhere

This system transforms basic property comparison into professional market intelligence, giving agents the analytical power to provide expert-level advice and strategic guidance to their clients.
      `
    }
  })

// Helper function to generate match explanation
function generateVectorMatchExplanation(searchVector: number[], propertyVector: number[], similarity: number): string {
  const dimensions = [
    'Budget', 'Area', 'Rooms', 'Location', 'Property Type',
    'Condition', 'Features', 'Family', 'Modern', 'Investment', 'Urgency', 'Transaction'
  ];

  const strongMatches = [];
  const weakMatches = [];

  for (let i = 0; i < 12; i++) {
    const diff = Math.abs(searchVector[i] - propertyVector[i]);
    if (diff < 0.2) {
      strongMatches.push(dimensions[i]);
    } else if (diff > 0.5) {
      weakMatches.push(dimensions[i]);
    }
  }

  let explanation = `${Math.round(similarity * 100)}% match. `;
  
  if (strongMatches.length > 0) {
    explanation += `Strong alignment: ${strongMatches.slice(0, 3).join(', ')}. `;
  }
  
  if (weakMatches.length > 0) {
    explanation += `Differences in: ${weakMatches.slice(0, 2).join(', ')}.`;
  }

  return explanation.trim();
} 

// Helper functions for property comparison
function getConditionScore(condition: string): number {
  const scores = {
    'POOR': 1,
    'FAIR': 2,
    'GOOD': 3,
    'EXCELLENT': 4,
    'NEW': 5
  };
  return scores[condition as keyof typeof scores] || 3;
}

function generateComparisonRecommendation(
  comparison: any, 
  property1Compatibility: number, 
  property2Compatibility: number
): string {
  const reasons = [];
  
  if (property1Compatibility > property2Compatibility + 0.1) {
    reasons.push('Property 1 better matches your preferences');
  } else if (property2Compatibility > property1Compatibility + 0.1) {
    reasons.push('Property 2 better matches your preferences');
  }
  
  if (comparison.valueForMoney.advantage === 'property1') {
    reasons.push('Property 1 offers better value per square meter');
  } else if (comparison.valueForMoney.advantage === 'property2') {
    reasons.push('Property 2 offers better value per square meter');
  }
  
  if (comparison.features.property1FeatureCount > comparison.features.property2FeatureCount) {
    reasons.push('Property 1 has more amenities');
  } else if (comparison.features.property2FeatureCount > comparison.features.property1FeatureCount) {
    reasons.push('Property 2 has more amenities');
  }
  
  return reasons.length > 0 ? reasons.join(', ') : 'Both properties have similar suitability';
}

function generateOverallRecommendation(comparison: any): string {
  const scores = {
    property1: 0,
    property2: 0
  };
  
  // Price advantage
  if (comparison.price.advantage === 'property1') scores.property1++;
  else if (comparison.price.advantage === 'property2') scores.property2++;
  
  // Area advantage  
  if (comparison.area.advantage === 'property1') scores.property1++;
  else if (comparison.area.advantage === 'property2') scores.property2++;
  
  // Value for money
  if (comparison.valueForMoney.advantage === 'property1') scores.property1++;
  else if (comparison.valueForMoney.advantage === 'property2') scores.property2++;
  
  // Features
  if (comparison.features.property1FeatureCount > comparison.features.property2FeatureCount) {
    scores.property1++;
  } else if (comparison.features.property2FeatureCount > comparison.features.property1FeatureCount) {
    scores.property2++;
  }
  
  // Condition
  if (comparison.condition.advantage === 'property1') scores.property1++;
  else if (comparison.condition.advantage === 'property2') scores.property2++;
  
  // Historical performance
  if (comparison.historicalPerformance.advantage === 'property1') scores.property1++;
  else if (comparison.historicalPerformance.advantage === 'property2') scores.property2++;
  
  if (scores.property1 > scores.property2) {
    return 'Property 1 is recommended based on overall analysis';
  } else if (scores.property2 > scores.property1) {
    return 'Property 2 is recommended based on overall analysis';
  } else {
    return 'Both properties have similar overall value - decision depends on personal preferences';
  }
} 

// Helper function for comprehensive recommendation
function generateComprehensiveRecommendation(comparison: any): string {
  const recommended = comparison.comparison.professionalRecommendation.recommendedProperty;
  const confidence = comparison.comparison.professionalRecommendation.confidenceLevel;
  const property = recommended === 'property1' ? comparison.property1 : comparison.property2;
  const analysis = property.analysis;

  let recommendation = `**${confidence} Confidence Recommendation: ${property.title}**\n\n`;
  
  recommendation += `**Investment Grade**: ${analysis.investmentAnalysis.investmentGrade} with ${(analysis.investmentAnalysis.expectedROI * 100).toFixed(1)}% expected ROI\n`;
  recommendation += `**Market Position**: ${analysis.priceAnalysis.pricePositioning} - ${analysis.priceAnalysis.competitiveAdvantage}\n`;
  recommendation += `**Location Ranking**: ${analysis.locationIntelligence.neighborhoodRanking} neighborhood\n`;
  recommendation += `**Market Strategy**: ${analysis.professionalInsights.recommendedStrategy}\n\n`;
  
  recommendation += `**Key Advantages**:\n`;
  comparison.comparison.executiveSummary[`${recommended}Advantages`].forEach((advantage: string) => {
    recommendation += `• ${advantage}\n`;
  });
  
  recommendation += `\n**Professional Insight**: ${analysis.professionalInsights.marketPosition}`;
  
  return recommendation;
} 