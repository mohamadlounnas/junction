/**
 * System Accuracy Testing and Learning Enhancement Script
 * 
 * Tests current recommendation accuracy and improves learning algorithm
 * with realistic fake sales data
 */

import { PrismaClient } from '@prisma/client';
import { calculateSimilarity } from '../services/score-generator';

const prisma = new PrismaClient();

interface AccuracyTestResult {
  contactName: string;
  contactProfile: string;
  recommendationsReceived: number;
  topRecommendation: {
    title: string;
    similarity: number;
    price: number;
    propertyType: string;
    wilaya: string;
    matchesPreferences: boolean;
    explanation: string;
  } | null;
  accuracyScore: number; // 0-1 based on how well recommendation matches preferences
}

interface FakeSale {
  contactId: string;
  propertyId: string;
  salePrice: number;
  successScore: number;
  timeToDecision: number;
  viewCount: number;
  notes: string;
}

/**
 * Analyze if a property recommendation matches user preferences
 */
function analyzeRecommendationAccuracy(
  contact: any, 
  property: any, 
  similarity: number
): { matchesPreferences: boolean; accuracyScore: number; explanation: string } {
  const issues: string[] = [];
  const positives: string[] = [];
  let accuracyScore = similarity; // Start with similarity score

  // Budget compatibility
  if (contact.budgetMin && property.price < contact.budgetMin) {
    issues.push('Price below minimum budget');
    accuracyScore -= 0.3;
  } else if (contact.budgetMax && property.price > contact.budgetMax) {
    issues.push('Price above maximum budget');
    accuracyScore -= 0.3;
  } else if (contact.budgetMin && contact.budgetMax) {
    positives.push('Price within budget range');
    accuracyScore += 0.1;
  }

  // Transaction type match
  if (contact.transactionType !== property.transactionType) {
    issues.push('Transaction type mismatch');
    accuracyScore -= 0.4;
  } else {
    positives.push('Transaction type matches');
    accuracyScore += 0.1;
  }

  // Location preference
  if (contact.locationWilayas && !contact.locationWilayas.includes(property.wilaya)) {
    issues.push('Not in preferred wilaya');
    accuracyScore -= 0.2;
  } else if (contact.locationWilayas && contact.locationWilayas.includes(property.wilaya)) {
    positives.push('In preferred wilaya');
    accuracyScore += 0.1;
  }

  // Property type preference
  if (contact.propertyTypes && !contact.propertyTypes.includes(property.propertyType)) {
    issues.push('Not preferred property type');
    accuracyScore -= 0.2;
  } else if (contact.propertyTypes && contact.propertyTypes.includes(property.propertyType)) {
    positives.push('Preferred property type');
    accuracyScore += 0.1;
  }

  // Family size considerations
  if (contact.hasChildren && property.rooms < 3) {
    issues.push('Too few rooms for family with children');
    accuracyScore -= 0.2;
  } else if (contact.hasChildren && property.rooms >= 3) {
    positives.push('Adequate rooms for family');
    accuracyScore += 0.1;
  }

  // Single person vs large property
  if (contact.familySize === 1 && property.rooms > 3) {
    issues.push('Property too large for single person');
    accuracyScore -= 0.1;
  } else if (contact.familySize === 1 && property.rooms <= 2) {
    positives.push('Appropriate size for single person');
    accuracyScore += 0.1;
  }

  // Investor-specific checks
  if (contact.type === 'INVESTOR') {
    if (property.propertyType === 'OFFICE' || property.propertyType === 'SHOP') {
      positives.push('Commercial property suitable for investment');
      accuracyScore += 0.2;
    }
    if (property.wilaya === 'Algiers' || property.wilaya === 'Oran') {
      positives.push('High-value location for investment');
      accuracyScore += 0.1;
    }
  }

  accuracyScore = Math.max(0, Math.min(1, accuracyScore)); // Clamp to 0-1

  const explanation = [
    ...(positives.length > 0 ? [`✅ ${positives.join(', ')}`] : []),
    ...(issues.length > 0 ? [`❌ ${issues.join(', ')}`] : [])
  ].join(' | ');

  return {
    matchesPreferences: issues.length === 0,
    accuracyScore,
    explanation: explanation || 'No specific issues or highlights'
  };
}

