import { Elysia, t } from 'elysia';
import { prisma } from '../config/database';
import { learnFromSale } from '../services/score-generator';

export const salesRoutes = new Elysia({ prefix: '/sales' })
  // List sales with filtering
  .get('/', async ({ query }) => {
    try {
      const {
        page = 1,
        limit = 10,
        contactId,
        propertyId,
        successScoreMin,
        successScoreMax
      } = query;

      const pageNum = Math.max(1, Number(page));
      const limitNum = Math.min(50, Math.max(1, Number(limit)));
      const skip = (pageNum - 1) * limitNum;

      // Build filters
      const where: any = {};
      if (contactId) where.contactId = contactId;
      if (propertyId) where.propertyId = propertyId;
      
      if (successScoreMin || successScoreMax) {
        where.successScore = {};
        if (successScoreMin) where.successScore.gte = Number(successScoreMin);
        if (successScoreMax) where.successScore.lte = Number(successScoreMax);
      }

      const [sales, total] = await Promise.all([
        prisma.sale.findMany({
          where,
          skip,
          take: limitNum,
          orderBy: { saleDate: 'desc' },
          include: {
            contact: {
              select: { id: true, name: true, email: true, type: true }
            },
            property: {
              select: { id: true, title: true, price: true, wilaya: true, city: true }
            }
          }
        }),
        prisma.sale.count({ where })
      ]);

      return {
        success: true,
        data: sales,
        pagination: {
          page: pageNum,
          limit: limitNum,
          total,
          pages: Math.ceil(total / limitNum)
        }
      };
    } catch (error) {
      console.error('Get sales error:', error);
      return {
        success: false,
        error: 'Failed to fetch sales'
      };
    }
  }, {
    detail: {
      tags: ['Sales'],
      summary: 'List sales',
      description: 'Get all sales with filtering and pagination'
    }
  })

  // Get sale by ID
  .get('/:id', async ({ params: { id } }) => {
    try {
      const sale = await prisma.sale.findUnique({
        where: { id },
        include: {
          contact: true,
          property: true
        }
      });

      if (!sale) {
        return {
          success: false,
          error: 'Sale not found'
        };
      }

      return {
        success: true,
        data: sale
      };
    } catch (error) {
      console.error('Get sale error:', error);
      return {
        success: false,
        error: 'Failed to fetch sale'
      };
    }
  }, {
    detail: {
      tags: ['Sales'],
      summary: 'Get sale by ID',
      description: 'Get a specific sale with contact and property details'
    }
  })

  // Create new sale (triggers learning)
  .post('/', async ({ body }) => {
    try {
      const {
        contactId,
        propertyId,
        salePrice,
        successScore,
        timeToDecision,
        viewCount,
        notes
      } = body;

      // Verify contact and property exist
      const [contact, property] = await Promise.all([
        prisma.contact.findUnique({ where: { id: contactId } }),
        prisma.property.findUnique({ where: { id: propertyId } })
      ]);

      if (!contact) {
        return {
          success: false,
          error: 'Contact not found'
        };
      }

      if (!property) {
        return {
          success: false,
          error: 'Property not found'
        };
      }

      // Create the sale
      const sale = await prisma.sale.create({
        data: {
          contactId,
          propertyId,
          salePrice,
          successScore,
          timeToDecision,
          viewCount,
          notes,
          saleDate: new Date()
        }
      });

      // Learn from this sale if it was successful
      if (successScore >= 0.6) {
        try {
          const updatedScores = learnFromSale(contact as any, property, { successScore, salePrice });
          
          await prisma.contact.update({
            where: { id: contactId },
            data: { scores: updatedScores }
          });

          console.log(`Learning applied: Updated contact ${contactId} preferences based on successful sale`);
        } catch (learningError) {
          console.error('Learning error:', learningError);
          // Don't fail the sale creation if learning fails
        }
      }

      // Trigger collaborative learning for similar users and properties
      try {
        const { processLearningForSale } = await import('../services/learning');
        const learningResult = await processLearningForSale(sale.id);
        
        if (learningResult.success) {
          console.log(`Collaborative learning triggered: ${learningResult.usersAffected} users, ${learningResult.propertiesAffected} properties affected`);
        } else {
          console.log('Collaborative learning disabled or failed');
        }
      } catch (collaborativeLearningError) {
        console.error('Collaborative learning error:', collaborativeLearningError);
        // Don't fail the sale creation if collaborative learning fails
      }

      // Update property status if it was sold
      if (property.transactionType === 'SALE') {
        await prisma.property.update({
          where: { id: propertyId },
          data: { status: 'SOLD' }
        });
      } else {
        await prisma.property.update({
          where: { id: propertyId },
          data: { status: 'RENTED' }
        });
      }

      return {
        success: true,
        data: sale,
        message: 'Sale recorded successfully and learning applied'
      };
    } catch (error) {
      console.error('Create sale error:', error);
      return {
        success: false,
        error: 'Failed to create sale'
      };
    }
  }, {
    body: t.Object({
      contactId: t.String(),
      propertyId: t.String(),
      salePrice: t.Number({ minimum: 0 }),
      successScore: t.Number({ minimum: 0, maximum: 1 }),
      timeToDecision: t.Optional(t.Number({ minimum: 0 })),
      viewCount: t.Optional(t.Number({ minimum: 0 })),
      notes: t.Optional(t.String())
    }),
    detail: {
      tags: ['Sales'],
      summary: 'Create sale',
      description: 'Record a new sale and trigger learning algorithm'
    }
  })

  // Update sale
  .put('/:id', async ({ params: { id }, body }) => {
    try {
      const sale = await prisma.sale.findUnique({ where: { id } });
      if (!sale) {
        return {
          success: false,
          error: 'Sale not found'
        };
      }

      const updatedSale = await prisma.sale.update({
        where: { id },
        data: body as any
      });

      return {
        success: true,
        data: updatedSale,
        message: 'Sale updated successfully'
      };
    } catch (error) {
      console.error('Update sale error:', error);
      return {
        success: false,
        error: 'Failed to update sale'
      };
    }
  }, {
    detail: {
      tags: ['Sales'],
      summary: 'Update sale',
      description: 'Update sale details'
    }
  })

  // Delete sale
  .delete('/:id', async ({ params: { id } }) => {
    try {
      const sale = await prisma.sale.findUnique({ where: { id } });
      if (!sale) {
        return {
          success: false,
          error: 'Sale not found'
        };
      }

      await prisma.sale.delete({ where: { id } });

      return {
        success: true,
        message: 'Sale deleted successfully'
      };
    } catch (error) {
      console.error('Delete sale error:', error);
      return {
        success: false,
        error: 'Failed to delete sale'
      };
    }
  }, {
    detail: {
      tags: ['Sales'],
      summary: 'Delete sale',
      description: 'Delete a sale record'
    }
  })

  // Get sales analytics
  .get('/analytics', async () => {
    try {
      const [
        totalSales,
        avgSuccessScore,
        salesByMonth,
        topPerformingContacts,
        topPerformingProperties
      ] = await Promise.all([
        prisma.sale.count(),
        prisma.sale.aggregate({
          _avg: { successScore: true }
        }),
        prisma.sale.groupBy({
          by: ['saleDate'],
          _count: { id: true },
          _avg: { successScore: true },
          orderBy: { saleDate: 'desc' },
          take: 12
        }),
        prisma.sale.groupBy({
          by: ['contactId'],
          _count: { id: true },
          _avg: { successScore: true },
          orderBy: { _count: { id: 'desc' } },
          take: 10
        }),
        prisma.sale.groupBy({
          by: ['propertyId'],
          _count: { id: true },
          _avg: { successScore: true },
          orderBy: { _avg: { successScore: 'desc' } },
          take: 10
        })
      ]);

      return {
        success: true,
        data: {
          overview: {
            totalSales,
            averageSuccessScore: avgSuccessScore._avg.successScore || 0
          },
          trends: {
            salesByMonth
          },
          performance: {
            topContacts: topPerformingContacts,
            topProperties: topPerformingProperties
          }
        }
      };
    } catch (error) {
      console.error('Sales analytics error:', error);
      return {
        success: false,
        error: 'Failed to fetch sales analytics'
      };
    }
  }, {
    detail: {
      tags: ['Sales'],
      summary: 'Sales analytics',
      description: 'Get sales performance analytics and trends'
    }
  }); 