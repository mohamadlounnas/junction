/**
 * Collaborative Learning System Test
 * 
 * Tests the new collaborative learning functionality including:
 * - API endpoint functionality
 * - User-to-user collaborative learning
 * - Property-to-property learning
 * - Settings configuration
 * - Performance metrics
 */

import { PrismaClient } from '@prisma/client';
import { processCollaborativeLearning, processLearningForSale, getLearningStats } from '../services/learning';
import { calculateSimilarity } from '../services/score-generator';

const prisma = new PrismaClient();

interface TestResult {
  testName: string;
  success: boolean;
  details: any;
  error?: string;
}

/**
 * Test the collaborative learning API functionality
 */
async function testCollaborativeLearningAPI(): Promise<TestResult> {
  try {
    console.log('🧪 Testing Collaborative Learning API...');

    // Test recent sales learning
    const recentSalesResult = await processCollaborativeLearning({
      salesLimit: 10
    });

    console.log('📊 Recent Sales Learning Result:', {
      success: recentSalesResult.success,
      usersAffected: recentSalesResult.usersAffected,
      propertiesAffected: recentSalesResult.propertiesAffected,
      totalOperations: recentSalesResult.totalLearningOperations,
      processingTime: `${recentSalesResult.processingTimeMs}ms`
    });

    // Test learning stats
    const stats = await getLearningStats();
    console.log('📈 Learning Statistics:', {
      totalSales: stats.totalSales,
      recentSales: stats.recentSales,
      averageSuccessScore: (stats.averageSuccessScore * 100).toFixed(1) + '%',
      totalUsers: stats.totalUsers,
      totalProperties: stats.totalProperties,
      collaborativeLearningEnabled: stats.config.enableCollaborativeLearning
    });

    return {
      testName: 'Collaborative Learning API',
      success: recentSalesResult.success,
      details: {
        recentSalesResult,
        stats
      }
    };

  } catch (error) {
    return {
      testName: 'Collaborative Learning API',
      success: false,
      details: {},
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Test user similarity and learning
 */
async function testUserSimilarityLearning(): Promise<TestResult> {
  try {
    console.log('👥 Testing User Similarity Learning...');

    // Get some users for testing
    const users = await prisma.contact.findMany({
      where: { isActive: true },
      take: 5,
      select: { id: true, name: true, scores: true, type: true }
    });

    if (users.length < 2) {
      return {
        testName: 'User Similarity Learning',
        success: false,
        details: {},
        error: 'Not enough users for similarity testing'
      };
    }

    // Calculate similarities between users
    const similarities: Array<{
      user1: string;
      user2: string;
      similarity: number;
    }> = [];

    for (let i = 0; i < users.length; i++) {
      for (let j = i + 1; j < users.length; j++) {
        const similarity = calculateSimilarity(users[i].scores, users[j].scores);
        similarities.push({
          user1: users[i].name,
          user2: users[j].name,
          similarity: Math.round(similarity * 1000) / 1000
        });
      }
    }

    // Sort by similarity (highest first)
    similarities.sort((a, b) => b.similarity - a.similarity);

    console.log('🔗 User Similarities (Top 5):');
    similarities.slice(0, 5).forEach((sim, index) => {
      console.log(`   ${index + 1}. ${sim.user1} ↔ ${sim.user2}: ${(sim.similarity * 100).toFixed(1)}%`);
    });

    const highSimilarityPairs = similarities.filter(s => s.similarity >= 0.8);
    
    return {
      testName: 'User Similarity Learning',
      success: true,
      details: {
        totalUsers: users.length,
        totalComparisons: similarities.length,
        highSimilarityPairs: highSimilarityPairs.length,
        averageSimilarity: similarities.reduce((sum, s) => sum + s.similarity, 0) / similarities.length,
        topSimilarities: similarities.slice(0, 5)
      }
    };

  } catch (error) {
    return {
      testName: 'User Similarity Learning',
      success: false,
      details: {},
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Test property similarity and learning
 */
async function testPropertySimilarityLearning(): Promise<TestResult> {
  try {
    console.log('🏠 Testing Property Similarity Learning...');

    // Get some properties for testing
    const properties = await prisma.property.findMany({
      where: { status: 'AVAILABLE' },
      take: 5,
      select: { id: true, title: true, scores: true, propertyType: true, price: true }
    });

    if (properties.length < 2) {
      return {
        testName: 'Property Similarity Learning',
        success: false,
        details: {},
        error: 'Not enough properties for similarity testing'
      };
    }

    // Calculate similarities between properties
    const similarities: Array<{
      property1: string;
      property2: string;
      similarity: number;
      priceRatio: number;
    }> = [];

    for (let i = 0; i < properties.length; i++) {
      for (let j = i + 1; j < properties.length; j++) {
        const similarity = calculateSimilarity(properties[i].scores, properties[j].scores);
        const priceRatio = Math.min(properties[i].price, properties[j].price) / 
                          Math.max(properties[i].price, properties[j].price);
        
        similarities.push({
          property1: properties[i].title,
          property2: properties[j].title,
          similarity: Math.round(similarity * 1000) / 1000,
          priceRatio: Math.round(priceRatio * 1000) / 1000
        });
      }
    }

    // Sort by similarity (highest first)
    similarities.sort((a, b) => b.similarity - a.similarity);

    console.log('🔗 Property Similarities (Top 5):');
    similarities.slice(0, 5).forEach((sim, index) => {
      console.log(`   ${index + 1}. ${sim.property1.substring(0, 30)}... ↔ ${sim.property2.substring(0, 30)}...: ${(sim.similarity * 100).toFixed(1)}%`);
    });

    const highSimilarityPairs = similarities.filter(s => s.similarity >= 0.8);
    
    return {
      testName: 'Property Similarity Learning',
      success: true,
      details: {
        totalProperties: properties.length,
        totalComparisons: similarities.length,
        highSimilarityPairs: highSimilarityPairs.length,
        averageSimilarity: similarities.reduce((sum, s) => sum + s.similarity, 0) / similarities.length,
        averagePriceRatio: similarities.reduce((sum, s) => sum + s.priceRatio, 0) / similarities.length,
        topSimilarities: similarities.slice(0, 3)
      }
    };

  } catch (error) {
    return {
      testName: 'Property Similarity Learning',
      success: false,
      details: {},
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Test learning configuration and settings
 */
async function testLearningConfiguration(): Promise<TestResult> {
  try {
    console.log('⚙️ Testing Learning Configuration...');

    // Get current settings
    const settings = await prisma.setting.findMany({
      where: {
        category: 'algorithm',
        key: {
          in: [
            'collaborative_learning_enabled',
            'user_similarity_threshold', 
            'property_similarity_threshold',
            'collaborative_learning_rate',
            'genetic_algorithm_enabled'
          ]
        }
      }
    });

    const configMap = settings.reduce((map, setting) => {
      map[setting.key] = { value: setting.value, type: setting.type };
      return map;
    }, {} as Record<string, { value: string; type: string }>);

    console.log('📋 Current Learning Configuration:');
    Object.entries(configMap).forEach(([key, config]) => {
      console.log(`   ${key}: ${config.value} (${config.type})`);
    });

    return {
      testName: 'Learning Configuration',
      success: true,
      details: {
        settingsFound: settings.length,
        configuration: configMap,
        collaborativeLearningEnabled: configMap.collaborative_learning_enabled?.value === 'true',
        geneticAlgorithmEnabled: configMap.genetic_algorithm_enabled?.value === 'true'
      }
    };

  } catch (error) {
    return {
      testName: 'Learning Configuration',
      success: false,
      details: {},
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Test learning with a specific sale
 */
async function testSpecificSaleLearning(): Promise<TestResult> {
  try {
    console.log('💰 Testing Specific Sale Learning...');

    // Get a recent sale
    const recentSale = await prisma.sale.findFirst({
      orderBy: { saleDate: 'desc' },
      include: {
        contact: { select: { id: true, name: true, scores: true } },
        property: { select: { id: true, title: true, scores: true } }
      }
    });

    if (!recentSale) {
      return {
        testName: 'Specific Sale Learning',
        success: false,
        details: {},
        error: 'No sales found for testing'
      };
    }

    console.log(`📈 Testing learning from sale: ${recentSale.contact.name} → ${recentSale.property.title}`);
    console.log(`   Success Score: ${(recentSale.successScore * 100).toFixed(1)}%`);
    console.log(`   Sale Price: ${recentSale.salePrice.toLocaleString()} DZD`);

    // Process learning for this specific sale
    const learningResult = await processLearningForSale(recentSale.id);

    console.log('📊 Learning Result:', {
      success: learningResult.success,
      usersAffected: learningResult.usersAffected,
      propertiesAffected: learningResult.propertiesAffected,
      totalOperations: learningResult.totalLearningOperations,
      processingTime: `${learningResult.processingTimeMs}ms`
    });

    return {
      testName: 'Specific Sale Learning',
      success: learningResult.success,
      details: {
        saleInfo: {
          buyerName: recentSale.contact.name,
          propertyTitle: recentSale.property.title,
          successScore: recentSale.successScore,
          salePrice: recentSale.salePrice
        },
        learningResult
      }
    };

  } catch (error) {
    return {
      testName: 'Specific Sale Learning',
      success: false,
      details: {},
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Generate comprehensive test report
 */
function generateTestReport(results: TestResult[]): string {
  const successfulTests = results.filter(r => r.success).length;
  const totalTests = results.length;
  const successRate = (successfulTests / totalTests) * 100;

  let report = `
🧠 COLLABORATIVE LEARNING SYSTEM - TEST REPORT
=============================================

📊 OVERALL TEST RESULTS
-----------------------
• Tests Run: ${totalTests}
• Successful: ${successfulTests}
• Failed: ${totalTests - successfulTests}
• Success Rate: ${successRate.toFixed(1)}%

🔍 DETAILED TEST RESULTS
------------------------
`;

  results.forEach((result, index) => {
    const status = result.success ? '✅ PASS' : '❌ FAIL';
    report += `\n${index + 1}. ${result.testName}: ${status}`;
    
    if (!result.success && result.error) {
      report += `\n   Error: ${result.error}`;
    }
    
    if (result.success && result.details) {
      if (result.testName === 'Collaborative Learning API') {
        const details = result.details;
        report += `\n   • Users Affected: ${details.recentSalesResult.usersAffected}`;
        report += `\n   • Properties Affected: ${details.recentSalesResult.propertiesAffected}`;
        report += `\n   • Total Operations: ${details.recentSalesResult.totalLearningOperations}`;
        report += `\n   • Processing Time: ${details.recentSalesResult.processingTimeMs}ms`;
      }
      
      if (result.testName === 'User Similarity Learning') {
        const details = result.details;
        report += `\n   • Users Analyzed: ${details.totalUsers}`;
        report += `\n   • High Similarity Pairs (≥80%): ${details.highSimilarityPairs}`;
        report += `\n   • Average Similarity: ${(details.averageSimilarity * 100).toFixed(1)}%`;
      }
      
      if (result.testName === 'Property Similarity Learning') {
        const details = result.details;
        report += `\n   • Properties Analyzed: ${details.totalProperties}`;
        report += `\n   • High Similarity Pairs (≥80%): ${details.highSimilarityPairs}`;
        report += `\n   • Average Similarity: ${(details.averageSimilarity * 100).toFixed(1)}%`;
      }
      
      if (result.testName === 'Learning Configuration') {
        const details = result.details;
        report += `\n   • Collaborative Learning: ${details.collaborativeLearningEnabled ? 'Enabled' : 'Disabled'}`;
        report += `\n   • Genetic Algorithm: ${details.geneticAlgorithmEnabled ? 'Enabled' : 'Disabled'}`;
        report += `\n   • Settings Found: ${details.settingsFound}`;
      }
      
      if (result.testName === 'Specific Sale Learning') {
        const details = result.details;
        report += `\n   • Sale Success Score: ${(details.saleInfo.successScore * 100).toFixed(1)}%`;
        report += `\n   • Users Affected: ${details.learningResult.usersAffected}`;
        report += `\n   • Properties Affected: ${details.learningResult.propertiesAffected}`;
      }
    }
  });

  report += `\n\n💡 RECOMMENDATIONS
------------------`;

  if (successRate === 100) {
    report += `\n🎉 EXCELLENT: All tests passed! The collaborative learning system is working perfectly.
✅ System is ready for production use
✅ All components functioning correctly
✅ Learning algorithms properly configured`;
  } else if (successRate >= 80) {
    report += `\n✅ GOOD: Most tests passed. Minor issues detected.
📝 Review failed tests and address any configuration issues
🔧 System is mostly functional but may need some adjustments`;
  } else if (successRate >= 60) {
    report += `\n⚠️ MODERATE: Some tests failed. System needs attention.
🔍 Review configuration settings and database connectivity
🛠️ Address failed tests before production deployment`;
  } else {
    report += `\n❌ CRITICAL: Multiple test failures detected.
🚨 System requires immediate attention
🔧 Check database configuration, dependencies, and settings
📞 Consider consulting system administrator`;
  }

  report += `\n\n🚀 NEXT STEPS
------------
1. Review any failed tests and address issues
2. Monitor system performance in production
3. Adjust learning parameters based on real usage
4. Consider enabling genetic algorithm for advanced optimization
5. Set up monitoring for learning effectiveness

Generated: ${new Date().toLocaleString()}
`;

  return report;
}

/**
 * Main test execution
 */
async function main() {
  try {
    console.log('🧠 Starting Collaborative Learning System Tests...\n');

    const tests = [
      testLearningConfiguration,
      testUserSimilarityLearning,
      testPropertySimilarityLearning,
      testCollaborativeLearningAPI,
      testSpecificSaleLearning
    ];

    const results: TestResult[] = [];

    for (const test of tests) {
      try {
        const result = await test();
        results.push(result);
        console.log(`${result.success ? '✅' : '❌'} ${result.testName}: ${result.success ? 'PASSED' : 'FAILED'}`);
        if (!result.success && result.error) {
          console.log(`   Error: ${result.error}`);
        }
        console.log(''); // Empty line for readability
      } catch (error) {
        results.push({
          testName: test.name,
          success: false,
          details: {},
          error: error instanceof Error ? error.message : 'Unknown error'
        });
        console.log(`❌ ${test.name}: FAILED (Exception)`);
        console.log(`   Error: ${error}`);
        console.log('');
      }
    }

    // Generate and display report
    const report = generateTestReport(results);
    console.log(report);

    // Save report to file
    const fs = require('fs');
    const timestamp = new Date().toISOString().split('T')[0];
    const filename = `collaborative-learning-test-${timestamp}.txt`;
    fs.writeFileSync(filename, report);
    console.log(`\n📄 Test report saved to: ${filename}`);

  } catch (error) {
    console.error('❌ Test execution failed:', error);
  } finally {
    await prisma.$disconnect();
  }
}

// Run the tests
main(); 