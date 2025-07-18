import { PrismaClient, UserType, PropertyType, FurnishingType, ConditionType, TransactionType, PropertyStatus } from '../generated/prisma';

const prisma = new PrismaClient();

// Algerian locations
const locations = [
  'Bab Ezzouar', 'Alger Centre', 'Hydra', 'El Biar', 'Birkhadem', 
  'Cheraga', 'Ben Aknoun', 'Dely Ibrahim', 'Bouzareah', 'Oued Koriche',
  'Bab El Oued', 'Casbah', 'Belouizdad', 'Hamma', 'El Harrach',
  'Bachdjerrah', 'Bordj El Kiffan', 'Rouiba', 'Reghaia', 'Dar El Beida'
];

// Property titles
const propertyTitles = [
  'Appartement moderne avec vue mer',
  'Villa luxueuse avec jardin privé',
  'Studio meublé dans résidence sécurisée',
  'Duplex avec terrasse panoramique',
  'Maison traditionnelle rénovée',
  'Appartement de standing avec parking',
  'Villa contemporaine avec piscine',
  'Studio étudiant près de l\'université',
  'Appartement familial spacieux',
  'Villa d\'architecte avec garage'
];

// Generate random score vector
function generateRandomScoreVector(): number[] {
  return Array.from({ length: 8 }, () => Math.random());
}

// Generate property score vector based on actual data
function generatePropertyScoreVector(
  price: number,
  area: number,
  rooms: number,
  location: string,
  propertyType: PropertyType,
  furnishing: FurnishingType,
  condition: ConditionType,
  transactionType: TransactionType
): number[] {
  // Normalize price (assuming range 2000-41000)
  const normalizedPrice = Math.min(Math.max((price - 2000) / (41000 - 2000), 0), 1);
  
  // Normalize area (assuming range 20-500)
  const normalizedArea = Math.min(Math.max((area - 20) / (500 - 20), 0), 1);
  
  // Normalize rooms (assuming max 5 rooms)
  const normalizedRooms = Math.min(rooms / 5, 1);
  
  // Location encoding (simple hash-based)
  const locationHash = location.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0);
  const normalizedLocation = (locationHash % 100) / 100;
  
  // Property type encoding
  const propertyTypeEncoding = {
    [PropertyType.APARTMENT]: 0.2,
    [PropertyType.VILLA]: 0.8,
    [PropertyType.OFFICE]: 0.5,
    [PropertyType.LAND]: 0.1
  };
  
  // Furnishing encoding
  const furnishingEncoding = {
    [FurnishingType.FURNISHED]: 1.0,
    [FurnishingType.SEMI_FURNISHED]: 0.5,
    [FurnishingType.UNFURNISHED]: 0.0
  };
  
  // Condition encoding
  const conditionEncoding = {
    [ConditionType.POOR]: 0.0,
    [ConditionType.FAIR]: 0.3,
    [ConditionType.GOOD]: 0.7,
    [ConditionType.EXCELLENT]: 1.0
  };
  
  // Transaction type encoding
  const transactionTypeEncoding = {
    [TransactionType.RENT]: 0.0,
    [TransactionType.SALE]: 1.0
  };
  
  return [
    normalizedPrice,
    normalizedArea,
    normalizedRooms,
    normalizedLocation,
    propertyTypeEncoding[propertyType],
    furnishingEncoding[furnishing],
    conditionEncoding[condition],
    transactionTypeEncoding[transactionType]
  ];
}

async function seed() {
  console.log('🌱 Starting database seeding...');

  // Clear existing data
  await prisma.property.deleteMany();
  await prisma.user.deleteMany();
  console.log('🗑️  Cleared existing data');

  // Create users
  const users: any[] = [];
  
  // Create agents
  for (let i = 0; i < 5; i++) {
    const user = await prisma.user.create({
      data: {
        email: `agent${i + 1}@smartcontact.dz`,
        name: `Agent ${i + 1}`,
        phone: `+213 5${Math.floor(Math.random() * 90000000) + 10000000}`,
        userType: UserType.AGENT,
        scoreVector: generateRandomScoreVector()
      }
    });
    users.push(user);
    console.log(`👤 Created agent: ${user.name}`);
  }

  // Create buyers/tenants
  for (let i = 0; i < 20; i++) {
    const userType = Math.random() > 0.5 ? UserType.BUYER : UserType.TENANT;
    const user = await prisma.user.create({
      data: {
        email: `user${i + 1}@example.com`,
        name: `User ${i + 1}`,
        phone: `+213 5${Math.floor(Math.random() * 90000000) + 10000000}`,
        userType,
        scoreVector: generateRandomScoreVector()
      }
    });
    users.push(user);
    console.log(`👤 Created ${userType.toLowerCase()}: ${user.name}`);
  }

  // Create properties
  const agents = users.filter((u: any) => u.userType === UserType.AGENT);
  
  for (let i = 0; i < 50; i++) {
    const price = Math.floor(Math.random() * 39000) + 2000; // 2000-41000
    const area = Math.floor(Math.random() * 480) + 20; // 20-500
    const rooms = Math.floor(Math.random() * 5) + 1; // 1-5 rooms
    const location = locations[Math.floor(Math.random() * locations.length)];
    const propertyType = Object.values(PropertyType)[Math.floor(Math.random() * 4)];
    const furnishing = Object.values(FurnishingType)[Math.floor(Math.random() * 3)];
    const condition = Object.values(ConditionType)[Math.floor(Math.random() * 4)];
    const transactionType = Object.values(TransactionType)[Math.floor(Math.random() * 2)];
    const isResidentialComplex = Math.random() > 0.7; // 30% chance
    const hasParking = Math.random() > 0.5; // 50% chance
    const hasSecurity = Math.random() > 0.6; // 40% chance
    
    const scoreVector = generatePropertyScoreVector(
      price, area, rooms, location, propertyType, furnishing, condition, transactionType
    );

    const property = await prisma.property.create({
      data: {
        title: propertyTitles[Math.floor(Math.random() * propertyTitles.length)],
        description: `Beautiful property in ${location} with ${rooms} rooms and ${area}m² area.`,
        price,
        area,
        rooms,
        location,
        propertyType,
        furnishing,
        condition,
        transactionType,
        scoreVector,
        agentId: agents[Math.floor(Math.random() * agents.length)]?.id,
        isResidentialComplex,
        hasParking,
        hasSecurity
      }
    });
    
    console.log(`🏠 Created property: ${property.title} in ${property.location}`);
  }

  console.log('✅ Database seeding completed!');
  console.log(`📊 Created ${users.length} users and 50 properties`);
  
  // Show some statistics
  const userStats = await prisma.user.groupBy({
    by: ['userType'],
    _count: true
  });
  
  console.log('\n📈 User Statistics:');
  userStats.forEach(stat => {
    console.log(`  ${stat.userType}: ${stat._count}`);
  });
  
  const propertyStats = await prisma.property.groupBy({
    by: ['transactionType'],
    _count: true
  });
  
  console.log('\n📈 Property Statistics:');
  propertyStats.forEach(stat => {
    console.log(`  ${stat.transactionType}: ${stat._count}`);
  });
}

seed()
  .catch((e) => {
    console.error('❌ Error seeding database:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  }); 