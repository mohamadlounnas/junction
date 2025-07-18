/**
 * Collaborative Learning Service for Algeria Real Estate AI
 * 
 * Implements advanced collaborative learning algorithms that allow users and properties
 * to learn from successful sales transactions of similar entities.
 * 
 * Key Features:
 * - User-to-User collaborative learning (similar users learn from each other's successful purchases)
 * - Property-to-Property learning (similar properties adapt based on successful sales)
 * - Configurable similarity thresholds and learning parameters
 * - Background processing for genetic algorithm optimization
 * - Real-time learning triggers on new sales
 */

import { PrismaClient } from '@prisma/client';
import { 
  calculateSimilarity, 
  collaborativeLearningFromSale,
  propertyLearningFromSale,
  batchCollaborativeLearning,
  calculateCombinedScore
} from './score-generator';
import { runGeneticOptimization } from './genetic-algorithm';

const prisma = new PrismaClient();

export interface LearningConfig {
  userSimilarityThreshold: number;
  propertySimilarityThreshold: number;
  baseLearningRate: number;
  enableTimeWeighting: boolean;
  enableSuccessWeighting: boolean;
  enableCollaborativeLearning: boolean;
  autoLearnOnSale: boolean;
  geneticAlgorithmEnabled: boolean;
}

export interface LearningResult {
  success: boolean;
  usersAffected: number;
  propertiesAffected: number;
  totalLearningOperations: number;
  processingTimeMs: number;
  salesProcessed: number;
  geneticOptimizationTriggered?: boolean;
  errors?: string[];
}

/**
 * Get learning configuration from settings
 */
export async function getLearningConfig(): Promise<LearningConfig> {
  const settings = await prisma.setting.findMany({
    where: {
      key: {
        in: [
          'user_similarity_threshold',
          'property_similarity_threshold', 
          'collaborative_learning_rate',
          'enable_time_weighting',
          'enable_success_weighting',
          'collaborative_learning_enabled',
          'auto_learn_on_sale',
          'genetic_algorithm_enabled'
        ]
      }
    }
  });

  const config: LearningConfig = {
    userSimilarityThreshold: 0.8,
    propertySimilarityThreshold: 0.8,
    baseLearningRate: 0.1,
    enableTimeWeighting: true,
    enableSuccessWeighting: true,
    enableCollaborativeLearning: true,
    autoLearnOnSale: true,
    geneticAlgorithmEnabled: false
  };

  // Override with database settings
  settings.forEach(setting => {
    switch (setting.key) {
      case 'user_similarity_threshold':
        config.userSimilarityThreshold = parseFloat(setting.value);
        break;
      case 'property_similarity_threshold':
        config.propertySimilarityThreshold = parseFloat(setting.value);
        break;
      case 'collaborative_learning_rate':
        config.baseLearningRate = parseFloat(setting.value);
        break;
      case 'enable_time_weighting':
        config.enableTimeWeighting = setting.value === 'true';
        break;
      case 'enable_success_weighting':
        config.enableSuccessWeighting = setting.value === 'true';
        break;
      case 'collaborative_learning_enabled':
        config.enableCollaborativeLearning = setting.value === 'true';
        break;
      case 'auto_learn_on_sale':
        config.autoLearnOnSale = setting.value === 'true';
        break;
      case 'genetic_algorithm_enabled':
        config.geneticAlgorithmEnabled = setting.value === 'true';
        break;
    }
  });

  return config;
}

/**
 * Process collaborative learning for all recent sales
 */
