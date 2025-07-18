#!/usr/bin/env bun

/**
 * Test Algeria-Optimized Vector System
 * Demonstrates smart defaults for missing user preferences
 */

import algerianVectorGenerator from '../src/services/vector-generator';
import { UserType, PropertyType, FurnishingType, ConditionType, TransactionType } from '../generated/prisma';

async function testAlgerianVectors() {
  console.log('🇩🇿 Testing Algeria-Optimized Vector System\n');
  
  // Test Case 1: User with minimal information (only userType)
  console.log('📊 Test 1: Minimal User Information');
  console.log('=====================================');
  const minimalUser = await algerianVectorGenerator.generateUserVector({
    userType: UserType.BUYER
  });
  console.log('Input: Only userType = BUYER');
  console.log('Generated Vector:', minimalUser);
  console.log('Interpretation:');
  console.log(`- Price preference: ${(minimalUser[0] * 100).toFixed(1)}% (${minimalUser[0] * 50}M DZD budget)`);
  console.log(`- Area preference: ${(minimalUser[1] * 100).toFixed(1)}% (~${Math.round(minimalUser[1] * 500)}m²)`);
  console.log(`- Rooms needed: ${Math.round(minimalUser[2] * 6)} rooms`);
  console.log(`- Location: ${getWilayaFromScore(minimalUser[3])}`);
  console.log('');
  
  // Test Case 2: Family with children
  console.log('📊 Test 2: Family with Children');
  console.log('================================');
  const familyUser = await algerianVectorGenerator.generateUserVector({
    userType: UserType.BUYER,
    familySize: 5,
    hasChildren: true,
    preferredLocation: 'Algiers',
    budget: 25000000 // 25M DZD
  });
  console.log('Input: Family of 5, children, Algiers, 25M DZD budget');
  console.log('Generated Vector:', familyUser);
  console.log('Interpretation:');
  console.log(`- Price preference: ${(familyUser[0] * 100).toFixed(1)}% (${familyUser[0] * 50}M DZD budget)`);
  console.log(`- Area preference: ${(familyUser[1] * 100).toFixed(1)}% (~${Math.round(familyUser[1] * 500)}m²)`);
  console.log(`- Rooms needed: ${Math.round(familyUser[2] * 6)} rooms`);
  console.log(`- Family-friendly: ${(familyUser[11] * 100).toFixed(1)}%`);
  console.log('');
  
  // Test Case 3: First-time tenant
  console.log('📊 Test 3: First-time Tenant');
  console.log('=============================');
  const firstTimeTenant = await algerianVectorGenerator.generateUserVector({
    userType: UserType.TENANT,
    isFirstTimeBuyer: true,
    transportNeeded: true,
    budget: 30000 // 30K DZD monthly rent
  });
  console.log('Input: First-time tenant, needs transport, 30K DZD budget');
  console.log('Generated Vector:', firstTimeTenant);
  console.log('Interpretation:');
  console.log(`- Price preference: ${(firstTimeTenant[0] * 100).toFixed(1)}% (${firstTimeTenant[0] * 50}K DZD rent)`);
  console.log(`- Furnishing: ${getFurnishingFromScore(firstTimeTenant[5])}`);
  console.log(`- Transaction: ${firstTimeTenant[7] === 0 ? 'RENT' : 'SALE'}`);
  console.log(`- Accessibility: ${(firstTimeTenant[10] * 100).toFixed(1)}%`);
  console.log('');
  
  // Test Case 4: Property vectors
  console.log('📊 Test 4: Property Vectors');
  console.log('============================');
  
  const algiersVilla = algerianVectorGenerator.generatePropertyVector({
    price: 35000000, // 35M DZD
    area: 250,
    rooms: 4,
    location: 'Hydra, Algiers',
    propertyType: PropertyType.VILLA,
    furnishing: FurnishingType.SEMI_FURNISHED,
    condition: ConditionType.EXCELLENT,
    transactionType: TransactionType.SALE,
    hasParking: true,
    hasSecurity: true,
    nearSchool: true,
    nearMosque: true
  });
  
  console.log('Property: Villa in Hydra, Algiers');
  console.log('Generated Vector:', algiersVilla);
  console.log('Interpretation:');
  console.log(`- Price level: ${(algiersVilla[0] * 100).toFixed(1)}% (Premium)`);
  console.log(`- Wilaya: ${getWilayaFromScore(algiersVilla[3])} (Score: ${algiersVilla[3]})`);
  console.log(`- Amenities: ${(algiersVilla[8] * 100).toFixed(1)}% (Parking + Security)`);
  console.log(`- Family-friendly: ${(algiersVilla[11] * 100).toFixed(1)}% (Near school)`);
  console.log('');
  
  // Test Case 5: Compatibility check
  console.log('📊 Test 5: User-Property Compatibility');
  console.log('=======================================');
  
  const similarity = cosineSimilarity(familyUser, algiersVilla);
  console.log(`Family User Vector: [${familyUser.map(v => v.toFixed(2)).join(', ')}]`);
  console.log(`Algiers Villa Vector: [${algiersVilla.map(v => v.toFixed(2)).join(', ')}]`);
  console.log(`Similarity Score: ${(similarity * 100).toFixed(1)}%`);
  console.log(`Compatibility: ${getCompatibilityLevel(similarity)}`);
  console.log('');
  
  // Test Case 6: Compare with random vectors
  console.log('📊 Test 6: Smart vs Random Vectors');
  console.log('===================================');
  
  const randomVector = Array.from({ length: 12 }, () => Math.random());
  const randomSimilarity = cosineSimilarity(randomVector, algiersVilla);
  
  console.log(`Smart Vector Similarity: ${(similarity * 100).toFixed(1)}%`);
  console.log(`Random Vector Similarity: ${(randomSimilarity * 100).toFixed(1)}%`);
  console.log(`Improvement: ${((similarity - randomSimilarity) * 100).toFixed(1)} percentage points`);
  console.log('');
  
  console.log('🎉 Algeria-optimized vectors provide meaningful defaults!');
  console.log('✅ No more random meaningless vectors');
  console.log('✅ Context-aware recommendations even with minimal user input');
  console.log('✅ Algeria-specific wilaya and cultural considerations');
}

