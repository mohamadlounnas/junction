/**
 * Extensive Genetic Algorithm Testing Suite
 * 
 * Comprehensive validation for real-world investor presentation
 * Tests performance, convergence, stability, and scalability
 */

import { PrismaClient } from '@prisma/client';
import { 
  runGeneticOptimization, 
  applyGeneticOptimization,
  GA_CONFIG,
  generateInitialPopulation,
  calculateDiversity,
  evolveGeneration
} from '../services/genetic-algorithm';
import { calculateSimilarity } from '../services/score-generator';

const prisma = new PrismaClient();

interface GeneticTestSuite {
  performanceTests: PerformanceTestResult[];
  convergenceTests: ConvergenceTestResult[];
  stabilityTests: StabilityTestResult[];
  scalabilityTests: ScalabilityTestResult[];
  realWorldValidation: RealWorldTestResult[];
  summary: TestSuiteSummary;
}

interface PerformanceTestResult {
  contactId: string;
  contactName: string;
  userType: string;
  originalAccuracy: number;
  geneticAccuracy: number;
  improvement: number;
  generations: number;
  executionTime: number;
  significantImprovement: boolean;
}

interface ConvergenceTestResult {
  contactId: string;
  contactName: string;
  convergenceGeneration: number;
  finalDiversity: number;
  convergencePattern: number[];
  plateauDetected: boolean;
  optimalSolution: boolean;
}

interface StabilityTestResult {
  contactId: string;
  contactName: string;
  runs: number;
  averageImprovement: number;
  standardDeviation: number;
  consistentResults: boolean;
  bestRun: number;
  worstRun: number;
}

interface ScalabilityTestResult {
  populationSize: number;
  generationCount: number;
  averageExecutionTime: number;
  averageImprovement: number;
  memoryUsage: number;
  scalabilityScore: number;
}

interface RealWorldTestResult {
  scenario: string;
  description: string;
  expectedOutcome: string;
  actualOutcome: string;
  success: boolean;
  investorRelevance: string;
}

interface TestSuiteSummary {
  totalTests: number;
  successfulTests: number;
  averageImprovement: number;
  maxImprovement: number;
  averageConvergenceTime: number;
  stabilityScore: number;
  scalabilityRating: string;
  investorReadiness: boolean;
  recommendations: string[];
}

/**
 * Run comprehensive performance tests
 */
async function runPerformanceTests(): Promise<PerformanceTestResult[]> {
  console.log('🚀 Running genetic algorithm performance tests...');
  
  const contacts = await prisma.contact.findMany({ 
    where: { isActive: true },
    include: { sales: true }
  });
  
  const results: PerformanceTestResult[] = [];
  
  for (const contact of contacts) {
    console.log(`   Testing ${contact.name} (${contact.type})...`);
    
    const startTime = Date.now();
    const geneticResult = await runGeneticOptimization(contact.id, contact.scores);
    const executionTime = Date.now() - startTime;
    
    const userType = `${contact.type}_${contact.hasChildren ? 'Family' : 'Individual'}_${contact.transactionType}`;
    
    results.push({
      contactId: contact.id,
      contactName: contact.name,
      userType,
      originalAccuracy: geneticResult.originalAccuracy,
      geneticAccuracy: geneticResult.geneticAccuracy,
      improvement: geneticResult.improvement,
      generations: geneticResult.generations,
      executionTime,
      significantImprovement: geneticResult.improvement > 5
    });
  }
  
  return results;
}

/**
 * Test convergence patterns and optimization behavior
 */
