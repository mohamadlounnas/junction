import { PrismaClient } from '@prisma/client';
import * as GeneticAlgorithm from '../services/genetic-algorithm';
import * as ScoreGenerator from '../services/score-generator';

const prisma = new PrismaClient();

interface TestResult {
  method: string;
  accuracy: number;
  precision: number;
  recall: number;
  f1Score: number;
  executionTime: number;
  recommendationsGenerated: number;
  averageScore: number;
  scoreVariance: number;
}

class ComprehensiveComparisonTest {
  constructor() {
    // Services are imported as modules, not classes
  }

  async runComparison(): Promise<void> {
    console.log('🏁 Starting Comprehensive Comparison Test');
    console.log('=' .repeat(80));

    // Get test users and properties
    const testUsers = await this.getTestUsers();
    const testProperties = await this.getTestProperties();

    console.log(`📊 Test Setup:`);
    console.log(`   - Users: ${testUsers.length}`);
    console.log(`   - Properties: ${testProperties.length}`);
    console.log();

    // Test 1: Normal Value-Based Scoring
    console.log('🔍 Test 1: Normal Value-Based Scoring');
    const normalResults = await this.testNormalScoring(testUsers, testProperties);
    console.log();

    // Test 2: Genetic Algorithm Optimization
    console.log('🧬 Test 2: Genetic Algorithm Optimization');
    const geneticResults = await this.testGeneticOptimization(testUsers, testProperties);
    console.log();

    // Test 3: Hybrid Approach
    console.log('🔄 Test 3: Hybrid Approach (Normal + Genetic Refinement)');
    const hybridResults = await this.testHybridApproach(testUsers, testProperties);
    console.log();

    // Generate comprehensive report
    await this.generateReport([normalResults, geneticResults, hybridResults]);
  }

  private async getTestUsers() {
    return await prisma.contact.findMany({
      take: 20, // Reduced for testing
      include: {
        sales: {
          include: {
            property: true
          }
        }
      }
    });
  }

  private async getTestProperties() {
    return await prisma.property.findMany({
      take: 50, // Reduced for testing
      include: {
        sales: true
      }
    });
  }

  private async testNormalScoring(users: any[], properties: any[]): Promise<TestResult> {
    const startTime = Date.now();
    const results: any[] = [];

    for (const user of users) {
      // Generate scores using the score generator module
      const userScores = ScoreGenerator.generateScoresFromContact(user);
      const recommendations = await this.getRecommendationsNormal(user, properties, userScores);
      
      // Calculate accuracy based on user's historical preferences
      const accuracy = this.calculateAccuracy(user, recommendations);
      results.push({ user, recommendations, accuracy });
    }

    const executionTime = Date.now() - startTime;
    const avgAccuracy = results.reduce((sum, r) => sum + r.accuracy, 0) / results.length;
    
    const allScores = results.flatMap(r => r.recommendations.map((rec: any) => rec.score));
    const avgScore = allScores.reduce((sum, score) => sum + score, 0) / allScores.length;
    const scoreVariance = this.calculateVariance(allScores);

    console.log(`   ✅ Accuracy: ${(avgAccuracy * 100).toFixed(2)}%`);
    console.log(`   ⏱️  Execution Time: ${executionTime}ms`);
    console.log(`   📈 Average Score: ${avgScore.toFixed(2)}`);
    console.log(`   📊 Score Variance: ${scoreVariance.toFixed(2)}`);

    return {
      method: 'Normal Value-Based Scoring',
      accuracy: avgAccuracy,
      precision: this.calculatePrecision(results),
      recall: this.calculateRecall(results),
      f1Score: this.calculateF1Score(results),
      executionTime,
      recommendationsGenerated: results.length * 10,
      averageScore: avgScore,
      scoreVariance
    };
  }

