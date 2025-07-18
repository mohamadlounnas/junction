import { PrismaClient } from '../generated/prisma';

const prisma = new PrismaClient();
const BASE_URL = 'http://localhost:3000/api';

// Test data
const testUser = {
  email: 'test@example.com',
  name: 'Test User',
  phone: '+213123456789',
  userType: 'BUYER' as const,
  scoreVector: [0.5, 0.3, 0.7, 0.2, 0.8, 0.4, 0.6, 0.1]
};

const testProperty = {
  title: 'Test Property',
  description: 'A beautiful test property',
  price: 15000,
  area: 120,
  rooms: 3,
  location: 'Algiers',
  propertyType: 'APARTMENT' as const,
  furnishing: 'FURNISHED' as const,
  condition: 'GOOD' as const,
  transactionType: 'RENT' as const,
  isResidentialComplex: true,
  hasParking: true,
  hasSecurity: false
};

// Helper function to make HTTP requests
async function makeRequest(url: string, options: RequestInit = {}) {
  try {
    const response = await fetch(url, {
      headers: {
        'Content-Type': 'application/json',
        ...options.headers,
      },
      ...options,
    });
    
    let data: any;
    const contentType = response.headers.get('content-type');
    if (contentType && contentType.includes('application/json')) {
      data = await response.json();
    } else {
      data = await response.text();
    }
    
    return {
      status: response.status,
      data,
      ok: response.ok,
    };
  } catch (error) {
    console.error('Request failed:', error);
    return {
      status: 500,
      data: { error: 'Request failed' },
      ok: false,
    };
  }
}

// Test functions
async function testHealthCheck() {
  console.log('🏥 Testing health check...');
  const result = await makeRequest(`${BASE_URL}/health`);
  
  if (result.ok && result.data.success) {
    console.log('✅ Health check passed');
    return true;
  } else {
    console.log('❌ Health check failed:', result.data);
    return false;
  }
}

async function testUserCRUD() {
  console.log('\n👤 Testing User CRUD operations...');
  
  // Create user
  console.log('Creating user...');
  const createResult = await makeRequest(`${BASE_URL}/users`, {
    method: 'POST',
    body: JSON.stringify(testUser),
  });
  
  if (!createResult.ok) {
    console.log('❌ Failed to create user:', createResult.data);
    return null;
  }
  
  const userId = createResult.data.data.id;
  console.log('✅ User created:', userId);
  
  // Get user
  console.log('Getting user...');
  const getResult = await makeRequest(`${BASE_URL}/users/${userId}`);
  
  if (getResult.ok) {
    console.log('✅ User retrieved successfully');
  } else {
    console.log('❌ Failed to get user:', getResult.data);
  }
  
  // Update user
  console.log('Updating user...');
  const updateResult = await makeRequest(`${BASE_URL}/users/${userId}`, {
    method: 'PUT',
    body: JSON.stringify({
      name: 'Updated Test User',
      phone: '+213987654321'
    }),
  });
  
  if (updateResult.ok) {
    console.log('✅ User updated successfully');
  } else {
    console.log('❌ Failed to update user:', updateResult.data);
  }
  
  // Get user score
  console.log('Getting user score...');
  const scoreResult = await makeRequest(`${BASE_URL}/users/${userId}/score`);
  
  if (scoreResult.ok) {
    console.log('✅ User score retrieved:', scoreResult.data.data.scoreVector);
  } else {
    console.log('❌ Failed to get user score:', scoreResult.data);
  }
  
  // Update user score
  console.log('Updating user score...');
  const newScore = [0.8, 0.2, 0.9, 0.1, 0.7, 0.3, 0.5, 0.4];
  const updateScoreResult = await makeRequest(`${BASE_URL}/users/${userId}/score`, {
    method: 'PUT',
    body: JSON.stringify({ scoreVector: newScore }),
  });
  
  if (updateScoreResult.ok) {
    console.log('✅ User score updated successfully');
  } else {
    console.log('❌ Failed to update user score:', updateScoreResult.data);
  }
  
  // Get all users with filters
  console.log('Getting users with filters...');
  const listResult = await makeRequest(`${BASE_URL}/users?userType=BUYER&limit=5`);
  
  if (listResult.ok) {
    console.log('✅ Users list retrieved:', listResult.data.data.length, 'users');
  } else {
    console.log('❌ Failed to get users list:', listResult.data);
  }
  
  return userId;
}