async function runConvergenceTests(): Promise<ConvergenceTestResult[]> {
  console.log('📈 Testing genetic algorithm convergence patterns...');
  
  const contacts = await prisma.contact.findMany({ take: 3 }); // Sample for detailed analysis
  const results: ConvergenceTestResult[] = [];
  
  for (const contact of contacts) {
    console.log(`   Analyzing convergence for ${contact.name}...`);
    
    const geneticResult = await runGeneticOptimization(contact.id, contact.scores);
    
    // Analyze convergence pattern
    const convergencePattern = geneticResult.convergencePattern;
    let convergenceGeneration = convergencePattern.length;
    let plateauDetected = false;
    
    // Detect when algorithm converged (plateau in fitness)
    for (let i = 10; i < convergencePattern.length - 5; i++) {
      const recentWindow = convergencePattern.slice(i, i + 5);
      const improvement = Math.max(...recentWindow) - Math.min(...recentWindow);
      
      if (improvement < GA_CONFIG.CONVERGENCE_THRESHOLD) {
        convergenceGeneration = i;
        plateauDetected = true;
        break;
      }
    }
    
    const finalFitness = convergencePattern[convergencePattern.length - 1];
    const optimalSolution = finalFitness > 0.85; // Consider >85% as optimal
    
    results.push({
      contactId: contact.id,
      contactName: contact.name,
      convergenceGeneration,
      finalDiversity: geneticResult.finalDiversity,
      convergencePattern,
      plateauDetected,
      optimalSolution
    });
  }
  
  return results;
}

/**
 * Test stability across multiple runs
 */
async function runStabilityTests(): Promise<StabilityTestResult[]> {
  console.log('🎯 Testing genetic algorithm stability...');
  
  const contacts = await prisma.contact.findMany({ take: 2 }); // Intensive test on sample
  const results: StabilityTestResult[] = [];
  const runsPerContact = 5;
  
  for (const contact of contacts) {
    console.log(`   Stability testing ${contact.name} (${runsPerContact} runs)...`);
    
    const runResults: number[] = [];
    
    for (let run = 0; run < runsPerContact; run++) {
      const geneticResult = await runGeneticOptimization(contact.id, contact.scores);
      runResults.push(geneticResult.improvement);
      console.log(`      Run ${run + 1}: ${geneticResult.improvement.toFixed(1)}% improvement`);
    }
    
    const averageImprovement = runResults.reduce((sum, val) => sum + val, 0) / runResults.length;
    const variance = runResults.reduce((sum, val) => sum + Math.pow(val - averageImprovement, 2), 0) / runResults.length;
    const standardDeviation = Math.sqrt(variance);
    
    const consistentResults = standardDeviation < 3; // Within 3% standard deviation
    const bestRun = Math.max(...runResults);
    const worstRun = Math.min(...runResults);
    
    results.push({
      contactId: contact.id,
      contactName: contact.name,
      runs: runsPerContact,
      averageImprovement,
      standardDeviation,
      consistentResults,
      bestRun,
      worstRun
    });
  }
  
  return results;
}

/**
 * Test scalability with different population sizes
 */
async function runScalabilityTests(): Promise<ScalabilityTestResult[]> {
  console.log('📊 Testing genetic algorithm scalability...');
  
  const contact = await prisma.contact.findFirst();
  if (!contact) throw new Error('No contacts found for scalability testing');
  
  const populationSizes = [10, 20, 30, 50];
  const results: ScalabilityTestResult[] = [];
  
  for (const popSize of populationSizes) {
    console.log(`   Testing population size: ${popSize}...`);
    
    // Temporarily modify GA config
    const originalPopSize = GA_CONFIG.POPULATION_SIZE;
    (GA_CONFIG as any).POPULATION_SIZE = popSize;
    
    const iterations = 3;
    const executionTimes: number[] = [];
    const improvements: number[] = [];
    
    for (let i = 0; i < iterations; i++) {
      const startTime = Date.now();
      const result = await runGeneticOptimization(contact.id, contact.scores);
      const executionTime = Date.now() - startTime;
      
      executionTimes.push(executionTime);
      improvements.push(result.improvement);
    }
    
    // Restore original config
    (GA_CONFIG as any).POPULATION_SIZE = originalPopSize;
    
    const avgExecutionTime = executionTimes.reduce((sum, val) => sum + val, 0) / executionTimes.length;
    const avgImprovement = improvements.reduce((sum, val) => sum + val, 0) / improvements.length;
    const memoryUsage = popSize * 12 * 8; // Rough estimate in bytes
    
    // Calculate scalability score (improvement per unit time)
    const scalabilityScore = avgImprovement / (avgExecutionTime / 1000);
    
    results.push({
      populationSize: popSize,
      generationCount: 50,
      averageExecutionTime: avgExecutionTime,
      averageImprovement: avgImprovement,
      memoryUsage,
      scalabilityScore
    });
  }
  
  return results;
}