function cosineSimilarity(vectorA: number[], vectorB: number[]): number {
  let dotProduct = 0;
  let normA = 0;
  let normB = 0;
  
  for (let i = 0; i < vectorA.length; i++) {
    dotProduct += vectorA[i] * vectorB[i];
    normA += vectorA[i] * vectorA[i];
    normB += vectorB[i] * vectorB[i];
  }
  
  normA = Math.sqrt(normA);
  normB = Math.sqrt(normB);
  
  if (normA === 0 || normB === 0) return 0;
  
  return dotProduct / (normA * normB);
}

function getWilayaFromScore(score: number): string {
  if (score >= 0.95) return 'Algiers (Capital)';
  if (score >= 0.90) return 'Oran/Constantine (Major City)';
  if (score >= 0.80) return 'Annaba/Tipaza (Important City)';
  if (score >= 0.70) return 'Boumerdès/Regional Center';
  if (score >= 0.50) return 'Provincial City';
  return 'Rural/Remote Area';
}

function getFurnishingFromScore(score: number): string {
  if (score >= 0.8) return 'FURNISHED';
  if (score >= 0.4) return 'SEMI_FURNISHED';
  return 'UNFURNISHED';
}

function getCompatibilityLevel(similarity: number): string {
  if (similarity >= 0.8) return 'Excellent Match 🎯';
  if (similarity >= 0.6) return 'Good Match ✅';
  if (similarity >= 0.4) return 'Fair Match ⚡';
  return 'Poor Match ❌';
}

// Run the tests
testAlgerianVectors().catch(console.error); 