  private async testGeneticOptimization(users: any[], properties: any[]): Promise<TestResult> {
    const startTime = Date.now();
    
    // Run genetic algorithm optimization for one user as example
    const testUser = users[0];
    const baseVector = ScoreGenerator.generateScoresFromContact(testUser);
    const geneticResult = await GeneticAlgorithm.runGeneticOptimization(testUser.id, baseVector);
    
    // Apply genetic optimization to all users
    const results: any[] = [];
    for (const user of users) {
      const userScores = ScoreGenerator.generateScoresFromContact(user);
      const optimizedScores = await this.applyGeneticOptimization(user, userScores);
      const recommendations = await this.getRecommendationsGenetic(user, properties, optimizedScores);
      
      const accuracy = this.calculateAccuracy(user, recommendations);
      results.push({ user, recommendations, accuracy });
    }

    const executionTime = Date.now() - startTime;
    const avgAccuracy = results.reduce((sum, r) => sum + r.accuracy, 0) / results.length;
    
    const allScores = results.flatMap(r => r.recommendations.map((rec: any) => rec.score));
    const avgScore = allScores.reduce((sum, score) => sum + score, 0) / allScores.length;
    const scoreVariance = this.calculateVariance(allScores);

    console.log(`   ✅ Accuracy: ${(avgAccuracy * 100).toFixed(2)}%`);
    console.log(`   ⏱️  Execution Time: ${executionTime}ms`);
    console.log(`   🧬 Genetic Improvement: ${(geneticResult.improvement * 100).toFixed(2)}%`);
    console.log(`   📈 Average Score: ${avgScore.toFixed(2)}`);
    console.log(`   📊 Score Variance: ${scoreVariance.toFixed(2)}`);

    return {
      method: 'Genetic Algorithm Optimization',
      accuracy: avgAccuracy,
      precision: this.calculatePrecision(results),
      recall: this.calculateRecall(results),
      f1Score: this.calculateF1Score(results),
      executionTime,
      recommendationsGenerated: results.length * 10,
      averageScore: avgScore,
      scoreVariance
    };
  }

  private async testHybridApproach(users: any[], properties: any[]): Promise<TestResult> {
    const startTime = Date.now();
    
    const results: any[] = [];
    for (const user of users) {
      // Generate normal scores first
      const baseScores = ScoreGenerator.generateScoresFromContact(user);
      
      // Apply genetic algorithm refinement
      const refinedScores = await this.applyGeneticOptimization(user, baseScores);
      const recommendations = await this.getRecommendationsHybrid(user, properties, baseScores, refinedScores);
      
      const accuracy = this.calculateAccuracy(user, recommendations);
      results.push({ user, recommendations, accuracy });
    }

    const executionTime = Date.now() - startTime;
    const avgAccuracy = results.reduce((sum, r) => sum + r.accuracy, 0) / results.length;
    
    const allScores = results.flatMap(r => r.recommendations.map((rec: any) => rec.score));
    const avgScore = allScores.reduce((sum, score) => sum + score, 0) / allScores.length;
    const scoreVariance = this.calculateVariance(allScores);

    console.log(`   ✅ Accuracy: ${(avgAccuracy * 100).toFixed(2)}%`);
    console.log(`   ⏱️  Execution Time: ${executionTime}ms`);
    console.log(`   🔄 Hybrid: Normal + Genetic Refinement`);
    console.log(`   📈 Average Score: ${avgScore.toFixed(2)}`);
    console.log(`   📊 Score Variance: ${scoreVariance.toFixed(2)}`);

    return {
      method: 'Hybrid Approach (Normal + Genetic Refinement)',
      accuracy: avgAccuracy,
      precision: this.calculatePrecision(results),
      recall: this.calculateRecall(results),
      f1Score: this.calculateF1Score(results),
      executionTime,
      recommendationsGenerated: results.length * 10,
      averageScore: avgScore,
      scoreVariance
    };
  }

  private async getRecommendationsNormal(user: any, properties: any[], userScores: number[]) {
    const recommendations = properties
      .filter(property => property.status === 'AVAILABLE')
      .map(property => {
        const similarity = ScoreGenerator.calculateSimilarity(userScores, property.scores);
        return {
          propertyId: property.id,
          property,
          score: similarity
        };
      })
      .sort((a, b) => b.score - a.score)
      .slice(0, 10);
    
    return recommendations;
  }