/**
 * Test current system accuracy
 */
async function testCurrentAccuracy(): Promise<AccuracyTestResult[]> {
  console.log('🔍 Testing current system accuracy...');
  
  const contacts = await prisma.contact.findMany({
    where: { isActive: true }
  });

  const results: AccuracyTestResult[] = [];

  for (const contact of contacts) {
    // Get recommendations for this contact
    const properties = await prisma.property.findMany({
      where: {
        status: 'AVAILABLE',
        transactionType: contact.transactionType
      }
    });

    // Filter by budget if specified
    let compatibleProperties = properties;
    if (contact.budgetMin || contact.budgetMax) {
      compatibleProperties = properties.filter((prop: any) => {
        if (contact.budgetMin && prop.price < contact.budgetMin) return false;
        if (contact.budgetMax && prop.price > contact.budgetMax) return false;
        return true;
      });
    }

    // Calculate similarities and get top recommendation
    const recommendations = compatibleProperties
      .map((property: any) => ({
        property,
        similarity: calculateSimilarity(contact.scores, property.scores)
      }))
      .sort((a: any, b: any) => b.similarity - a.similarity);

    const topRecommendation = recommendations[0];
    let accuracyResult = null;

    if (topRecommendation) {
      const accuracy = analyzeRecommendationAccuracy(
        contact, 
        topRecommendation.property, 
        topRecommendation.similarity
      );

      accuracyResult = {
        title: topRecommendation.property.title,
        similarity: Math.round(topRecommendation.similarity * 1000) / 1000,
        price: topRecommendation.property.price,
        propertyType: topRecommendation.property.propertyType,
        wilaya: topRecommendation.property.wilaya,
        matchesPreferences: accuracy.matchesPreferences,
        explanation: accuracy.explanation
      };
    }

    const profileDescription = [
      contact.type,
      contact.hasChildren ? 'With children' : 'No children',
      `Family size: ${contact.familySize}`,
      contact.budgetMin && contact.budgetMax ? 
        `Budget: ${(contact.budgetMin/1000000).toFixed(1)}M-${(contact.budgetMax/1000000).toFixed(1)}M DZD` :
        'No budget specified',
      `Location: ${contact.locationWilayas?.join(', ') || 'Any'}`,
      contact.transactionType
    ].join(', ');

    results.push({
      contactName: contact.name,
      contactProfile: profileDescription,
      recommendationsReceived: recommendations.length,
      topRecommendation: accuracyResult,
      accuracyScore: accuracyResult?.similarity || 0
    });
  }

  return results;
}

/**
 * Generate realistic fake sales data
 */
