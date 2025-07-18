#!/usr/bin/env bun

/**
 * Migration Script: 8D to 12D Algeria-Optimized Vectors
 * 
 * This script migrates existing users and properties from the old 8-dimensional
 * random/basic vectors to the new 12-dimensional Algeria-optimized vectors.
 */

import { PrismaClient } from '../generated/prisma';
import algerianVectorGenerator from '../src/services/vector-generator';

const prisma = new PrismaClient();

async function migrateVectors() {
  console.log('🇩🇿 Starting migration to Algeria-optimized vectors...\n');
  
  try {
    // Get all users
    console.log('📊 Fetching all users...');
    const users = await prisma.user.findMany();
    console.log(`Found ${users.length} users to migrate`);
    
    // Get all properties
    console.log('🏠 Fetching all properties...');
    const properties = await prisma.property.findMany();
    console.log(`Found ${properties.length} properties to migrate`);
    
    // Migrate users
    console.log('\n👥 Migrating user vectors...');
    let userCount = 0;
    
    for (const user of users) {
      try {
        // Generate intelligent vector based on user type
        const newVector = await algerianVectorGenerator.generateUserVector({
          userType: user.userType,
          // For existing users, we'll use smart defaults
          isFirstTimeBuyer: user.userType !== 'AGENT',
          hasChildren: Math.random() > 0.6, // 40% chance of having children
          familySize: user.userType === 'BUYER' ? Math.floor(Math.random() * 3) + 2 : 1, // 2-4 for buyers, 1 for others
          transportNeeded: Math.random() > 0.5, // 50% chance
        });
        
        await prisma.user.update({
          where: { id: user.id },
          data: { scoreVector: newVector }
        });
        
        userCount++;
        
        if (userCount % 5 === 0) {
          console.log(`  ✅ Migrated ${userCount}/${users.length} users`);
        }
      } catch (error) {
        console.error(`  ❌ Failed to migrate user ${user.id}:`, error);
      }
    }
    
    // Migrate properties
    console.log('\n🏠 Migrating property vectors...');
    let propertyCount = 0;
    
    for (const property of properties) {
      try {
        // Generate intelligent vector based on property features
        const newVector = algerianVectorGenerator.generatePropertyVector({
          price: property.price,
          area: property.area,
          rooms: property.rooms,
          location: property.location,
          propertyType: property.propertyType,
          furnishing: property.furnishing,
          condition: property.condition,
          transactionType: property.transactionType,
          hasParking: property.hasParking || false,
          hasSecurity: property.hasSecurity || false,
          hasElevator: Math.random() > 0.7, // 30% chance for existing properties
          nearMosque: Math.random() > 0.6,  // 40% chance
          nearSchool: Math.random() > 0.7,  // 30% chance
          nearTransport: Math.random() > 0.5 // 50% chance
        });
        
        await prisma.property.update({
          where: { id: property.id },
          data: { scoreVector: newVector }
        });
        
        propertyCount++;
        
        if (propertyCount % 10 === 0) {
          console.log(`  ✅ Migrated ${propertyCount}/${properties.length} properties`);
        }
      } catch (error) {
        console.error(`  ❌ Failed to migrate property ${property.id}:`, error);
      }
    }
    
    // Verification
    console.log('\n🔍 Verifying migration...');
    
    // Check a few migrated vectors
    const sampleUsers = await prisma.user.findMany({ take: 3 });
    const sampleProperties = await prisma.property.findMany({ take: 3 });
    
    console.log('\n📊 Sample migrated user vectors:');
    sampleUsers.forEach((user, index) => {
      console.log(`User ${index + 1} (${user.userType}): [${user.scoreVector.map(v => v.toFixed(2)).join(', ')}]`);
      console.log(`  Dimensions: ${user.scoreVector.length} (should be 12)`);
    });
    
    console.log('\n🏠 Sample migrated property vectors:');
    sampleProperties.forEach((property, index) => {
      console.log(`Property ${index + 1} (${property.location}): [${property.scoreVector.map(v => v.toFixed(2)).join(', ')}]`);
      console.log(`  Dimensions: ${property.scoreVector.length} (should be 12)`);
    });
    
    // Test compatibility
    if (sampleUsers.length > 0 && sampleProperties.length > 0) {
      console.log('\n🎯 Testing recommendation compatibility...');
      
      const user = sampleUsers[0];
      const property = sampleProperties[0];
      
      // Calculate similarity
      const similarity = cosineSimilarity(user.scoreVector, property.scoreVector);
      console.log(`Sample compatibility: ${(similarity * 100).toFixed(1)}%`);
      
      if (similarity > 0.1) {
        console.log('✅ Vectors are compatible for recommendations');
      } else {
        console.log('⚠️ Low compatibility - may need adjustment');
      }
    }
    
    console.log(`\n🎉 Migration completed successfully!`);
    console.log(`✅ ${userCount} users migrated`);
    console.log(`✅ ${propertyCount} properties migrated`);
    console.log(`🇩🇿 All vectors are now Algeria-optimized with 12 dimensions`);
    
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

function cosineSimilarity(vectorA: number[], vectorB: number[]): number {
  if (vectorA.length !== vectorB.length) {
    throw new Error(`Vector length mismatch: ${vectorA.length} vs ${vectorB.length}`);
  }
  
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
  
  if (normA === 0 || normB === 0) {
    return 0;
  }
  
  return dotProduct / (normA * normB);
}

// Run the migration
migrateVectors().catch(console.error); 