async function testPropertyCRUD() {
  console.log('\n🏠 Testing Property CRUD operations...');
  
  // Get an agent for the property
  const agent = await prisma.user.findFirst({
    where: { userType: 'AGENT' }
  });
  
  const propertyData = {
    ...testProperty,
    agentId: agent?.id
  };
  
  // Create property
  console.log('Creating property...');
  const createResult = await makeRequest(`${BASE_URL}/properties`, {
    method: 'POST',
    body: JSON.stringify(propertyData),
  });
  
  if (!createResult.ok) {
    console.log('❌ Failed to create property:', createResult.data);
    return null;
  }
  
  const propertyId = createResult.data.data.id;
  console.log('✅ Property created:', propertyId);
  
  // Get property
  console.log('Getting property...');
  const getResult = await makeRequest(`${BASE_URL}/properties/${propertyId}`);
  
  if (getResult.ok) {
    console.log('✅ Property retrieved successfully');
  } else {
    console.log('❌ Failed to get property:', getResult.data);
  }
  
  // Update property
  console.log('Updating property...');
  const updateResult = await makeRequest(`${BASE_URL}/properties/${propertyId}`, {
    method: 'PUT',
    body: JSON.stringify({
      title: 'Updated Test Property',
      price: 18000,
      description: 'Updated description'
    }),
  });
  
  if (updateResult.ok) {
    console.log('✅ Property updated successfully');
  } else {
    console.log('❌ Failed to update property:', updateResult.data);
  }
  
  // Get property score
  console.log('Getting property score...');
  const scoreResult = await makeRequest(`${BASE_URL}/properties/${propertyId}/score`);
  
  if (scoreResult.ok) {
    console.log('✅ Property score retrieved:', scoreResult.data.data.scoreVector);
  } else {
    console.log('❌ Failed to get property score:', scoreResult.data);
  }
  
  // Sync property score
  console.log('Syncing property score...');
  const syncResult = await makeRequest(`${BASE_URL}/properties/${propertyId}/sync-score`, {
    method: 'POST',
  });
  
  if (syncResult.ok) {
    console.log('✅ Property score synced successfully');
  } else {
    console.log('❌ Failed to sync property score:', syncResult.data);
  }
  
  // Get all properties with filters
  console.log('Getting properties with filters...');
  const listResult = await makeRequest(`${BASE_URL}/properties?propertyType=APARTMENT&transactionType=RENT&priceMin=10000&priceMax=20000&limit=5`);
  
  if (listResult.ok) {
    console.log('✅ Properties list retrieved:', listResult.data.data.length, 'properties');
  } else {
    console.log('❌ Failed to get properties list:', listResult.data);
  }
  
  return propertyId;
}

async function testRecommendations() {
  console.log('\n🎯 Testing Recommendations...');
  
  // Get a user and property for testing
  const user = await prisma.user.findFirst({
    where: { userType: 'BUYER' }
  });
  
  const property = await prisma.property.findFirst({
    where: { status: 'ACTIVE' }
  });
  
  if (!user || !property) {
    console.log('❌ No user or property found for recommendations test');
    return;
  }
  
  // Test user recommendations
  console.log('Testing user recommendations...');
  const userRecResult = await makeRequest(`${BASE_URL}/recommendations/user/${user.id}?limit=5&minScore=0.2`);
  
  if (userRecResult.ok) {
    console.log('✅ User recommendations generated:', userRecResult.data.data.length, 'recommendations');
    if (userRecResult.data.data.length > 0) {
      console.log('   Top recommendation similarity:', userRecResult.data.data[0].similarity);
    }
  } else {
    console.log('❌ Failed to generate user recommendations:', userRecResult.data);
  }
  
  // Test property recommendations
  console.log('Testing property recommendations...');
  const propertyRecResult = await makeRequest(`${BASE_URL}/recommendations/property/${property.id}?limit=5&minScore=0.2`);
  
  if (propertyRecResult.ok) {
    console.log('✅ Property recommendations generated:', propertyRecResult.data.data.length, 'recommendations');
    if (propertyRecResult.data.data.length > 0) {
      console.log('   Top recommendation similarity:', propertyRecResult.data.data[0].similarity);
    }
  } else {
    console.log('❌ Failed to generate property recommendations:', propertyRecResult.data);
  }
  
  // Test recommendations with filters
  console.log('Testing recommendations with filters...');
  const filteredRecResult = await makeRequest(`${BASE_URL}/recommendations/user/${user.id}?limit=3&location=Algiers&propertyType=APARTMENT&priceMax=20000`);
  
  if (filteredRecResult.ok) {
    console.log('✅ Filtered recommendations generated:', filteredRecResult.data.data.length, 'recommendations');
  } else {
    console.log('❌ Failed to generate filtered recommendations:', filteredRecResult.data);
  }
}