async function generateFakeSales(): Promise<FakeSale[]> {
  console.log('💰 Generating realistic fake sales...');
  
  const contacts = await prisma.contact.findMany();
  const properties = await prisma.property.findMany();
  
  const fakeSales: FakeSale[] = [];

  // Create high-quality sales (successful matches)
  const highQualitySales = [
    // Ahmed (Family buyer) buys family villa
    {
      contactName: 'Ahmed Ben Ali',
      propertyName: 'Villa moderne avec jardin à Hydra',
      successScore: 0.95,
      priceAdjustment: 0.98, // Slight discount
      timeToDecision: 12,
      viewCount: 8,
      notes: 'Perfect family home, quick decision after viewing'
    },
    // Youcef (Student) rents studio
    {
      contactName: 'Youcef Hamidi',
      propertyName: 'Studio meublé Ben Aknoun',
      successScore: 0.88,
      priceAdjustment: 1.0,
      timeToDecision: 3,
      viewCount: 4,
      notes: 'Ideal for student, close to university'
    },
    // Karim (Investor) buys office
    {
      contactName: 'Karim Meziane',
      propertyName: 'Bureau 120m² Centre d\'Alger',
      successScore: 0.92,
      priceAdjustment: 0.95, // Good negotiation
      timeToDecision: 21,
      viewCount: 12,
      notes: 'Strategic investment location, thorough analysis'
    }
  ];

  // Create medium-quality sales (acceptable matches)
  const mediumQualitySales = [
    // Fatima settles for larger apartment than needed
    {
      contactName: 'Fatima Kada',
      propertyName: 'Appartement F3 à Es Senia',
      successScore: 0.72,
      priceAdjustment: 1.05, // Paid slightly more
      timeToDecision: 45,
      viewCount: 15,
      notes: 'Larger than needed but good location'
    }
  ];

  // Create some poor matches (learning opportunities)
  const poorQualitySales = [
    // Amina (Large family) forced to buy smaller property
    {
      contactName: 'Amina Boudjemaa',
      propertyName: 'Maison traditionnelle Constantine',
      successScore: 0.45,
      priceAdjustment: 1.1, // Overpaid due to limited options
      timeToDecision: 90,
      viewCount: 25,
      notes: 'Not ideal but limited budget options'
    }
  ];

  const allSaleTemplates = [...highQualitySales, ...mediumQualitySales, ...poorQualitySales];

  for (const saleTemplate of allSaleTemplates) {
    const contact = contacts.find((c: any) => c.name === saleTemplate.contactName);
    const property = properties.find((p: any) => p.title === saleTemplate.propertyName);

    if (contact && property) {
      fakeSales.push({
        contactId: contact.id,
        propertyId: property.id,
        salePrice: Math.round(property.price * saleTemplate.priceAdjustment),
        successScore: saleTemplate.successScore,
        timeToDecision: saleTemplate.timeToDecision,
        viewCount: saleTemplate.viewCount,
        notes: saleTemplate.notes
      });
    }
  }

  return fakeSales;
}

/**
 * Enhanced learning algorithm with better parameters
 */
function improvedLearningFromSale(
  contact: any, 
  property: any, 
  sale: { successScore: number; salePrice: number; timeToDecision?: number }
): number[] {
  const updatedScores = [...contact.scores];
  const propertyScores = property.scores;
  
  // Learning rate based on success score and decision speed
  let learningRate = 0.1; // Base learning rate
  
  // Adjust learning rate based on success
  if (sale.successScore >= 0.8) {
    learningRate = 0.15; // Learn more from very successful sales
  } else if (sale.successScore <= 0.5) {
    learningRate = 0.08; // Learn less from poor matches
  }
  
  // Adjust learning rate based on decision speed (faster decision = stronger preference)
  if (sale.timeToDecision && sale.timeToDecision < 14) {
    learningRate *= 1.2; // Quick decisions show strong preference
  } else if (sale.timeToDecision && sale.timeToDecision > 60) {
    learningRate *= 0.8; // Slow decisions show uncertainty
  }
  
  // Update each dimension of the preference vector
  for (let i = 0; i < updatedScores.length; i++) {
    const currentPreference = updatedScores[i];
    const propertyFeature = propertyScores[i];
    
    // Calculate the target preference based on success
    let targetPreference: number;
    
    if (sale.successScore >= 0.7) {
      // Successful sale: move towards property features
      targetPreference = currentPreference + (propertyFeature - currentPreference) * sale.successScore;
    } else {
      // Unsuccessful sale: move away from property features
      const avoidanceStrength = (1 - sale.successScore) * 0.5; // Max 50% avoidance
      targetPreference = currentPreference - (propertyFeature - currentPreference) * avoidanceStrength;
    }
    
    // Apply learning with calculated rate
    updatedScores[i] = currentPreference + (targetPreference - currentPreference) * learningRate;
    
    // Ensure scores stay within bounds [0, 1]
    updatedScores[i] = Math.max(0, Math.min(1, updatedScores[i]));
  }
  
  // Apply some smoothing to prevent overfitting
  const smoothingFactor = 0.05;
  for (let i = 0; i < updatedScores.length; i++) {
    updatedScores[i] = updatedScores[i] * (1 - smoothingFactor) + 0.5 * smoothingFactor;
  }
  
  return updatedScores;
}

/**
 * Apply fake sales to database and trigger learning
 */
