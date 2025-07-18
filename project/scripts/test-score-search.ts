#!/usr/bin/env bun

/**
 * Test Score-Based User Search
 * 
 * This script demonstrates the new score-based search functionality
 * for the /api/users endpoint, including:
 * - Similarity-based search using vector comparison
 * - Score range filtering for specific vector dimensions
 * - Combined filtering with existing parameters
 */

const API_BASE_URL = 'http://localhost:3001';

interface ApiResponse {
  success: boolean;
  data: any;
  pagination?: {
    page: number;
    limit: number;
    total: number;
    pages: number;
  };
  filters?: any;
}

interface RequestResult {
  success: boolean;
  data: ApiResponse;
  status: number;
}

async function makeRequest(url: string, options: RequestInit = {}): Promise<RequestResult> {
  try {
    const response = await fetch(url, {
      headers: {
        'Content-Type': 'application/json',
        ...options.headers,
      },
      ...options,
    });
    
    const data = await response.json() as ApiResponse;
    return { success: response.ok, data, status: response.status };
  } catch (error) {
    return { success: false, data: { success: false, data: error }, status: 500 };
  }
}

async function testScoreBasedSearch() {
  console.log('🧪 Testing Score-Based User Search\n');

  // Test 1: Search by similarity to a specific vector
  console.log('1️⃣ Testing similarity-based search...');
  const targetVector = [0.7, 0.6, 0.4, 0.9, 0.4, 0.2, 0.8, 1.0, 0.3, 0.6, 0.5, 0.3]; // High-budget buyer in Algiers
  const similarityUrl = `${API_BASE_URL}/api/users?similarityVector=${JSON.stringify(targetVector)}&minSimilarity=0.5&limit=5`;
  
  const similarityResult = await makeRequest(similarityUrl);
  if (similarityResult.success) {
    console.log('✅ Similarity search successful');
    console.log(`Found ${similarityResult.data.data.length} users with similarity >= 0.5`);
    if (similarityResult.data.data.length > 0) {
      console.log('Top match:', {
        name: similarityResult.data.data[0].name,
        similarity: similarityResult.data.data[0].similarity,
        userType: similarityResult.data.data[0].userType
      });
    }
  } else {
    console.log('❌ Similarity search failed:', similarityResult.data);
  }

  // Test 2: Search by price preference (index 0)
  console.log('\n2️⃣ Testing price preference search (index 0)...');
  const priceUrl = `${API_BASE_URL}/api/users?scoreIndex=0&scoreMin=0.6&scoreMax=0.9&limit=5`;
  
  const priceResult = await makeRequest(priceUrl);
  if (priceResult.success) {
    console.log('✅ Price preference search successful');
    console.log(`Found ${priceResult.data.data.length} users with price preference 0.6-0.9`);
    if (priceResult.data.data.length > 0) {
      console.log('Sample user:', {
        name: priceResult.data.data[0].name,
        priceScore: priceResult.data.data[0].scoreVector[0],
        userType: priceResult.data.data[0].userType
      });
    }
  } else {
    console.log('❌ Price preference search failed:', priceResult.data);
  }

  // Test 3: Search by location preference (index 3) - Algiers area
  console.log('\n3️⃣ Testing location preference search (index 3)...');
  const locationUrl = `${API_BASE_URL}/api/users?scoreIndex=3&scoreMin=0.8&limit=5`;
  
  const locationResult = await makeRequest(locationUrl);
  if (locationResult.success) {
    console.log('✅ Location preference search successful');
    console.log(`Found ${locationResult.data.data.length} users preferring major cities (score >= 0.8)`);
    if (locationResult.data.data.length > 0) {
      console.log('Sample user:', {
        name: locationResult.data.data[0].name,
        locationScore: locationResult.data.data[0].scoreVector[3],
        userType: locationResult.data.data[0].userType
      });
    }
  } else {
    console.log('❌ Location preference search failed:', locationResult.data);
  }

  // Test 4: Search by property type preference (index 4) - Villa lovers
  console.log('\n4️⃣ Testing property type preference search (index 4)...');
  const propertyTypeUrl = `${API_BASE_URL}/api/users?scoreIndex=4&scoreMin=0.6&limit=5`;
  
  const propertyTypeResult = await makeRequest(propertyTypeUrl);
  if (propertyTypeResult.success) {
    console.log('✅ Property type preference search successful');
    console.log(`Found ${propertyTypeResult.data.data.length} users preferring villas (score >= 0.6)`);
    if (propertyTypeResult.data.data.length > 0) {
      console.log('Sample user:', {
        name: propertyTypeResult.data.data[0].name,
        propertyTypeScore: propertyTypeResult.data.data[0].scoreVector[4],
        userType: propertyTypeResult.data.data[0].userType
      });
    }
  } else {
    console.log('❌ Property type preference search failed:', propertyTypeResult.data);
  }

  // Test 5: Combined search - Buyers with high budget in Algiers
  console.log('\n5️⃣ Testing combined search...');
  const combinedUrl = `${API_BASE_URL}/api/users?userType=BUYER&scoreIndex=0&scoreMin=0.6&scoreIndex=3&scoreMin=0.8&limit=5`;
  
  const combinedResult = await makeRequest(combinedUrl);
  if (combinedResult.success) {
    console.log('✅ Combined search successful');
    console.log(`Found ${combinedResult.data.data.length} buyers with high budget in major cities`);
    if (combinedResult.data.data.length > 0) {
      console.log('Sample user:', {
        name: combinedResult.data.data[0].name,
        priceScore: combinedResult.data.data[0].scoreVector[0],
        locationScore: combinedResult.data.data[0].scoreVector[3]
      });
    }
  } else {
    console.log('❌ Combined search failed:', combinedResult.data);
  }

  // Test 6: Search by family-friendly preferences (index 11)
  console.log('\n6️⃣ Testing family-friendly preference search (index 11)...');
  const familyUrl = `${API_BASE_URL}/api/users?scoreIndex=11&scoreMin=0.7&limit=5`;
  
  const familyResult = await makeRequest(familyUrl);
  if (familyResult.success) {
    console.log('✅ Family-friendly preference search successful');
    console.log(`Found ${familyResult.data.data.length} users with family-friendly preferences (score >= 0.7)`);
    if (familyResult.data.data.length > 0) {
      console.log('Sample user:', {
        name: familyResult.data.data[0].name,
        familyScore: familyResult.data.data[0].scoreVector[11],
        userType: familyResult.data.data[0].userType
      });
    }
  } else {
    console.log('❌ Family-friendly preference search failed:', familyResult.data);
  }

  // Test 7: Search by transaction type preference (index 7) - Sale vs Rent
  console.log('\n7️⃣ Testing transaction type preference search (index 7)...');
  const transactionUrl = `${API_BASE_URL}/api/users?scoreIndex=7&scoreMin=0.8&limit=5`;
  
  const transactionResult = await makeRequest(transactionUrl);
  if (transactionResult.success) {
    console.log('✅ Transaction type preference search successful');
    console.log(`Found ${transactionResult.data.data.length} users preferring to buy (score >= 0.8)`);
    if (transactionResult.data.data.length > 0) {
      console.log('Sample user:', {
        name: transactionResult.data.data[0].name,
        transactionScore: transactionResult.data.data[0].scoreVector[7],
        userType: transactionResult.data.data[0].userType
      });
    }
  } else {
    console.log('❌ Transaction type preference search failed:', transactionResult.data);
  }

  console.log('\n🎯 Score-Based Search Test Complete!');
  console.log('\n📋 Available Score Indices:');
  console.log('  0: Price preference (0.0-1.0)');
  console.log('  1: Area preference (0.0-1.0)');
  console.log('  2: Rooms preference (0.0-1.0)');
  console.log('  3: Location/Wilaya preference (0.0-1.0)');
  console.log('  4: Property type preference (0.0-1.0)');
  console.log('  5: Furnishing preference (0.0-1.0)');
  console.log('  6: Condition preference (0.0-1.0)');
  console.log('  7: Transaction type preference (0.0-1.0)');
  console.log('  8: Amenities preference (0.0-1.0)');
  console.log('  9: Neighborhood preference (0.0-1.0)');
  console.log('  10: Accessibility preference (0.0-1.0)');
  console.log('  11: Family-friendly preference (0.0-1.0)');
}

// Run the test
testScoreBasedSearch().catch(console.error); 