export async function processCollaborativeLearning(options: {
  salesLimit?: number;
  forceReprocess?: boolean;
  config?: Partial<LearningConfig>;
} = {}): Promise<LearningResult> {
  const startTime = Date.now();
  const { salesLimit = 100, forceReprocess = false } = options;
  
  try {
    // Get learning configuration
    const config = { ...await getLearningConfig(), ...options.config };
    
    if (!config.enableCollaborativeLearning) {
      return {
        success: false,
        usersAffected: 0,
        propertiesAffected: 0,
        totalLearningOperations: 0,
        processingTimeMs: Date.now() - startTime,
        salesProcessed: 0,
        errors: ['Collaborative learning is disabled in settings']
      };
    }

    // Get recent sales for learning
    const sales = await prisma.sale.findMany({
      take: salesLimit,
      orderBy: { saleDate: 'desc' },
      include: {
        contact: {
          select: { id: true, scores: true, name: true }
        },
        property: {
          select: { id: true, scores: true, title: true }
        }
      }
    });

    if (sales.length === 0) {
      return {
        success: true,
        usersAffected: 0,
        propertiesAffected: 0,
        totalLearningOperations: 0,
        processingTimeMs: Date.now() - startTime,
        salesProcessed: 0
      };
    }

    // Get all users and properties for collaborative learning
    const allUsers = await prisma.contact.findMany({
      where: { isActive: true },
      select: { id: true, scores: true, name: true }
    });

    const allProperties = await prisma.property.findMany({
      where: { status: 'AVAILABLE' },
      select: { id: true, scores: true, title: true }
    });

    // Prepare sales data for batch processing
    const salesData = sales.map(sale => ({
      contactId: sale.contactId,
      propertyId: sale.propertyId,
      successScore: sale.successScore,
      timeToDecision: sale.timeToDecision || undefined,
      salePrice: sale.salePrice,
      viewCount: sale.viewCount || undefined
    }));

    // Process batch collaborative learning
    const learningResult = batchCollaborativeLearning(
      allUsers,
      allProperties,
      salesData,
      {
        userSimilarityThreshold: config.userSimilarityThreshold,
        propertySimilarityThreshold: config.propertySimilarityThreshold,
        baseLearningRate: config.baseLearningRate
      }
    );

    // Update users in database
    const userUpdatePromises = learningResult.updatedUsers.map(user => 
      prisma.contact.update({
        where: { id: user.id },
        data: { scores: user.scores }
      })
    );

    // Update properties in database  
    const propertyUpdatePromises = learningResult.updatedProperties.map(property =>
      prisma.property.update({
        where: { id: property.id },
        data: { scores: property.scores }
      })
    );

    // Execute all updates
    await Promise.all([...userUpdatePromises, ...propertyUpdatePromises]);

    // Trigger genetic algorithm optimization if enabled
    let geneticOptimizationTriggered = false;
    if (config.geneticAlgorithmEnabled && learningResult.learningStats.usersAffected > 0) {
      // Run genetic optimization in background for affected users
      setImmediate(async () => {
        try {
          const affectedUserIds = learningResult.updatedUsers
            .filter((_, index) => index < learningResult.learningStats.usersAffected)
            .map(user => user.id);
          
          for (const userId of affectedUserIds.slice(0, 5)) { // Limit to 5 users to prevent overload
            const user = learningResult.updatedUsers.find(u => u.id === userId);
            if (user) {
              await runGeneticOptimization(userId, user.scores);
            }
          }
        } catch (error) {
          console.error('Background genetic optimization error:', error);
        }
      });
      geneticOptimizationTriggered = true;
    }

    return {
      success: true,
      usersAffected: learningResult.learningStats.usersAffected,
      propertiesAffected: learningResult.learningStats.propertiesAffected,
      totalLearningOperations: learningResult.learningStats.totalLearningOperations,
      processingTimeMs: Date.now() - startTime,
      salesProcessed: sales.length,
      geneticOptimizationTriggered
    };

  } catch (error) {
    console.error('Collaborative learning error:', error);
    return {
      success: false,
      usersAffected: 0,
      propertiesAffected: 0,
      totalLearningOperations: 0,
      processingTimeMs: Date.now() - startTime,
      salesProcessed: 0,
      errors: [error instanceof Error ? error.message : 'Unknown error']
    };
  }
}

/**
 * Process learning for a specific sale (triggered when new sale is added)
 */