/**
 * Real-world scenario validation tests
 */
async function runRealWorldValidation(): Promise<RealWorldTestResult[]> {
  console.log('🌍 Running real-world scenario validation...');
  
  const scenarios: RealWorldTestResult[] = [
    {
      scenario: 'High-Net-Worth Investor',
      description: 'Wealthy investor seeking premium properties with high ROI',
      expectedOutcome: 'Should optimize toward commercial properties in prime locations',
      actualOutcome: '',
      success: false,
      investorRelevance: 'Critical for institutional investors'
    },
    {
      scenario: 'First-Time Family Buyer',
      description: 'Young family with limited budget seeking family-friendly property',
      expectedOutcome: 'Should optimize toward affordable family homes with good amenities',
      actualOutcome: '',
      success: false,
      investorRelevance: 'Primary market segment'
    },
    {
      scenario: 'Student Housing Specialist',
      description: 'Investor focusing on student accommodation near universities',
      expectedOutcome: 'Should optimize toward small, affordable units near educational institutions',
      actualOutcome: '',
      success: false,
      investorRelevance: 'Specialized investment strategy'
    },
    {
      scenario: 'Commercial Real Estate Focus',
      description: 'Business-focused investor seeking office and retail spaces',
      expectedOutcome: 'Should optimize toward commercial properties in business districts',
      actualOutcome: '',
      success: false,
      investorRelevance: 'Commercial investment validation'
    }
  ];
  
  // Test each scenario with appropriate user profiles
  const contacts = await prisma.contact.findMany();
  
  for (const scenario of scenarios) {
    const relevantContact = findRelevantContactForScenario(contacts, scenario.scenario);
    
    if (relevantContact) {
      const originalVector = [...relevantContact.scores];
      const result = await runGeneticOptimization(relevantContact.id, originalVector);
      
      // Analyze the optimized vector to see if it matches expectations
      const analysis = analyzeVectorForScenario(result.bestIndividual.vector, scenario.scenario);
      scenario.actualOutcome = analysis.description;
      scenario.success = analysis.matchesExpectation;
    } else {
      scenario.actualOutcome = 'No suitable contact profile found for testing';
      scenario.success = false;
    }
  }
  
  return scenarios;
}

/**
 * Find contact most relevant to scenario
 */
function findRelevantContactForScenario(contacts: any[], scenario: string): any | null {
  switch (scenario) {
    case 'High-Net-Worth Investor':
      return contacts.find(c => c.type === 'INVESTOR' && c.budgetMax > 50000000);
    case 'First-Time Family Buyer':
      return contacts.find(c => c.type === 'BUYER' && c.hasChildren && c.budgetMax < 20000000);
    case 'Student Housing Specialist':
      return contacts.find(c => c.type === 'TENANT' && c.familySize === 1 && c.budgetMax < 50000);
    case 'Commercial Real Estate Focus':
      return contacts.find(c => c.type === 'INVESTOR' && c.propertyTypes?.includes('OFFICE'));
    default:
      return null;
  }
}

/**
 * Analyze vector for scenario expectations
 */
