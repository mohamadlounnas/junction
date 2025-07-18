import { PrismaClient, UserType } from '../generated/prisma';

const prisma = new PrismaClient();

// Calculate cosine similarity between two vectors
function cosineSimilarity(vectorA: number[], vectorB: number[]): number {
  if (vectorA.length !== vectorB.length) {
    throw new Error('Vectors must have the same length');
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

async function testDatabase() {
  console.log('🧪 Testing database operations...\n');

  // Test 1: Count users and properties
  const userCount = await prisma.user.count();
  const propertyCount = await prisma.property.count();
  
  console.log(`📊 Database Statistics:`);
  console.log(`  Users: ${userCount}`);
  console.log(`  Properties: ${propertyCount}\n`);

  // Test 2: Get users by type
  const agents = await prisma.user.findMany({
    where: { userType: UserType.AGENT }
  });
  
  const buyers = await prisma.user.findMany({
    where: { userType: UserType.BUYER }
  });
  
  const tenants = await prisma.user.findMany({
    where: { userType: UserType.TENANT }
  });
  
  console.log(`👥 Users by Type:`);
  console.log(`  Agents: ${agents.length}`);
  console.log(`  Buyers: ${buyers.length}`);
  console.log(`  Tenants: ${tenants.length}\n`);

  // Test 3: Get properties with agents
  const propertiesWithAgents = await prisma.property.findMany({
    include: {
      agent: true
    },
    take: 5
  });
  
  console.log(`🏠 Sample Properties with Agents:`);
  propertiesWithAgents.forEach((property, index) => {
    console.log(`  ${index + 1}. ${property.title}`);
    console.log(`     Location: ${property.location}`);
    console.log(`     Price: ${property.price} DA`);
    console.log(`     Agent: ${property.agent?.name || 'No agent'}`);
    console.log(`     Score Vector: [${property.scoreVector.slice(0, 3).map(v => v.toFixed(2)).join(', ')}, ...]`);
    console.log('');
  });

  // Test 4: Vector similarity test
  console.log(`🔍 Testing Vector Similarity:`);
  
  const testUser = buyers[0];
  const testProperties = await prisma.property.findMany({
    take: 3
  });
  
  console.log(`\nComparing user "${testUser.name}" with properties:`);
  
  testProperties.forEach((property, index) => {
    const similarity = cosineSimilarity(testUser.scoreVector, property.scoreVector);
    console.log(`  ${index + 1}. ${property.title}`);
    console.log(`     Similarity: ${(similarity * 100).toFixed(2)}%`);
    console.log(`     User Vector: [${testUser.scoreVector.slice(0, 3).map(v => v.toFixed(2)).join(', ')}, ...]`);
    console.log(`     Property Vector: [${property.scoreVector.slice(0, 3).map(v => v.toFixed(2)).join(', ')}, ...]`);
    console.log('');
  });

  // Test 5: Find similar properties for a user
  console.log(`🎯 Finding Similar Properties for User:`);
  
  const targetUser = buyers[0];
  const allProperties = await prisma.property.findMany();
  
  // Calculate similarities and sort
  const similarities = allProperties.map(property => ({
    property,
    similarity: cosineSimilarity(targetUser.scoreVector, property.scoreVector)
  }));
  
  similarities.sort((a, b) => b.similarity - a.similarity);
  
  console.log(`\nTop 5 most similar properties for "${targetUser.name}":`);
  similarities.slice(0, 5).forEach((item, index) => {
    console.log(`  ${index + 1}. ${item.property.title}`);
    console.log(`     Location: ${item.property.location}`);
    console.log(`     Price: ${item.property.price} DA`);
    console.log(`     Similarity: ${(item.similarity * 100).toFixed(2)}%`);
    console.log('');
  });

  // Test 6: Test residential complex features
  console.log(`🏢 Testing Residential Complex Features:`);
  
  const residentialComplexes = await prisma.property.findMany({
    where: {
      isResidentialComplex: true
    }
  });
  
  console.log(`Found ${residentialComplexes.length} properties in residential complexes:`);
  residentialComplexes.slice(0, 3).forEach((property, index) => {
    console.log(`  ${index + 1}. ${property.title}`);
    console.log(`     Location: ${property.location}`);
    console.log(`     Parking: ${property.hasParking ? 'Yes' : 'No'}`);
    console.log(`     Security: ${property.hasSecurity ? 'Yes' : 'No'}`);
    console.log('');
  });

  console.log('✅ All tests completed successfully!');
}

testDatabase()
  .catch((e) => {
    console.error('❌ Test failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  }); 