  private async getRecommendationsGenetic(user: any, properties: any[], optimizedScores: number[]) {
    const recommendations = properties
      .filter(property => property.status === 'AVAILABLE')
      .map(property => {
        const similarity = ScoreGenerator.calculateSimilarity(optimizedScores, property.scores);
        return {
          propertyId: property.id,
          property,
          score: similarity
        };
      })
      .sort((a, b) => b.score - a.score)
      .slice(0, 10);
    
    return recommendations;
  }

  private async getRecommendationsHybrid(user: any, properties: any[], baseScores: number[], refinedScores: number[]) {
    const recommendations = properties
      .filter(property => property.status === 'AVAILABLE')
      .map(property => {
        const baseSimilarity = ScoreGenerator.calculateSimilarity(baseScores, property.scores);
        const refinedSimilarity = ScoreGenerator.calculateSimilarity(refinedScores, property.scores);
        // Combine both scores with weight
        const hybridScore = baseSimilarity * 0.3 + refinedSimilarity * 0.7;
        return {
          propertyId: property.id,
          property,
          score: hybridScore
        };
      })
      .sort((a, b) => b.score - a.score)
      .slice(0, 10);
    
    return recommendations;
  }

  private async applyGeneticOptimization(user: any, baseScores: number[]): Promise<number[]> {
    try {
      // Run genetic optimization
      const result = await GeneticAlgorithm.runGeneticOptimization(user.id, baseScores);
      return result.bestIndividual.vector;
    } catch (error) {
      console.log(`   ⚠️  Genetic optimization failed for user ${user.id}, using base scores`);
      return baseScores;
    }
  }

  private calculateAccuracy(user: any, recommendations: any[]): number {
    if (!user.sales || user.sales.length === 0) return 0.5; // Default for users with no history
    
    const userPreferences = new Set(user.sales.map((sale: any) => sale.property.id));
    const recommendedIds = new Set(recommendations.map(rec => rec.propertyId));
    
    const intersection = new Set([...userPreferences].filter(x => recommendedIds.has(x)));
    return intersection.size / Math.max(userPreferences.size, 1);
  }

  private calculatePrecision(results: any[]): number {
    // Calculate precision across all results
    let totalPrecision = 0;
    let validResults = 0;
    
    for (const result of results) {
      if (result.user.sales && result.user.sales.length > 0) {
        const userPreferences = new Set(result.user.sales.map((sale: any) => sale.property.id));
        const recommendedIds = new Set(result.recommendations.map((rec: any) => rec.propertyId));
        
        const intersection = new Set([...userPreferences].filter(x => recommendedIds.has(x)));
        const precision = intersection.size / Math.max(recommendedIds.size, 1);
        totalPrecision += precision;
        validResults++;
      }
    }
    
    return validResults > 0 ? totalPrecision / validResults : 0;
  }

  private calculateRecall(results: any[]): number {
    // Calculate recall across all results
    let totalRecall = 0;
    let validResults = 0;
    
    for (const result of results) {
      if (result.user.sales && result.user.sales.length > 0) {
        const userPreferences = new Set(result.user.sales.map((sale: any) => sale.property.id));
        const recommendedIds = new Set(result.recommendations.map((rec: any) => rec.propertyId));
        
        const intersection = new Set([...userPreferences].filter(x => recommendedIds.has(x)));
        const recall = intersection.size / Math.max(userPreferences.size, 1);
        totalRecall += recall;
        validResults++;
      }
    }
    
    return validResults > 0 ? totalRecall / validResults : 0;
  }

  private calculateF1Score(results: any[]): number {
    const precision = this.calculatePrecision(results);
    const recall = this.calculateRecall(results);
    
    if (precision + recall === 0) return 0;
    return (2 * precision * recall) / (precision + recall);
  }