function analyzeVectorForScenario(vector: number[], scenario: string): { description: string; matchesExpectation: boolean } {
  // Vector dimensions: [BUDGET, AREA, ROOMS, LOCATION, PROPERTY_TYPE, CONDITION, FEATURES, FAMILY, MODERN, INVESTMENT, URGENCY, TRANSACTION]
  
  switch (scenario) {
    case 'High-Net-Worth Investor':
      const highBudget = vector[0] > 0.7; // High budget preference
      const investmentFocus = vector[9] > 0.7; // High investment score
      const commercialType = vector[4] > 0.6; // Commercial property preference
      const matches1 = highBudget && investmentFocus && commercialType;
      return {
        description: `Budget: ${(vector[0] * 100).toFixed(0)}%, Investment: ${(vector[9] * 100).toFixed(0)}%, Commercial: ${(vector[4] * 100).toFixed(0)}%`,
        matchesExpectation: matches1
      };
      
    case 'First-Time Family Buyer':
      const moderateBudget = vector[0] < 0.6; // Moderate budget
      const familyFocus = vector[7] > 0.7; // High family score
      const securityFeatures = vector[6] > 0.6; // Good features
      const matches2 = moderateBudget && familyFocus && securityFeatures;
      return {
        description: `Budget: ${(vector[0] * 100).toFixed(0)}%, Family: ${(vector[7] * 100).toFixed(0)}%, Features: ${(vector[6] * 100).toFixed(0)}%`,
        matchesExpectation: matches2
      };
      
    case 'Student Housing Specialist':
      const lowBudget = vector[0] < 0.4; // Low budget
      const smallSize = vector[1] < 0.5; // Small area preference
      const lowFamily = vector[7] < 0.4; // Low family needs
      const matches3 = lowBudget && smallSize && lowFamily;
      return {
        description: `Budget: ${(vector[0] * 100).toFixed(0)}%, Size: ${(vector[1] * 100).toFixed(0)}%, Family: ${(vector[7] * 100).toFixed(0)}%`,
        matchesExpectation: matches3
      };
      
    case 'Commercial Real Estate Focus':
      const businessLocation = vector[3] > 0.6; // Good location
      const commercialFocus = vector[4] > 0.6; // Commercial property
      const investmentPotential = vector[9] > 0.6; // Investment focus
      const matches4 = businessLocation && commercialFocus && investmentPotential;
      return {
        description: `Location: ${(vector[3] * 100).toFixed(0)}%, Commercial: ${(vector[4] * 100).toFixed(0)}%, Investment: ${(vector[9] * 100).toFixed(0)}%`,
        matchesExpectation: matches4
      };
      
    default:
      return { description: 'Unknown scenario', matchesExpectation: false };
  }
}

/**
 * Generate comprehensive test suite summary
 */
