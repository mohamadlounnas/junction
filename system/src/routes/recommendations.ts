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

      if (!propertyIds || propertyIds.length === 0) {
        return {
          success: false,
          error: 'Property IDs are required'
        };
      }

      const limitNum = Math.min(50, Math.max(1, Number(limit)));
      const minSim = Math.max(0, Math.min(1, Number(minSimilarity)));

      // Get all properties
      const properties = await prisma.property.findMany({
        where: { id: { in: propertyIds } },
        select: {
          id: true,
          title: true,
          price: true,
          transactionType: true,
          scores: true
        }
      });

      // Get all active contacts
      const contacts = await prisma.contact.findMany({
        where: { isActive: true },
        select: {
          id: true,
          name: true,
          email: true,
          type: true,
          transactionType: true,
          budgetMin: true,
          budgetMax: true,
          scores: true
        }
      });

      // Generate recommendations for each property
      const bulkRecommendations = properties.map((property: any) => {
        const compatibleContacts = contacts.filter((contact: any) => {
          // Transaction type match
          if (contact.transactionType !== property.transactionType) return false;
          
          // Budget compatibility
          if (contact.budgetMin && property.price < contact.budgetMin) return false;
          if (contact.budgetMax && property.price > contact.budgetMax) return false;
          
          return true;
        });

        const recommendations = compatibleContacts
          .map((contact: any) => ({
            contact: {
              id: contact.id,
              name: contact.name,
              email: contact.email,
              type: contact.type
            },
            similarity: calculateSimilarity(property.scores, contact.scores)
          }))
          .filter((rec: any) => rec.similarity >= minSim)
          .sort((a: any, b: any) => b.similarity - a.similarity)
          .slice(0, limitNum);

        return {
          propertyId: property.id,
          propertyTitle: property.title,
          recommendationsCount: recommendations.length,
          recommendations
        };
      });

      return {
        success: true,
        data: bulkRecommendations,
        metadata: {
          propertiesProcessed: properties.length,
          totalContactsPool: contacts.length,
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
      summary: 'Bulk property recommendations',
      description: 'Generate recommendations for multiple properties at once'
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