  private calculateVariance(scores: number[]): number {
    if (scores.length === 0) return 0;
    
    const mean = scores.reduce((sum, score) => sum + score, 0) / scores.length;
    const squaredDifferences = scores.map(score => Math.pow(score - mean, 2));
    return squaredDifferences.reduce((sum, diff) => sum + diff, 0) / scores.length;
  }

  private async generateReport(results: TestResult[]): Promise<void> {
    console.log('📊 COMPREHENSIVE COMPARISON REPORT');
    console.log('=' .repeat(80));
    
    // Sort results by accuracy
    const sortedResults = results.sort((a, b) => b.accuracy - a.accuracy);
    
    console.log('🏆 RANKING BY ACCURACY:');
    sortedResults.forEach((result, index) => {
      console.log(`${index + 1}. ${result.method}`);
      console.log(`   Accuracy: ${(result.accuracy * 100).toFixed(2)}%`);
      console.log(`   F1-Score: ${(result.f1Score * 100).toFixed(2)}%`);
      console.log(`   Execution Time: ${result.executionTime}ms`);
      console.log();
    });

    console.log('📈 DETAILED METRICS:');
    console.log('-' .repeat(60));
    console.log('Method'.padEnd(35) + 'Accuracy'.padEnd(12) + 'F1-Score'.padEnd(12) + 'Time(ms)'.padEnd(12) + 'Avg Score'.padEnd(12));
    console.log('-'.repeat(83));
    
    results.forEach(result => {
      console.log(
        result.method.padEnd(35) +
        `${(result.accuracy * 100).toFixed(1)}%`.padEnd(12) +
        `${(result.f1Score * 100).toFixed(1)}%`.padEnd(12) +
        `${result.executionTime}`.padEnd(12) +
        `${result.averageScore.toFixed(2)}`.padEnd(12)
      );
    });

    console.log();
    console.log('🎯 KEY INSIGHTS:');
    console.log('-' .repeat(60));
    
    const bestMethod = sortedResults[0];
    const worstMethod = sortedResults[sortedResults.length - 1];
    
    console.log(`✅ Best Performing Method: ${bestMethod.method}`);
    console.log(`   - Accuracy: ${(bestMethod.accuracy * 100).toFixed(2)}%`);
    console.log(`   - F1-Score: ${(bestMethod.f1Score * 100).toFixed(2)}%`);
    
    console.log(`❌ Worst Performing Method: ${worstMethod.method}`);
    console.log(`   - Accuracy: ${(worstMethod.accuracy * 100).toFixed(2)}%`);
    console.log(`   - F1-Score: ${(worstMethod.f1Score * 100).toFixed(2)}%`);
    
    const accuracyImprovement = ((bestMethod.accuracy - worstMethod.accuracy) / worstMethod.accuracy) * 100;
    console.log(`📈 Accuracy Improvement: ${accuracyImprovement.toFixed(1)}%`);
    
    console.log();
    console.log('💡 RECOMMENDATIONS:');
    console.log('-' .repeat(60));
    
    if (bestMethod.method.includes('Genetic')) {
      console.log('🧬 Genetic Algorithm shows superior performance');
      console.log('   - Consider implementing as primary recommendation engine');
      console.log('   - Monitor computational costs for large-scale deployment');
    } else if (bestMethod.method.includes('Hybrid')) {
      console.log('🔄 Hybrid approach provides best balance');
      console.log('   - Use normal scoring for initial recommendations');
      console.log('   - Apply genetic optimization for refinement');
    } else {
      console.log('📊 Normal scoring performs adequately');
      console.log('   - Consider genetic optimization for edge cases');
      console.log('   - Monitor for performance degradation with scale');
    }

    // Save report to file
    const reportContent = this.generateDetailedReport(results);
    await this.saveReport(reportContent);
  }