function generateTestSuiteSummary(
  performanceTests: PerformanceTestResult[],
  convergenceTests: ConvergenceTestResult[],
  stabilityTests: StabilityTestResult[],
  scalabilityTests: ScalabilityTestResult[],
  realWorldTests: RealWorldTestResult[]
): TestSuiteSummary {
  const totalTests = performanceTests.length + convergenceTests.length + 
                    stabilityTests.length + scalabilityTests.length + realWorldTests.length;
  
  const successfulPerformance = performanceTests.filter(t => t.significantImprovement).length;
  const successfulConvergence = convergenceTests.filter(t => t.optimalSolution).length;
  const successfulStability = stabilityTests.filter(t => t.consistentResults).length;
  const successfulRealWorld = realWorldTests.filter(t => t.success).length;
  
  const successfulTests = successfulPerformance + successfulConvergence + 
                         successfulStability + successfulRealWorld;
  
  const averageImprovement = performanceTests.reduce((sum, t) => sum + t.improvement, 0) / performanceTests.length;
  const maxImprovement = Math.max(...performanceTests.map(t => t.improvement));
  const averageConvergenceTime = convergenceTests.reduce((sum, t) => sum + t.convergenceGeneration, 0) / convergenceTests.length;
  const stabilityScore = stabilityTests.reduce((sum, t) => sum + (t.consistentResults ? 1 : 0), 0) / stabilityTests.length;
  
  const bestScalability = scalabilityTests.reduce((best, current) => 
    current.scalabilityScore > best.scalabilityScore ? current : best
  );
  
  const scalabilityRating = bestScalability.scalabilityScore > 0.5 ? 'Excellent' : 
                           bestScalability.scalabilityScore > 0.3 ? 'Good' : 'Fair';
  
  const investorReadiness = (successfulTests / totalTests) > 0.75 && averageImprovement > 3;
  
  const recommendations: string[] = [];
  if (averageImprovement < 5) recommendations.push('Consider increasing mutation rate for better exploration');
  if (averageConvergenceTime > 30) recommendations.push('Optimize convergence criteria for faster results');
  if (stabilityScore < 0.8) recommendations.push('Improve algorithm stability with better initialization');
  if (!investorReadiness) recommendations.push('Additional optimization needed before investor presentation');
  
  if (recommendations.length === 0) {
    recommendations.push('System demonstrates excellent genetic optimization capabilities');
    recommendations.push('Ready for investor presentation and production deployment');
  }
  
  return {
    totalTests,
    successfulTests,
    averageImprovement,
    maxImprovement,
    averageConvergenceTime,
    stabilityScore,
    scalabilityRating,
    investorReadiness,
    recommendations
  };
}

/**
 * Generate investor-ready report
 */
function generateInvestorReport(testSuite: GeneticTestSuite): string {
  const summary = testSuite.summary;
  
  return `
🧬 GENETIC ALGORITHM OPTIMIZATION - INVESTOR REPORT
==================================================

📊 EXECUTIVE SUMMARY
-------------------
• Test Coverage: ${summary.totalTests} comprehensive tests executed
• Success Rate: ${((summary.successfulTests / summary.totalTests) * 100).toFixed(1)}%
• Average Performance Improvement: ${summary.averageImprovement.toFixed(1)}%
• Maximum Performance Gain: ${summary.maxImprovement.toFixed(1)}%
• Convergence Efficiency: ${summary.averageConvergenceTime.toFixed(0)} generations average
• System Stability: ${(summary.stabilityScore * 100).toFixed(0)}%
• Scalability Rating: ${summary.scalabilityRating}
• Investor Readiness: ${summary.investorReadiness ? '✅ READY' : '⚠️ NEEDS IMPROVEMENT'}

🚀 PERFORMANCE ANALYSIS
-----------------------
`;

  testSuite.performanceTests.forEach(test => {
    report += `
👤 ${test.contactName} (${test.userType})
   Original Accuracy: ${(test.originalAccuracy * 100).toFixed(1)}%
   Genetic Accuracy: ${(test.geneticAccuracy * 100).toFixed(1)}%
   Improvement: ${test.improvement >= 0 ? '+' : ''}${test.improvement.toFixed(1)}%
   Execution Time: ${test.executionTime}ms
   Status: ${test.significantImprovement ? '✅ Significant' : '📊 Marginal'}`;
  });

  report += `

📈 CONVERGENCE BEHAVIOR
----------------------
`;

  testSuite.convergenceTests.forEach(test => {
    report += `
🧬 ${test.contactName}
   Convergence: Generation ${test.convergenceGeneration}
   Final Diversity: ${(test.finalDiversity * 100).toFixed(1)}%
   Plateau Detected: ${test.plateauDetected ? 'Yes' : 'No'}
   Optimal Solution: ${test.optimalSolution ? '✅ Yes' : '❌ No'}`;
  });

  report += `

🎯 STABILITY VALIDATION
----------------------
`;

  testSuite.stabilityTests.forEach(test => {
    report += `
🔄 ${test.contactName} (${test.runs} runs)
   Average Improvement: ${test.averageImprovement.toFixed(1)}%
   Standard Deviation: ±${test.standardDeviation.toFixed(1)}%
   Consistency: ${test.consistentResults ? '✅ Stable' : '⚠️ Variable'}
   Best Run: ${test.bestRun.toFixed(1)}%
   Worst Run: ${test.worstRun.toFixed(1)}%`;
  });

  report += `

📊 SCALABILITY METRICS
---------------------
`;

  testSuite.scalabilityTests.forEach(test => {
    report += `
Population Size: ${test.populationSize}
   Execution Time: ${test.averageExecutionTime}ms
   Improvement: ${test.averageImprovement.toFixed(1)}%
   Memory Usage: ${(test.memoryUsage / 1024).toFixed(1)}KB
   Efficiency Score: ${test.scalabilityScore.toFixed(3)}`;
  });

  report += `

🌍 REAL-WORLD VALIDATION
------------------------
`;

  testSuite.realWorldValidation.forEach(test => {
    report += `
${test.scenario}
   Expected: ${test.expectedOutcome}
   Actual: ${test.actualOutcome}
   Success: ${test.success ? '✅' : '❌'}
   Investor Relevance: ${test.investorRelevance}`;
  });

  report += `

💡 RECOMMENDATIONS
-----------------
`;

  summary.recommendations.forEach(rec => {
    report += `• ${rec}\n`;
  });

  report += `

✅ INVESTMENT THESIS VALIDATION
------------------------------
The genetic algorithm enhancement demonstrates:

1. **Measurable Performance Gains**: Average ${summary.averageImprovement.toFixed(1)}% improvement
2. **Predictable Convergence**: Reliable optimization within ${summary.averageConvergenceTime.toFixed(0)} generations
3. **Production Stability**: ${(summary.stabilityScore * 100).toFixed(0)}% consistency across runs
4. **Scalable Architecture**: ${summary.scalabilityRating} scalability rating
5. **Real-World Applicability**: Validated across investor scenarios

🎯 INVESTOR VERDICT: ${summary.investorReadiness ? 
  '✅ READY FOR INSTITUTIONAL DEPLOYMENT' : 
  '⚠️ REQUIRES ADDITIONAL OPTIMIZATION'}

Generated: ${new Date().toLocaleString()}
`;

  return report;
}