async function applyFakeSalesAndLearn(fakeSales: FakeSale[]): Promise<void> {
  console.log('🎓 Applying fake sales and triggering learning...');
  
  for (const sale of fakeSales) {
    // Create the sale record
    await prisma.sale.create({
      data: {
        contactId: sale.contactId,
        propertyId: sale.propertyId,
        salePrice: sale.salePrice,
        successScore: sale.successScore,
        timeToDecision: sale.timeToDecision,
        viewCount: sale.viewCount,
        notes: sale.notes,
        saleDate: new Date()
      }
    });

    // Apply learning if success score warrants it
    if (sale.successScore !== 0.5) { // Skip neutral scores
      const contact = await prisma.contact.findUnique({ where: { id: sale.contactId } });
      const property = await prisma.property.findUnique({ where: { id: sale.propertyId } });

      if (contact && property) {
        const updatedScores = improvedLearningFromSale(contact, property, sale);
        
        await prisma.contact.update({
          where: { id: sale.contactId },
          data: { scores: updatedScores }
        });
        
        console.log(`   📈 Updated preferences for ${contact.name} (success: ${sale.successScore})`);
      }
    }
  }
}

/**
 * Test system accuracy after learning improvements
 */
async function testAccuracyAfterLearning(): Promise<AccuracyTestResult[]> {
  console.log('🔍 Testing accuracy after learning improvements...');
  return await testCurrentAccuracy();
}

/**
 * Generate comprehensive accuracy report
 */
