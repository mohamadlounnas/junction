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

      // Get the contact
      const contact = await prisma.contact.findUnique({
        where: { id },
        select: {
          id: true,
          name: true,
          email: true,
          type: true,
          transactionType: true,
          scores: true,
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

      // Build property filters
      const where: any = {
        status: 'AVAILABLE'
      };

      // Match transaction type
      if (contact.transactionType) {
        where.transactionType = contact.transactionType;
      }
      if (transactionType) {
        where.transactionType = transactionType;
      }

      // Apply additional filters
      if (propertyType) where.propertyType = propertyType;
      if (wilaya) where.wilaya = wilaya;

      // Budget filtering
      if (contact.budgetMin || contact.budgetMax || priceMin || priceMax) {
        where.price = {};
        const minPrice = Math.max(
          contact.budgetMin || 0,
          priceMin ? Number(priceMin) : 0
        );
        const maxPrice = Math.min(
          contact.budgetMax || Infinity,
          priceMax ? Number(priceMax) : Infinity
        );
        
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

      // Calculate similarities and sort
      const recommendations = properties
        .map((property: any) => {
          const similarity = calculateSimilarity(contact.scores, property.scores);
          
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
            description: rec.property.description,
            price: rec.property.price,
            area: rec.property.area,
            rooms: rec.property.rooms,
            wilaya: rec.property.wilaya,
            city: rec.property.city,
            propertyType: rec.property.propertyType,
            transactionType: rec.property.transactionType,
            condition: rec.property.condition,
            hasParking: rec.property.hasParking,
            hasSecurity: rec.property.hasSecurity,
            featured: rec.property.featured
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
            type: contact.type,
            transactionType: contact.transactionType
          },
          recommendations,
          metadata: {
            totalProperties: properties.length,
            recommendationsFound: recommendations.length,
            minSimilarity: minSim,
            algorithm: '12D Vector Similarity',
            generatedAt: new Date().toISOString()
          }
        }
      };
    } catch (error) {
      console.error('Get contact recommendations error:', error);
      return {
        success: false,
        error: 'Failed to generate recommendations'
      };
    }
  }, {
    detail: {
      tags: ['Recommendations'],
      summary: 'Get property recommendations for contact',
      description: 'Get AI-powered property recommendations for a specific contact'
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

      // Get all contacts for matching
      const allContacts = await prisma.contact.findMany({
        where: { isActive: true },
        select: {
          id: true,
          name: true,
          email: true,
          type: true,
          transactionType: true,
          scores: true,
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

          // Filter contacts by transaction type match
          const matchingContacts = allContacts.filter(contact => 
            contact.transactionType === property.transactionType
          );

          // Calculate similarities
          const recommendations = matchingContacts
            .map(contact => {
              const similarity = calculateSimilarity(contact.scores, property.scores);
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
                type: rec.contact.type
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
      summary: 'Bulk recommendations for properties',
      description: 'Get recommendations for multiple properties at once'
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
      summary: 'Batch recommendation processing',
      description: 'Process recommendations for multiple contacts and properties simultaneously'
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