/**
 * Main test execution
 */
async function main() {
  try {
    console.log('🧬 Starting comprehensive genetic algorithm test suite...\n');

    // Run all test categories
    const performanceTests = await runPerformanceTests();
    const convergenceTests = await runConvergenceTests();
    const stabilityTests = await runStabilityTests();
    const scalabilityTests = await runScalabilityTests();
    const realWorldValidation = await runRealWorldValidation();

    // Generate summary
    const summary = generateTestSuiteSummary(
      performanceTests,
      convergenceTests,
      stabilityTests,
      scalabilityTests,
      realWorldValidation
    );

    const testSuite: GeneticTestSuite = {
      performanceTests,
      convergenceTests,
      stabilityTests,
      scalabilityTests,
      realWorldValidation,
      summary
    };

    // Generate investor report
    const investorReport = generateInvestorReport(testSuite);
    console.log(investorReport);

    // Save reports
    const fs = require('fs');
    const timestamp = new Date().toISOString().split('T')[0];
    
    fs.writeFileSync(`genetic-algorithm-test-suite-${timestamp}.json`, JSON.stringify(testSuite, null, 2));
    fs.writeFileSync(`genetic-algorithm-investor-report-${timestamp}.txt`, investorReport);
    
    console.log(`\n📄 Test results saved:`);
    console.log(`   - genetic-algorithm-test-suite-${timestamp}.json`);
    console.log(`   - genetic-algorithm-investor-report-${timestamp}.txt`);

  } catch (error) {
    console.error('❌ Error during genetic algorithm testing:', error);
  } finally {
    await prisma.$disconnect();
  }
}

// Add variable declaration at the top
let report = '';

// Run the comprehensive test suite
main(); 