export async function processLearningForSale(saleId: string): Promise<LearningResult> {
  const startTime = Date.now();
  
  try {
    const config = await getLearningConfig();
    
    if (!config.enableCollaborativeLearning || !config.autoLearnOnSale) {
      return {
        success: false,
        usersAffected: 0,
        propertiesAffected: 0,
        totalLearningOperations: 0,
        processingTimeMs: Date.now() - startTime,
        salesProcessed: 0,
        errors: ['Auto-learning is disabled']
      };
    }

    // Get the specific sale
    const sale = await prisma.sale.findUnique({
      where: { id: saleId },
      include: {
        contact: { select: { id: true, scores: true, name: true } },
        property: { select: { id: true, scores: true, title: true } }
      }
    });

    if (!sale) {
      return {
        success: false,
        usersAffected: 0,
        propertiesAffected: 0,
        totalLearningOperations: 0,
        processingTimeMs: Date.now() - startTime,
        salesProcessed: 0,
        errors: ['Sale not found']
      };
    }

    // Get all users except the buyer
    const similarUsers = await prisma.contact.findMany({
      where: { 
        isActive: true,
        NOT: { id: sale.contactId }
      },
      select: { id: true, scores: true, name: true }
    });

    // Get all properties except the sold one
    const similarProperties = await prisma.property.findMany({
      where: { 
        status: 'AVAILABLE',
        NOT: { id: sale.propertyId }
      },
      select: { id: true, scores: true, title: true }
    });

    let usersAffected = 0;
    let propertiesAffected = 0;
    let totalOperations = 0;

    const updatePromises: Promise<any>[] = [];

    // Process similar users
    for (const user of similarUsers) {
      const similarity = calculateSimilarity(user.scores, sale.contact.scores);
      
      if (similarity >= config.userSimilarityThreshold) {
        const newScores = collaborativeLearningFromSale(
          user,
          sale.contact,
          sale.property,
          {
            successScore: sale.successScore,
            timeToDecision: sale.timeToDecision || undefined,
            salePrice: sale.salePrice,
            viewCount: sale.viewCount || undefined
          },
          similarity,
          {
            baseLearningRate: config.baseLearningRate,
            similarityThreshold: config.userSimilarityThreshold,
            enableTimeWeighting: config.enableTimeWeighting,
            enableSuccessWeighting: config.enableSuccessWeighting
          }
        );

        // Check if scores changed significantly
        const changed = newScores.some((score, idx) => 
          Math.abs(score - user.scores[idx]) > 0.001
        );

        if (changed) {
          updatePromises.push(
            prisma.contact.update({
              where: { id: user.id },
              data: { scores: newScores }
            })
          );
          usersAffected++;
          totalOperations++;
        }
      }
    }

    // Process similar properties
    for (const property of similarProperties) {
      const similarity = calculateSimilarity(property.scores, sale.property.scores);
      
      if (similarity >= config.propertySimilarityThreshold) {
        const newScores = propertyLearningFromSale(
          property,
          sale.property,
          sale.contact,
          {
            successScore: sale.successScore,
            timeToDecision: sale.timeToDecision || undefined,
            salePrice: sale.salePrice,
            viewCount: sale.viewCount || undefined
          },
          similarity,
          {
            baseLearningRate: config.baseLearningRate * 0.5, // Lower rate for properties
            similarityThreshold: config.propertySimilarityThreshold
          }
        );

        // Check if scores changed significantly
        const changed = newScores.some((score, idx) => 
          Math.abs(score - property.scores[idx]) > 0.001
        );

        if (changed) {
          updatePromises.push(
            prisma.property.update({
              where: { id: property.id },
              data: { scores: newScores }
            })
          );
          propertiesAffected++;
          totalOperations++;
        }
      }
    }

    // Execute all updates
    await Promise.all(updatePromises);

    // Trigger genetic optimization for the buyer if enabled
    if (config.geneticAlgorithmEnabled && sale.successScore >= 0.7) {
      setImmediate(async () => {
        try {
          await runGeneticOptimization(sale.contactId, sale.contact.scores);
        } catch (error) {
          console.error('Background genetic optimization error:', error);
        }
      });
    }

    return {
      success: true,
      usersAffected,
      propertiesAffected,
      totalLearningOperations: totalOperations,
      processingTimeMs: Date.now() - startTime,
      salesProcessed: 1,
      geneticOptimizationTriggered: config.geneticAlgorithmEnabled && sale.successScore >= 0.7
    };

  } catch (error) {
    console.error('Sale-specific learning error:', error);
    return {
      success: false,
      usersAffected: 0,
      propertiesAffected: 0,
      totalLearningOperations: 0,
      processingTimeMs: Date.now() - startTime,
      salesProcessed: 0,
      errors: [error instanceof Error ? error.message : 'Unknown error']
    };
  }
}

/**
 * Get learning statistics and system health
 */
export async function getLearningStats(): Promise<{
  totalSales: number;
  recentSales: number;
  averageSuccessScore: number;
  totalUsers: number;
  totalProperties: number;
  config: LearningConfig;
  lastProcessedSale?: {
    date: Date;
    successScore: number;
  };
}> {
  const [totalSales, recentSales, allSales, totalUsers, totalProperties, config, lastSale] = await Promise.all([
    prisma.sale.count(),
    prisma.sale.count({
      where: {
        saleDate: {
          gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) // Last 30 days
        }
      }
    }),
    prisma.sale.findMany({
      select: { successScore: true }
    }),
    prisma.contact.count({ where: { isActive: true } }),
    prisma.property.count({ where: { status: 'AVAILABLE' } }),
    getLearningConfig(),
    prisma.sale.findFirst({
      orderBy: { saleDate: 'desc' },
      select: { saleDate: true, successScore: true }
    })
  ]);

  const averageSuccessScore = allSales.length > 0 
    ? allSales.reduce((sum, sale) => sum + sale.successScore, 0) / allSales.length 
    : 0;

  return {
    totalSales,
    recentSales,
    averageSuccessScore,
    totalUsers,
    totalProperties,
    config,
    lastProcessedSale: lastSale ? {
      date: lastSale.saleDate,
      successScore: lastSale.successScore
    } : undefined
  };
} 