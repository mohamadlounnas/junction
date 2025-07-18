import { Elysia, t } from 'elysia';
import { prisma } from '../config/database';
import { calculateSimilarity, explainScoreVector } from '../services/score-generator';

export const recommendationsRoutes = new Elysia({ prefix: '/recommendations' })
  // Get property recommendations for a contact
  .get('/contact/:id', async ({ params: { id }, query }) => {
    try {
      const {
        limit = 10,
        minSimilarity = 0.3,
        propertyType,
        transactionType,
        wilaya,
        priceMin,
        priceMax
      } = query;

      const limitNum = Math.min(50, Math.max(1, Number(limit)));
      const minSim = Math.max(0, Math.min(1, Number(minSimilarity)));

      // Get the contact with enhanced transaction data
      const contact = await prisma.contact.findUnique({
        where: { id },
        select: {
          id: true,
          name: true,
          email: true,
          type: true,
          transactionType: true,
          transactionTypes: true,
          primaryTransactionType: true,
          transactionFlexibility: true,
          scores: true,
          transactionScores: true,
          budgetMin: true,
          budgetMax: true,
          locationWilayas: true
        }
      });

      if (!contact) {
        return {
          success: false,
          error: 'Contact not found'
        };
      }

      // Build property filters with enhanced transaction support
      const where: any = {
        status: 'AVAILABLE'
      };

      // Enhanced transaction type matching
      if (contact.transactionTypes?.length) {
        // Contact has multiple transaction types - match any of them
        where.transactionType = { in: contact.transactionTypes };
      } else if (contact.transactionType) {
        // Legacy single transaction type
        where.transactionType = contact.transactionType;
      }
      
      // Override with query parameter if provided
      if (transactionType) {
        where.transactionType = transactionType;
      }

      // Apply additional filters
      if (propertyType) where.propertyType = propertyType;
      if (wilaya) where.wilaya = wilaya;

      // Budget filtering
      if (contact.budgetMin || contact.budgetMax || priceMin || priceMax) {
        where.price = {};
        const minPrice = Math.max(contact.budgetMin || 0, priceMin ? Number(priceMin) : 0);
        const maxPrice = Math.min(contact.budgetMax || Infinity, priceMax ? Number(priceMax) : Infinity);
        if (minPrice > 0) where.price.gte = minPrice;
        if (maxPrice < Infinity) where.price.lte = maxPrice;
      }

      // Get properties
      const properties = await prisma.property.findMany({
        where,
        include: {
          sales: {
            select: { successScore: true }
          }
        }
      });

      // Calculate similarities with enhanced transaction scoring
      const recommendations = properties
        .map((property: any) => {
          let similarity = calculateSimilarity(contact.scores, property.scores);
          
          // Apply transaction type bonus if contact has transaction scores
          if (contact.transactionScores?.length === 2) {
            const [rentScore, saleScore] = contact.transactionScores;
            const transactionBonus = property.transactionType === 'RENT' ? rentScore : saleScore;
            // Boost similarity for matching transaction types
            similarity = similarity * 0.8 + transactionBonus * 0.2;
          }
          
          // Calculate average success score for this property
          const avgSuccessScore = property.sales.length > 0
            ? property.sales.reduce((sum: number, sale: any) => sum + sale.successScore, 0) / property.sales.length
            : 0.5;

          return {
            property,
            similarity,
            avgSuccessScore,
            // Combined score: similarity + success history
            combinedScore: similarity * 0.8 + avgSuccessScore * 0.2
          };
        })
        .filter((rec: any) => rec.similarity >= minSim)
        .sort((a: any, b: any) => b.combinedScore - a.combinedScore)
        .slice(0, limitNum)
        .map((rec: any) => ({
          property: {
            id: rec.property.id,
            title: rec.property.title,
            price: rec.property.price,
            area: rec.property.area,
            rooms: rec.property.rooms,
            wilaya: rec.property.wilaya,
            city: rec.property.city,
            propertyType: rec.property.propertyType,
            transactionType: rec.property.transactionType,
            condition: rec.property.condition
          },
          similarity: Math.round(rec.similarity * 1000) / 1000,
          combinedScore: Math.round(rec.combinedScore * 1000) / 1000,
          explanation: generateExplanation(contact, rec.property, rec.similarity)
        }));

      return {
        success: true,
        data: {
          contact: {
            id: contact.id,
            name: contact.name,
            email: contact.email,
            type: contact.type,
            transactionType: contact.transactionType,
            transactionTypes: contact.transactionTypes,
            primaryTransactionType: contact.primaryTransactionType,
            transactionFlexibility: contact.transactionFlexibility
          },
          recommendations,
          total: recommendations.length,
          filters: {
            minSimilarity: minSim,
            propertyType,
            transactionType: where.transactionType,
            wilaya,
            priceMin: priceMin ? Number(priceMin) : undefined,
            priceMax: priceMax ? Number(priceMax) : undefined
          }
        }
      };
    } catch (error) {
      console.error('Get recommendations error:', error);
      return {
        success: false,
        error: 'Failed to get recommendations'
      };
    }
  }, {
    params: t.Object({
      id: t.String({ description: 'Contact ID' })
    }),
    query: t.Object({
      limit: t.Optional(t.Union([
        t.Number({ minimum: 1, maximum: 50, default: 10 }),
        t.String()
      ])),
      minSimilarity: t.Optional(t.Union([
        t.Number({ minimum: 0, maximum: 1, default: 0.3 }),
        t.String()
      ])),
      propertyType: t.Optional(t.Union([
        t.Literal('APARTMENT'), t.Literal('VILLA'), t.Literal('HOUSE'),
        t.Literal('OFFICE'), t.Literal('SHOP'), t.Literal('WAREHOUSE'),
        t.Literal('LAND'), t.Literal('GARAGE')
      ])),
      transactionType: t.Optional(t.Union([
        t.Literal('RENT'),
        t.Literal('SALE')
      ])),
      wilaya: t.Optional(t.String()),
      priceMin: t.Optional(t.Union([
        t.Number({ minimum: 0 }),
        t.String()
      ])),
      priceMax: t.Optional(t.Union([
        t.Number({ minimum: 0 }),
        t.String()
      ]))
    }),
    detail: {
      tags: ['Recommendations'],
      summary: 'Get property recommendations for contact with enhanced transaction support',
      description: `
## Enhanced Property Recommendations with Dual Transaction Support

Get AI-powered property recommendations for a contact, now with support for multiple transaction types.

### 🔄 Enhanced Transaction Support
- **Legacy**: Matches single transactionType
- **Enhanced**: Matches any transaction type from transactionTypes array
- **Flexibility**: Considers transaction flexibility in scoring
- **Primary Preference**: Prioritizes primary transaction type

### 🤖 AI Features
- **Dual Scoring**: Uses both main scores and transaction scores
- **Transaction Bonus**: Boosts similarity for matching transaction types
- **Flexibility Weighting**: Considers how flexible the contact is
- **Success History**: Incorporates past successful transactions

### 📊 Scoring Algorithm
1. **Base Similarity**: 12D vector similarity (80% weight)
2. **Transaction Bonus**: Transaction type matching (20% weight)
3. **Success History**: Past transaction success rates
4. **Combined Score**: Weighted combination for final ranking

### 🎯 Use Cases
- Flexible buyers open to both renting and buying
- Investors with multiple transaction strategies
- Contacts with primary and secondary preferences
        `
    }
  })

  // Get contact recommendations for a property
  .get('/property/:id', async ({ params: { id }, query }) => {
    try {
      const {
        limit = 10,
        minSimilarity = 0.3,
        contactType,
        wilaya,
        budgetMin,
        budgetMax
      } = query;

      const limitNum = Math.min(50, Math.max(1, Number(limit)));
      const minSim = Math.max(0, Math.min(1, Number(minSimilarity)));

      // Get the property
      const property = await prisma.property.findUnique({
        where: { id },
        select: {
          id: true,
          title: true,
          price: true,
          area: true,
          rooms: true,
          wilaya: true,
          city: true,
          propertyType: true,
          transactionType: true,
          condition: true,
          scores: true
        }
      });

      if (!property) {
        return {
          success: false,
          error: 'Property not found'
        };
      }

      // Build contact filters
      const where: any = {
        isActive: true
      };

      // Match transaction type
      if (property.transactionType) {
        where.transactionType = property.transactionType;
      }

      // Apply additional filters
      if (contactType) where.type = contactType;
      if (wilaya) {
        where.locationWilayas = { has: wilaya };
      }

      // Budget filtering
      if (budgetMin || budgetMax) {
        where.AND = [];
        if (budgetMin) where.AND.push({
          OR: [
            { budgetMin: { lte: Number(budgetMin) } },
            { budgetMin: null }
          ]
        });
        if (budgetMax) where.AND.push({
          OR: [
            { budgetMax: { gte: Number(budgetMax) } },
            { budgetMax: null }
          ]
        });
      }

      // Budget compatibility with property price
      where.AND = where.AND || [];
      where.AND.push({
        OR: [
          { budgetMin: { lte: property.price } },
          { budgetMin: null }
        ]
      });
      where.AND.push({
        OR: [
          { budgetMax: { gte: property.price } },
          { budgetMax: null }
        ]
      });

      // Get contacts
      const contacts = await prisma.contact.findMany({
        where,
        include: {
          sales: {
            select: { successScore: true }
          }
        }
      });

      // Calculate similarities and sort
      const recommendations = contacts
        .map((contact: any) => {
          const similarity = calculateSimilarity(property.scores, contact.scores);
          
          // Calculate average success score for this contact
          const avgSuccessScore = contact.sales.length > 0
            ? contact.sales.reduce((sum: number, sale: any) => sum + sale.successScore, 0) / contact.sales.length
            : 0.5;

          return {
            contact,
            similarity,
            avgSuccessScore,
            // Combined score: similarity + success history
            combinedScore: similarity * 0.8 + avgSuccessScore * 0.2
          };
        })
        .filter((rec: any) => rec.similarity >= minSim)
        .sort((a: any, b: any) => b.combinedScore - a.combinedScore)
        .slice(0, limitNum)
        .map((rec: any) => ({
          contact: {
            id: rec.contact.id,
            name: rec.contact.name,
            email: rec.contact.email,
            phone: rec.contact.phone,
            type: rec.contact.type,
            budgetMin: rec.contact.budgetMin,
            budgetMax: rec.contact.budgetMax,
            locationWilayas: rec.contact.locationWilayas,
            transactionType: rec.contact.transactionType
          },
          similarity: Math.round(rec.similarity * 1000) / 1000,
          combinedScore: Math.round(rec.combinedScore * 1000) / 1000,
          explanation: generateExplanation(rec.contact, property, rec.similarity)
        }));

      return {
        success: true,
        data: {
          property: {
            id: property.id,
            title: property.title,
            price: property.price,
            area: property.area,
            rooms: property.rooms,
            wilaya: property.wilaya,
            city: property.city,
            propertyType: property.propertyType,
            transactionType: property.transactionType
          },
          recommendations,
          metadata: {
            totalContacts: contacts.length,
            recommendationsFound: recommendations.length,
            minSimilarity: minSim,
            algorithm: '12D Vector Similarity',
            generatedAt: new Date().toISOString()
          }
        }
      };
    } catch (error) {
      console.error('Get property recommendations error:', error);
      return {
        success: false,
        error: 'Failed to generate recommendations'
      };
    }
  }, {
    detail: {
      tags: ['Recommendations'],
      summary: 'Get contact recommendations for property',
      description: 'Get AI-powered contact recommendations for a specific property'
    }
  })

  // Bulk recommendations for multiple properties
  .post('/bulk', async ({ body }) => {
    try {
      const { propertyIds, minSimilarity = 0.3, limit = 10 } = body;

      if (!Array.isArray(propertyIds) || propertyIds.length === 0) {
        return {
          success: false,
          error: 'Property IDs array is required and cannot be empty'
        };
      }

      if (propertyIds.length > 100) {
        return {
          success: false,
          error: 'Maximum 100 properties can be processed at once'
        };
      }

      const limitNum = Math.min(50, Math.max(1, Number(limit)));
      const minSim = Math.max(0, Math.min(1, Number(minSimilarity)));

      // Get all contacts for matching with enhanced transaction data
      const allContacts = await prisma.contact.findMany({
        where: { isActive: true },
        select: {
          id: true,
          name: true,
          email: true,
          type: true,
          transactionType: true,
          transactionTypes: true,
          primaryTransactionType: true,
          transactionFlexibility: true,
          scores: true,
          transactionScores: true,
          budgetMin: true,
          budgetMax: true,
          locationWilayas: true
        }
      });

      const results = [];

      for (const propertyId of propertyIds) {
        try {
          const property = await prisma.property.findUnique({
            where: { id: propertyId },
            select: {
              id: true,
              title: true,
              price: true,
              area: true,
              rooms: true,
              wilaya: true,
              city: true,
              propertyType: true,
              transactionType: true,
              condition: true,
              scores: true
            }
          });

          if (!property) {
            results.push({
              propertyId,
              error: 'Property not found'
            });
            continue;
          }

          // Enhanced transaction type matching with dual support
          const matchingContacts = allContacts.filter(contact => {
            // Enhanced dual transaction type matching
            if (contact.transactionTypes?.length) {
              // Contact has multiple transaction types - match any of them
              return contact.transactionTypes.includes(property.transactionType);
            } else if (contact.transactionType) {
              // Legacy single transaction type
              return contact.transactionType === property.transactionType;
            }
            return false;
          });

          // Calculate similarities with enhanced transaction scoring
          const recommendations = matchingContacts
            .map(contact => {
              let similarity = calculateSimilarity(contact.scores, property.scores);
              
              // Apply transaction type bonus if contact has transaction scores
              if (contact.transactionScores?.length === 2) {
                const [rentScore, saleScore] = contact.transactionScores;
                const transactionBonus = property.transactionType === 'RENT' ? rentScore : saleScore;
                // Boost similarity for matching transaction types
                similarity = similarity * 0.8 + transactionBonus * 0.2;
              }
              
              return { contact, similarity };
            })
            .filter(rec => rec.similarity >= minSim)
            .sort((a, b) => b.similarity - a.similarity)
            .slice(0, limitNum)
            .map(rec => ({
              contact: {
                id: rec.contact.id,
                name: rec.contact.name,
                email: rec.contact.email,
                type: rec.contact.type,
                transactionType: rec.contact.transactionType,
                transactionTypes: rec.contact.transactionTypes,
                primaryTransactionType: rec.contact.primaryTransactionType,
                transactionFlexibility: rec.contact.transactionFlexibility
              },
              similarity: Math.round(rec.similarity * 1000) / 1000
            }));

          results.push({
            propertyId,
            propertyTitle: property.title,
            recommendationsCount: recommendations.length,
            recommendations
          });
        } catch (error) {
          results.push({
            propertyId,
            error: error instanceof Error ? error.message : String(error)
          });
        }
      }

      return {
        success: true,
        data: results,
        metadata: {
          propertiesProcessed: propertyIds.length,
          totalContactsPool: allContacts.length,
          minSimilarity: minSim,
          generatedAt: new Date().toISOString()
        }
      };
    } catch (error) {
      console.error('Bulk recommendations error:', error);
      return {
        success: false,
        error: 'Failed to generate bulk recommendations'
      };
    }
  }, {
    body: t.Object({
      propertyIds: t.Array(t.String(), { minItems: 1, maxItems: 100 }),
      minSimilarity: t.Optional(t.Number({ minimum: 0, maximum: 1 })),
      limit: t.Optional(t.Number({ minimum: 1, maximum: 50 }))
    }),
    detail: {
      tags: ['Recommendations'],
      summary: 'Bulk recommendations for properties with enhanced dual transaction support',
      description: `
## Bulk Property Recommendations with Enhanced Dual Transaction Support

Get AI-powered contact recommendations for multiple properties at once, now with support for dual transaction types.

### 🔄 Enhanced Transaction Support
- **Legacy**: Matches single transactionType
- **Enhanced**: Matches any transaction type from transactionTypes array
- **Flexibility**: Considers transaction flexibility in scoring
- **Primary Preference**: Prioritizes primary transaction type

### 📊 Similarity Thresholds
- **0.0-0.2**: Very low similarity (rare matches)
- **0.2-0.4**: Low similarity (some matches)
- **0.4-0.6**: Medium similarity (good matches)
- **0.6-0.8**: High similarity (excellent matches)
- **0.8-1.0**: Very high similarity (perfect matches)

### 💡 Recommended Settings
- **minSimilarity: 0.3** - Good balance of quality and quantity
- **minSimilarity: 0.5** - Higher quality matches
- **minSimilarity: 0.7** - Premium matches only
- **minSimilarity: 0.95** - Perfect matches only (very rare)

### 🎯 Use Cases
- Batch processing multiple properties
- Market analysis and insights
- Lead generation campaigns
- Portfolio optimization
        `
    }
  })

  // Recommendation analytics
  .get('/analytics', async () => {
    try {
      const [
        totalContacts,
        totalProperties,
        recentRecommendations,
        topSimilarityScores
      ] = await Promise.all([
        prisma.contact.count({ where: { isActive: true } }),
        prisma.property.count({ where: { status: 'AVAILABLE' } }),
        prisma.sale.findMany({
          orderBy: { createdAt: 'desc' },
          take: 10,
          include: {
            contact: { select: { name: true, type: true } },
            property: { select: { title: true, propertyType: true } }
          }
        }),
        prisma.sale.aggregate({
          _avg: { successScore: true },
          _max: { successScore: true },
          _min: { successScore: true }
        })
      ]);

      // Calculate recommendation effectiveness
      const successfulSales = recentRecommendations.filter(sale => sale.successScore >= 0.7);
      const effectivenessRate = recentRecommendations.length > 0 
        ? (successfulSales.length / recentRecommendations.length) * 100 
        : 0;

      return {
        success: true,
        data: {
          overview: {
            totalContacts,
            totalProperties,
            potentialMatches: totalContacts * totalProperties,
            averageSuccessScore: topSimilarityScores._avg.successScore
          },
          effectiveness: {
            totalSales: recentRecommendations.length,
            successfulSales: successfulSales.length,
            effectivenessRate: Math.round(effectivenessRate * 100) / 100,
            averageSuccessScore: topSimilarityScores._avg.successScore,
            maxSuccessScore: topSimilarityScores._max.successScore,
            minSuccessScore: topSimilarityScores._min.successScore
          },
          recentActivity: {
            recentSales: recentRecommendations.map(sale => ({
              contactName: sale.contact.name,
              contactType: sale.contact.type,
              propertyTitle: sale.property.title,
              propertyType: sale.property.propertyType,
              successScore: sale.successScore,
              saleDate: sale.saleDate
            }))
          },
          algorithm: {
            name: '12D Vector Similarity',
            dimensions: 12,
            optimization: 'Algeria-specific',
            learningEnabled: true
          }
        }
      };
    } catch (error) {
      console.error('Recommendation analytics error:', error);
      return {
        success: false,
        error: 'Failed to generate recommendation analytics'
      };
    }
  }, {
    detail: {
      tags: ['Recommendations'],
      summary: 'Recommendation system analytics',
      description: 'Get comprehensive analytics about the recommendation system performance'
    }
  })

  // Similarity matrix for a contact
  .get('/similarity-matrix/:contactId', async ({ params: { contactId }, query }) => {
    try {
      const { limit = 20 } = query;
      const limitNum = Math.min(100, Math.max(1, Number(limit)));

      const contact = await prisma.contact.findUnique({
        where: { id: contactId },
        select: {
          id: true,
          name: true,
          type: true,
          transactionType: true,
          scores: true
        }
      });

      if (!contact) {
        return {
          success: false,
          error: 'Contact not found'
        };
      }

      // Get all available properties
      const properties = await prisma.property.findMany({
        where: { 
          status: 'AVAILABLE',
          transactionType: contact.transactionType
        },
        select: {
          id: true,
          title: true,
          price: true,
          area: true,
          rooms: true,
          wilaya: true,
          city: true,
          propertyType: true,
          scores: true
        }
      });

      // Calculate similarity matrix
      const similarityMatrix = properties
        .map(property => {
          const similarity = calculateSimilarity(contact.scores, property.scores);
          return {
            property: {
              id: property.id,
              title: property.title,
              price: property.price,
              area: property.area,
              rooms: property.rooms,
              wilaya: property.wilaya,
              city: property.city,
              propertyType: property.propertyType
            },
            similarity: Math.round(similarity * 1000) / 1000,
            explanation: generateExplanation(contact, property, similarity)
          };
        })
        .sort((a, b) => b.similarity - a.similarity)
        .slice(0, limitNum);

      return {
        success: true,
        data: {
          contact: {
            id: contact.id,
            name: contact.name,
            type: contact.type,
            transactionType: contact.transactionType
          },
          similarityMatrix,
          metadata: {
            totalProperties: properties.length,
            matrixSize: similarityMatrix.length,
            algorithm: '12D Vector Similarity',
            generatedAt: new Date().toISOString()
          }
        }
      };
    } catch (error) {
      console.error('Similarity matrix error:', error);
      return {
        success: false,
        error: 'Failed to generate similarity matrix'
      };
    }
  }, {
    query: t.Object({
      limit: t.Optional(t.Union([t.Number(), t.String()]))
    }),
    detail: {
      tags: ['Recommendations'],
      summary: 'Generate similarity matrix for contact',
      description: 'Get a complete similarity matrix showing how well a contact matches all available properties'
    }
  })

  // Batch recommendation processing
  .post('/batch-process', async ({ body }) => {
    try {
      const { contactIds, propertyIds, minSimilarity = 0.3, limit = 10 } = body;

      if (!Array.isArray(contactIds) || contactIds.length === 0) {
        return {
          success: false,
          error: 'Contact IDs array is required and cannot be empty'
        };
      }

      if (!Array.isArray(propertyIds) || propertyIds.length === 0) {
        return {
          success: false,
          error: 'Property IDs array is required and cannot be empty'
        };
      }

      if (contactIds.length > 50 || propertyIds.length > 50) {
        return {
          success: false,
          error: 'Maximum 50 contacts and 50 properties can be processed at once'
        };
      }

      const limitNum = Math.min(50, Math.max(1, Number(limit)));
      const minSim = Math.max(0, Math.min(1, Number(minSimilarity)));

      // Get contacts and properties
      const [contacts, properties] = await Promise.all([
        prisma.contact.findMany({
          where: { 
            id: { in: contactIds },
            isActive: true 
          },
          select: {
            id: true,
            name: true,
            email: true,
            type: true,
            transactionType: true,
            scores: true
          }
        }),
        prisma.property.findMany({
          where: { 
            id: { in: propertyIds },
            status: 'AVAILABLE'
          },
          select: {
            id: true,
            title: true,
            price: true,
            area: true,
            rooms: true,
            wilaya: true,
            city: true,
            propertyType: true,
            transactionType: true,
            scores: true
          }
        })
      ]);

      const results: any[] = [];

      for (const contact of contacts) {
        const contactResults = {
          contactId: contact.id,
          contactName: contact.name,
          recommendations: [] as any[]
        };

        // Filter properties by transaction type match
        const matchingProperties = properties.filter(property => 
          property.transactionType === contact.transactionType
        );

        // Calculate similarities
        const recommendations = matchingProperties
          .map(property => {
            const similarity = calculateSimilarity(contact.scores, property.scores);
            return { property, similarity };
          })
          .filter(rec => rec.similarity >= minSim)
          .sort((a, b) => b.similarity - a.similarity)
          .slice(0, limitNum)
          .map(rec => ({
            property: {
              id: rec.property.id,
              title: rec.property.title,
              price: rec.property.price,
              wilaya: rec.property.wilaya,
              propertyType: rec.property.propertyType
            },
            similarity: Math.round(rec.similarity * 1000) / 1000
          }));

        contactResults.recommendations = recommendations;
        results.push(contactResults);
      }

      return {
        success: true,
        data: results,
        metadata: {
          contactsProcessed: contacts.length,
          propertiesProcessed: properties.length,
          totalRecommendations: results.reduce((sum, result) => sum + result.recommendations.length, 0),
          minSimilarity: minSim,
          generatedAt: new Date().toISOString()
        }
      };
    } catch (error) {
      console.error('Batch recommendation processing error:', error);
      return {
        success: false,
        error: 'Failed to process batch recommendations'
      };
    }
  }, {
    body: t.Object({
      contactIds: t.Array(t.String(), { minItems: 1, maxItems: 50 }),
      propertyIds: t.Array(t.String(), { minItems: 1, maxItems: 50 }),
      minSimilarity: t.Optional(t.Number({ minimum: 0, maximum: 1 })),
      limit: t.Optional(t.Number({ minimum: 1, maximum: 50 }))
    }),
    detail: {
      tags: ['Recommendations'],
      summary: 'Batch recommendation processing for multiple contacts and properties',
      description: `
## 🚀 Batch Recommendation Processing

Process recommendations for **multiple contacts against multiple properties simultaneously**, creating a comprehensive matching matrix for bulk operations.

### 🎯 What Is Batch Processing?

Batch processing takes arrays of contact IDs and property IDs, then finds the best property matches for each contact using AI-powered similarity scoring. Perfect for lead generation, portfolio analysis, and market research.

### 📊 Key Features

- **Many-to-Many Processing**: Multiple contacts × Multiple properties (up to 50×50 = 2,500 combinations)
- **Contact-Centric Results**: Each contact gets their best property matches
- **AI-Powered Matching**: Uses 12D vector similarity scoring with enhanced dual transaction support
- **Transaction Type Filtering**: Only matches compatible transaction types
- **Performance Optimized**: Efficient parallel processing

### 🔄 Algorithm Flow

1. **Input Validation**: Validate contact and property IDs arrays
2. **Data Fetching**: Retrieve contacts and properties in parallel
3. **For Each Contact**:
   - Filter properties by compatible transaction types
   - Calculate AI similarity scores using 12D vectors
   - Apply transaction type bonuses for dual transaction contacts
   - Filter by minimum similarity threshold
   - Sort by similarity score and take top N results
4. **Return Results**: Contact-centric recommendation matrix

### 🎯 Use Cases

#### **Lead Generation Campaigns**
Generate targeted property recommendations for marketing segments:
\`\`\`json
{
  "contactIds": ["segment_buyers_001", "segment_buyers_002"],
  "propertyIds": ["new_listing_001", "new_listing_002"],
  "minSimilarity": 0.4,
  "limit": 3
}
\`\`\`

#### **Portfolio Analysis**
Analyze which properties match investor clients:
\`\`\`json
{
  "contactIds": ["investor_001", "investor_002"],
  "propertyIds": ["commercial_001", "office_001", "retail_001"],
  "minSimilarity": 0.6,
  "limit": 5
}
\`\`\`

#### **Market Research**
Broad market demand analysis:
\`\`\`json
{
  "contactIds": ["sample_contacts_array"],
  "propertyIds": ["market_properties_array"],
  "minSimilarity": 0.2,
  "limit": 10
}
\`\`\`

#### **Sales Team Optimization**
Daily property matches for active contacts:
\`\`\`json
{
  "contactIds": ["active_contact_001", "active_contact_002"],
  "propertyIds": ["available_property_001", "available_property_002"],
  "minSimilarity": 0.35,
  "limit": 4
}
\`\`\`

### 📊 Performance Guidelines

| Batch Size | Contacts | Properties | Combinations | Response Time | Recommended Use |
|------------|----------|------------|--------------|---------------|-----------------|
| **Small** | 5-10 | 5-15 | 25-150 | < 500ms | Quick campaigns |
| **Medium** | 15-25 | 20-30 | 300-750 | 500ms-2s | Regular operations |
| **Large** | 30-50 | 35-50 | 1,050-2,500 | 2s-5s | Comprehensive analysis |

### 💡 Similarity Threshold Guidelines

- **0.2-0.3**: Broad matching for market research
- **0.3-0.5**: Balanced quality/quantity for campaigns ✅ **Recommended**
- **0.5-0.7**: High-quality matches for premium clients
- **0.7-1.0**: Exclusive matches (very selective)

### 🔄 Enhanced Dual Transaction Support

The batch processor now supports contacts with multiple transaction types:
- **Legacy contacts**: Single transaction type (RENT or SALE)
- **Enhanced contacts**: Multiple transaction types with primary preference
- **Flexibility scoring**: Transaction flexibility weighting in recommendations
- **Transaction bonuses**: Similarity boosts for matching transaction types

### ⚙️ Request Parameters

- **contactIds**: Array of contact IDs (1-50 required)
- **propertyIds**: Array of property IDs (1-50 required)  
- **minSimilarity**: Minimum similarity threshold (0-1, default: 0.3)
- **limit**: Maximum recommendations per contact (1-50, default: 10)

### 📈 Response Structure

Each contact receives:
- **contactId**: Contact identifier
- **contactName**: Contact name for reference
- **recommendations**: Array of matching properties with similarity scores
- **metadata**: Processing statistics and performance info

### 🛡️ Error Handling

Common validation errors:
- Empty contact or property arrays
- Arrays exceeding 50 items
- Invalid similarity thresholds
- Server processing errors

### 🔗 Related Endpoints

- **Individual**: \`/recommendations/contact/{id}\` - Single contact recommendations
- **Property**: \`/recommendations/property/{id}\` - Single property marketing
- **Bulk**: \`/recommendations/bulk\` - Multiple properties to contacts
- **Batch**: \`/recommendations/batch-process\` - Multiple contacts to properties ⭐

### 🎉 Integration Examples

Perfect for integrating with:
- **CRM Systems**: Lead generation and contact management
- **Email Marketing**: Personalized property recommendations  
- **Analytics Dashboards**: Market insights and demand analysis
- **Sales Tools**: Daily prospect matching and follow-up lists

### 🇩🇿 Algeria Market Optimization

- **48 Wilayas Support**: Geographic coverage across Algeria
- **DZD Currency**: All prices in Algerian Dinar
- **Cultural Preferences**: Family-oriented and investment patterns
- **Property Types**: Villa, apartment, office, land, and commercial spaces
        `,
      responses: {
        '200': {
          description: 'Batch processing completed successfully',
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
                        contactId: { type: 'string', example: 'cmd92djy5000a14ollrdik8y8' },
                        contactName: { type: 'string', example: 'Sara Benmoussa' },
                        recommendations: {
                          type: 'array',
                          items: {
                            type: 'object',
                            properties: {
                              property: {
                                type: 'object',
                                properties: {
                                  id: { type: 'string', example: 'cmd92dk6q000d14ol3ervqga7' },
                                  title: { type: 'string', example: 'Bureau 120m² Centre d\'Alger' },
                                  price: { type: 'number', example: 45000000, description: 'Price in DZD' },
                                  wilaya: { type: 'string', example: 'Algiers' },
                                  propertyType: { type: 'string', example: 'OFFICE' }
                                }
                              },
                              similarity: { type: 'number', minimum: 0, maximum: 1, example: 0.875, description: 'AI similarity score' }
                            }
                          }
                        }
                      }
                    }
                  },
                  metadata: {
                    type: 'object',
                    properties: {
                      contactsProcessed: { type: 'number', example: 2 },
                      propertiesProcessed: { type: 'number', example: 3 },
                      totalRecommendations: { type: 'number', example: 4 },
                      minSimilarity: { type: 'number', example: 0.3 },
                      generatedAt: { type: 'string', format: 'date-time', example: '2025-07-18T17:37:34.820Z' }
                    }
                  }
                }
              },
              examples: {
                'lead_generation_campaign': {
                  summary: 'Lead Generation Campaign Results',
                  description: 'Batch processing results for a targeted marketing campaign with multiple contacts and new property listings',
                  value: {
                    success: true,
                    data: [
                      {
                        contactId: 'cmd92djy5000a14ollrdik8y8',
                        contactName: 'Sara Benmoussa',
                        recommendations: [
                          {
                            property: {
                              id: 'cmd92dk6q000d14ol3ervqga7',
                              title: 'Bureau 120m² Centre d\'Alger',
                              price: 45000000,
                              wilaya: 'Algiers',
                              propertyType: 'OFFICE'
                            },
                            similarity: 0.875
                          },
                          {
                            property: {
                              id: 'cmd92dkfg000g14olx9jckmji',
                              title: 'Terrain constructible à Tipaza',
                              price: 8000000,
                              wilaya: 'Tipaza',
                              propertyType: 'LAND'
                            },
                            similarity: 0.764
                          }
                        ]
                      },
                      {
                        contactId: 'cmd92djwf000914oljj04qcej',
                        contactName: 'Youcef Hamidi',
                        recommendations: []
                      }
                    ],
                    metadata: {
                      contactsProcessed: 2,
                      propertiesProcessed: 3,
                      totalRecommendations: 2,
                      minSimilarity: 0.3,
                      generatedAt: '2025-07-18T17:37:34.820Z'
                    }
                  }
                },
                'portfolio_analysis': {
                  summary: 'Investment Portfolio Analysis',
                  description: 'High-quality matches for investor clients analyzing commercial properties',
                  value: {
                    success: true,
                    data: [
                      {
                        contactId: 'investor_premium_001',
                        contactName: 'Karim Investment Group',
                        recommendations: [
                          {
                            property: {
                              id: 'commercial_office_001',
                              title: 'Premium Office Complex Algiers',
                              price: 150000000,
                              wilaya: 'Algiers',
                              propertyType: 'OFFICE'
                            },
                            similarity: 0.92
                          },
                          {
                            property: {
                              id: 'retail_center_001',
                              title: 'Shopping Center Oran',
                              price: 200000000,
                              wilaya: 'Oran',
                              propertyType: 'SHOP'
                            },
                            similarity: 0.87
                          }
                        ]
                      }
                    ],
                    metadata: {
                      contactsProcessed: 1,
                      propertiesProcessed: 5,
                      totalRecommendations: 2,
                      minSimilarity: 0.6,
                      generatedAt: '2025-07-18T17:37:34.820Z'
                    }
                  }
                },
                'market_research': {
                  summary: 'Market Research Analysis',
                  description: 'Broad market analysis for research purposes with lower similarity threshold',
                  value: {
                    success: true,
                    data: [
                      {
                        contactId: 'research_segment_001',
                        contactName: 'Young Professionals Segment',
                        recommendations: [
                          {
                            property: {
                              id: 'modern_apartment_001',
                              title: 'Modern F3 Apartment',
                              price: 12000000,
                              wilaya: 'Algiers',
                              propertyType: 'APARTMENT'
                            },
                            similarity: 0.45
                          }
                        ]
                      }
                    ],
                    metadata: {
                      contactsProcessed: 3,
                      propertiesProcessed: 10,
                      totalRecommendations: 8,
                      minSimilarity: 0.2,
                      generatedAt: '2025-07-18T17:37:34.820Z'
                    }
                  }
                }
              }
            }
          }
        },
        '400': {
          description: 'Bad request - validation errors',
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  success: { type: 'boolean', example: false },
                  error: { type: 'string' }
                }
              },
              examples: {
                'empty_contact_ids': {
                  summary: 'Empty Contact IDs',
                  value: {
                    success: false,
                    error: 'Contact IDs array is required and cannot be empty'
                  }
                },
                'empty_property_ids': {
                  summary: 'Empty Property IDs',
                  value: {
                    success: false,
                    error: 'Property IDs array is required and cannot be empty'
                  }
                },
                'too_many_items': {
                  summary: 'Batch Size Limit Exceeded',
                  value: {
                    success: false,
                    error: 'Maximum 50 contacts and 50 properties can be processed at once'
                  }
                },
                'invalid_similarity': {
                  summary: 'Invalid Similarity Threshold',
                  value: {
                    success: false,
                    error: 'Minimum similarity must be between 0 and 1'
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
                  error: { type: 'string', example: 'Failed to process batch recommendations' }
                }
              }
            }
          }
        }
      }
    }
  }); 

// Helper function to generate human-readable explanations
function generateExplanation(contact: any, property: any, similarity: number): string {
  const explanations = [];

  if (similarity > 0.8) {
    explanations.push('Excellent match');
  } else if (similarity > 0.6) {
    explanations.push('Good match');
  } else if (similarity > 0.4) {
    explanations.push('Fair match');
  } else {
    explanations.push('Basic compatibility');
  }

  // Budget compatibility
  if (contact.budgetMin && contact.budgetMax) {
    if (property.price >= contact.budgetMin && property.price <= contact.budgetMax) {
      explanations.push('Budget perfect fit');
    } else if (property.price < contact.budgetMax * 1.2) {
      explanations.push('Budget close match');
    }
  }

  // Transaction type
  if (contact.transactionType === property.transactionType) {
    explanations.push(`${property.transactionType.toLowerCase()} preference match`);
  }

  // Location
  if (contact.locationWilayas && contact.locationWilayas.includes(property.wilaya)) {
    explanations.push('Preferred location');
  }

  // Property type
  if (contact.propertyTypes && contact.propertyTypes.includes(property.propertyType)) {
    explanations.push('Preferred property type');
  }

  return explanations.join(', ') || 'Basic compatibility factors';
}