async function testStatistics() {
  console.log('\n📊 Testing Statistics...');
  
  const statsResult = await makeRequest(`${BASE_URL}/stats`);
  
  if (statsResult.ok) {
    console.log('✅ Statistics retrieved successfully');
    console.log('   Total users:', statsResult.data.data.users.total);
    console.log('   Total properties:', statsResult.data.data.properties.total);
    console.log('   Users by type:', statsResult.data.data.users.byType);
    console.log('   Properties by transaction type:', statsResult.data.data.properties.byTransactionType);
  } else {
    console.log('❌ Failed to get statistics:', statsResult.data);
  }
}

async function testErrorHandling() {
  console.log('\n🚨 Testing Error Handling...');
  
  // Test invalid user ID
  console.log('Testing invalid user ID...');
  const invalidUserResult = await makeRequest(`${BASE_URL}/users/invalid-id`);
  
  if (!invalidUserResult.ok && invalidUserResult.status === 404) {
    console.log('✅ Invalid user ID handled correctly');
  } else {
    console.log('❌ Invalid user ID not handled correctly:', invalidUserResult.data);
  }
  
  // Test invalid property ID
  console.log('Testing invalid property ID...');
  const invalidPropertyResult = await makeRequest(`${BASE_URL}/properties/invalid-id`);
  
  if (!invalidPropertyResult.ok && invalidPropertyResult.status === 404) {
    console.log('✅ Invalid property ID handled correctly');
  } else {
    console.log('❌ Invalid property ID not handled correctly:', invalidPropertyResult.data);
  }
  
  // Test validation errors
  console.log('Testing validation errors...');
  const validationResult = await makeRequest(`${BASE_URL}/users`, {
    method: 'POST',
    body: JSON.stringify({
      email: 'invalid-email',
      name: 'A', // Too short
      userType: 'INVALID_TYPE'
    }),
  });
  
  if (!validationResult.ok && validationResult.status === 400) {
    console.log('✅ Validation errors handled correctly');
  } else {
    console.log('❌ Validation errors not handled correctly:', validationResult.data);
  }
}

async function cleanup() {
  console.log('\n🧹 Cleaning up test data...');
  
  // Clean up test users and properties
  await prisma.user.deleteMany({
    where: {
      email: testUser.email
    }
  });
  
  await prisma.property.deleteMany({
    where: {
      title: testProperty.title
    }
  });
  
  console.log('✅ Cleanup completed');
}

// Main test function
async function runTests() {
  console.log('🚀 Starting Smart Contact API Tests\n');
  
  try {
    // Test health check
    const healthOk = await testHealthCheck();
    if (!healthOk) {
      console.log('❌ Health check failed, stopping tests');
      return;
    }
    
    // Test CRUD operations
    const userId = await testUserCRUD();
    const propertyId = await testPropertyCRUD();
    
    // Test recommendations
    await testRecommendations();
    
    // Test statistics
    await testStatistics();
    
    // Test error handling
    await testErrorHandling();
    
    // Cleanup
    await cleanup();
    
    console.log('\n🎉 All tests completed successfully!');
    
  } catch (error) {
    console.error('❌ Test failed with error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

// Run tests
runTests(); 