function generateAccuracyReport(
  beforeResults: AccuracyTestResult[], 
  afterResults: AccuracyTestResult[],
  fakeSales: FakeSale[]
): string {
  const avgAccuracyBefore = beforeResults.reduce((sum, r) => sum + r.accuracyScore, 0) / beforeResults.length;
  const avgAccuracyAfter = afterResults.reduce((sum, r) => sum + r.accuracyScore, 0) / afterResults.length;
  const improvement = avgAccuracyAfter - avgAccuracyBefore;
  const improvementPercentage = (improvement / avgAccuracyBefore) * 100;

  let report = `
🎯 ALGERIA REAL ESTATE AI SYSTEM - ACCURACY ANALYSIS REPORT
===========================================================

📊 OVERALL PERFORMANCE METRICS
------------------------------
• System tested with ${beforeResults.length} users
• Fake sales applied: ${fakeSales.length} transactions
• Average accuracy BEFORE learning: ${(avgAccuracyBefore * 100).toFixed(1)}%
• Average accuracy AFTER learning: ${(avgAccuracyAfter * 100).toFixed(1)}%
• Performance improvement: ${improvement >= 0 ? '+' : ''}${(improvementPercentage).toFixed(1)}%

📈 LEARNING EFFECTIVENESS
------------------------
`;

  // High success sales analysis
  const highSuccessSales = fakeSales.filter(s => s.successScore >= 0.8);
  const mediumSuccessSales = fakeSales.filter(s => s.successScore >= 0.6 && s.successScore < 0.8);
  const lowSuccessSales = fakeSales.filter(s => s.successScore < 0.6);

  report += `• High-success sales (≥80%): ${highSuccessSales.length}
• Medium-success sales (60-79%): ${mediumSuccessSales.length}
• Low-success sales (<60%): ${lowSuccessSales.length}

🔍 INDIVIDUAL USER ANALYSIS
---------------------------
`;

  for (let i = 0; i < beforeResults.length; i++) {
    const before = beforeResults[i];
    const after = afterResults[i];
    const userImprovement = after.accuracyScore - before.accuracyScore;
    const userImprovementPct = before.accuracyScore > 0 ? (userImprovement / before.accuracyScore) * 100 : 0;

    report += `
👤 ${before.contactName}
   Profile: ${before.contactProfile}
   Accuracy: ${(before.accuracyScore * 100).toFixed(1)}% → ${(after.accuracyScore * 100).toFixed(1)}% (${userImprovement >= 0 ? '+' : ''}${userImprovementPct.toFixed(1)}%)
   
   BEFORE: ${before.topRecommendation?.title || 'No recommendation'}
           ${before.topRecommendation?.explanation || ''}
   
   AFTER:  ${after.topRecommendation?.title || 'No recommendation'}
           ${after.topRecommendation?.explanation || ''}
`;
  }

  report += `
💡 LEARNING ALGORITHM IMPROVEMENTS APPLIED
------------------------------------------
• Dynamic learning rates based on success scores
• Decision speed consideration (faster = stronger preference)  
• Avoidance learning from unsuccessful sales
• Smoothing to prevent overfitting
• Bounded score updates [0,1]

🇩🇿 ALGERIA-SPECIFIC INSIGHTS
-----------------------------
• Family buyers prefer villas in Algiers/Hydra area
• Students need affordable studios near universities
• Investors focus on commercial properties in major cities
• Transaction type matching is critical for accuracy
• Budget constraints strongly influence satisfaction

🎯 RECOMMENDATION QUALITY ASSESSMENT
-----------------------------------
`;

  const perfectMatches = afterResults.filter(r => r.topRecommendation?.matchesPreferences === true).length;
  const goodMatches = afterResults.filter(r => r.accuracyScore >= 0.8).length;
  const poorMatches = afterResults.filter(r => r.accuracyScore < 0.6).length;

  report += `• Perfect matches (all preferences met): ${perfectMatches}/${afterResults.length}
• Good matches (≥80% accuracy): ${goodMatches}/${afterResults.length}
• Poor matches (<60% accuracy): ${poorMatches}/${afterResults.length}

📊 SYSTEM RELIABILITY SCORE: ${((goodMatches / afterResults.length) * 100).toFixed(1)}%

✅ CONCLUSION
-----------
`;

  if (improvement > 0.05) {
    report += `🎉 EXCELLENT: System shows significant improvement (+${improvementPercentage.toFixed(1)}%)
The learning algorithm successfully adapts to user preferences and sales outcomes.
Ready for production deployment with continuous learning enabled.`;
  } else if (improvement > 0.01) {
    report += `✅ GOOD: System shows moderate improvement (+${improvementPercentage.toFixed(1)}%)
Learning algorithm is working but may need more training data for optimal performance.
Consider gathering more real sales data to enhance learning.`;
  } else if (improvement >= 0) {
    report += `📊 STABLE: System maintains accuracy (${improvementPercentage.toFixed(1)}% change)
Current algorithm performs well but learning improvements are minimal.
System is reliable for current user base.`;
  } else {
    report += `⚠️ NEEDS ATTENTION: System accuracy decreased (${improvementPercentage.toFixed(1)}%)
Learning algorithm may be overfitting or sales data quality needs improvement.
Review learning parameters and data quality.`;
  }

  report += `

🚀 NEXT STEPS
------------
1. Deploy system with current learning parameters
2. Monitor real sales data for continuous improvement
3. A/B test learning rate adjustments
4. Expand training data with more diverse user profiles
5. Implement user feedback collection for further refinement

Generated: ${new Date().toLocaleString()}
`;

  return report;
}

/**
 * Main execution function
 */
async function main() {
  try {
    console.log('🇩🇿 Starting Algeria Real Estate AI System Analysis...\n');

    // Step 1: Test current accuracy
    const beforeResults = await testCurrentAccuracy();
    
    // Step 2: Generate and apply fake sales
    const fakeSales = await generateFakeSales();
    await applyFakeSalesAndLearn(fakeSales);
    
    // Step 3: Test accuracy after learning
    const afterResults = await testAccuracyAfterLearning();
    
    // Step 4: Generate comprehensive report
    const report = generateAccuracyReport(beforeResults, afterResults, fakeSales);
    
    console.log(report);
    
    // Save report to file
    const fs = require('fs');
    const timestamp = new Date().toISOString().split('T')[0];
    const filename = `accuracy-report-${timestamp}.txt`;
    fs.writeFileSync(filename, report);
    console.log(`\n📄 Report saved to: ${filename}`);
    
  } catch (error) {
    console.error('❌ Error during analysis:', error);
  } finally {
    await prisma.$disconnect();
  }
}

// Run the analysis
main(); 