  private generateDetailedReport(results: TestResult[]): string {
    const timestamp = new Date().toISOString();
    const bestMethod = results.sort((a, b) => b.accuracy - a.accuracy)[0];
    
    return `# Comprehensive Comparison Test Report
Generated: ${timestamp}

## Executive Summary
The comparison test evaluated three recommendation approaches:
1. Normal Value-Based Scoring
2. Genetic Algorithm Optimization  
3. Hybrid Approach (Normal + Genetic Refinement)

**Best Performing Method**: ${bestMethod.method}
**Accuracy**: ${(bestMethod.accuracy * 100).toFixed(2)}%
**F1-Score**: ${(bestMethod.f1Score * 100).toFixed(2)}%

## Detailed Results

${results.map(result => `
### ${result.method}
- **Accuracy**: ${(result.accuracy * 100).toFixed(2)}%
- **Precision**: ${(result.precision * 100).toFixed(2)}%
- **Recall**: ${(result.recall * 100).toFixed(2)}%
- **F1-Score**: ${(result.f1Score * 100).toFixed(2)}%
- **Execution Time**: ${result.executionTime}ms
- **Recommendations Generated**: ${result.recommendationsGenerated}
- **Average Score**: ${result.averageScore.toFixed(2)}
- **Score Variance**: ${result.scoreVariance.toFixed(2)}
`).join('')}

## Recommendations

${this.getRecommendations(results)}

## Technical Details
- Test Users: 20
- Test Properties: 50
- Genetic Algorithm Population: 20
- Genetic Algorithm Generations: 50
- Convergence Threshold: 0.001

## Next Steps
1. Implement the best performing method in production
2. Set up monitoring for recommendation quality
3. Establish A/B testing framework
4. Plan for scaling considerations
`;
  }

  private getRecommendations(results: TestResult[]): string {
    const bestMethod = results.sort((a, b) => b.accuracy - a.accuracy)[0];
    
    if (bestMethod.method.includes('Genetic')) {
      return `
### Primary Recommendation: Genetic Algorithm
- **Implementation**: Deploy genetic algorithm as primary recommendation engine
- **Monitoring**: Track computational performance and memory usage
- **Optimization**: Tune population size and generation count based on load
- **Fallback**: Keep normal scoring as backup for high-load scenarios

### Performance Considerations
- Genetic algorithm requires more computational resources
- Consider batch processing for optimization runs
- Implement caching for optimized weights
- Monitor convergence patterns for early stopping
`;
    } else if (bestMethod.method.includes('Hybrid')) {
      return `
### Primary Recommendation: Hybrid Approach
- **Implementation**: Use normal scoring for initial recommendations
- **Refinement**: Apply genetic optimization for high-value users
- **Tiering**: Implement user tiers based on engagement level
- **Scaling**: Gradually increase genetic optimization coverage

### Operational Strategy
- Start with normal scoring for all users
- Apply genetic refinement to premium users
- Monitor performance impact and user satisfaction
- Scale genetic optimization based on business metrics
`;
    } else {
      return `
### Primary Recommendation: Normal Scoring
- **Implementation**: Continue with current value-based scoring
- **Enhancement**: Consider genetic optimization for specific use cases
- **Monitoring**: Track recommendation quality metrics
- **Improvement**: Focus on feature engineering and data quality

### Optimization Opportunities
- Improve feature weights through A/B testing
- Add more sophisticated similarity metrics
- Implement collaborative filtering components
- Consider genetic optimization for parameter tuning
`;
    }
  }

  private async saveReport(content: string): Promise<void> {
    const fs = require('fs');
    const path = require('path');
    
    const reportPath = path.join(__dirname, '../../reports/comparison-test-report.md');
    const reportDir = path.dirname(reportPath);
    
    if (!fs.existsSync(reportDir)) {
      fs.mkdirSync(reportDir, { recursive: true });
    }
    
    fs.writeFileSync(reportPath, content);
    console.log(`📄 Report saved to: ${reportPath}`);
  }
}

// Run the comparison test
async function main() {
  try {
    const test = new ComprehensiveComparisonTest();
    await test.runComparison();
  } catch (error) {
    console.error('❌ Test failed:', error);
  } finally {
    await prisma.$disconnect();
  }
}

main(); 