/**
 * Seed Script - Smart Contact System
 * Populates database with sample Algerian real estate data
 * Enhanced with dual transaction type support
 */

import { PrismaClient } from '@prisma/client';
import { generateScoresFromContact, generateAllScoresFromContact, generateScoresFromProperty } from '../services/score-generator';
import { updatePropertyGeohash } from '../services/geospatial';

const prisma = new PrismaClient();

// Sample contacts data with enhanced dual transaction support
const sampleContacts = [
  {
    email: 'ahmed.benali@email.dz',
    name: 'Ahmed Ben Ali',
    phone: '+213 555 123 456',
    type: 'BUYER' as const,
    budgetMin: 15000000, // 15M DZD
    budgetMax: 25000000, // 25M DZD
    locationWilayas: ['Algiers', 'Boumerdès'],
    locationCities: ['Hydra', 'Bab Ezzouar'],
    propertyTypes: ['VILLA' as const, 'APARTMENT' as const],
    transactionType: 'SALE' as const, // Legacy field
    transactionTypes: ['SALE' as const], // Enhanced field
    primaryTransactionType: 'SALE' as const,
    transactionFlexibility: 0.3, // Low flexibility - prefers buying
    familySize: 4,
    hasChildren: true,
    minRooms: 3,
    maxRooms: 5,
    minArea: 120,
    maxArea: 250,
    requiresParking: true,
    requiresSecurity: true
  },
  {
    email: 'fatima.kada@email.dz',
    name: 'Fatima Kada',
    phone: '+213 666 789 012',
    type: 'TENANT' as const,
    budgetMin: 50000, // 50K DZD/month
    budgetMax: 80000, // 80K DZD/month
    locationWilayas: ['Oran', 'Tlemcen'],
    locationCities: ['Es Senia', 'Oran Centre'],
    propertyTypes: ['APARTMENT' as const],
    transactionType: 'RENT' as const, // Legacy field
    transactionTypes: ['RENT' as const], // Enhanced field
    primaryTransactionType: 'RENT' as const,
    transactionFlexibility: 0.2, // Very low flexibility - only rents
    familySize: 2,
    hasChildren: false,
    minRooms: 2,
    maxRooms: 3,
    minArea: 80,
    maxArea: 120,
    requiresParking: false,
    requiresSecurity: true
  },
  {
    email: 'karim.investor@business.dz',
    name: 'Karim Meziane',
    phone: '+213 777 345 678',
    type: 'INVESTOR' as const,
    budgetMin: 30000000, // 30M DZD
    budgetMax: 100000000, // 100M DZD
    locationWilayas: ['Algiers', 'Oran', 'Constantine'],
    locationCities: ['Algiers Centre', 'Oran Centre', 'Constantine Centre'],
    propertyTypes: ['OFFICE' as const, 'SHOP' as const, 'APARTMENT' as const],
    transactionType: 'SALE' as const, // Legacy field
    transactionTypes: ['SALE' as const, 'RENT' as const], // Enhanced field - interested in both
    primaryTransactionType: 'SALE' as const, // Prefers buying for investment
    transactionFlexibility: 0.8, // High flexibility - open to both
    familySize: 1,
    hasChildren: false,
    minArea: 50,
    maxArea: 500,
    requiresParking: true,
    requiresSecurity: true
  },
  {
    email: 'amina.family@gmail.com',
    name: 'Amina Boudjemaa',
    phone: '+213 555 456 789',
    type: 'BUYER' as const,
    budgetMin: 8000000, // 8M DZD
    budgetMax: 15000000, // 15M DZD
    locationWilayas: ['Constantine', 'Annaba'],
    locationCities: ['Constantine', 'Annaba Centre'],
    propertyTypes: ['HOUSE' as const, 'APARTMENT' as const],
    transactionType: 'SALE' as const, // Legacy field
    transactionTypes: ['SALE' as const, 'RENT' as const], // Enhanced field - flexible
    primaryTransactionType: 'SALE' as const, // Prefers buying
    transactionFlexibility: 0.6, // Medium flexibility
    familySize: 6,
    hasChildren: true,
    minRooms: 4,
    maxRooms: 6,
    minArea: 150,
    maxArea: 300,
    requiresParking: true,
    requiresSecurity: false
  },
  {
    email: 'youcef.student@univ.dz',
    name: 'Youcef Hamidi',
    phone: '+213 666 123 789',
    type: 'TENANT' as const,
    budgetMin: 25000, // 25K DZD/month
    budgetMax: 40000, // 40K DZD/month
    locationWilayas: ['Algiers'],
    locationCities: ['Bab Ezzouar', 'Ben Aknoun'],
    propertyTypes: ['APARTMENT' as const],
    transactionType: 'RENT' as const, // Legacy field
    transactionTypes: ['RENT' as const], // Enhanced field
    primaryTransactionType: 'RENT' as const,
    transactionFlexibility: 0.1, // Very low flexibility - student budget
    familySize: 1,
    hasChildren: false,
    minRooms: 1,
    maxRooms: 2,
    minArea: 40,
    maxArea: 80,
    requiresParking: false,
    requiresSecurity: false
  },
  // New contact demonstrating dual transaction flexibility
  {
    email: 'sara.flexible@email.dz',
    name: 'Sara Benmoussa',
    phone: '+213 555 999 888',
    type: 'BUYER' as const,
    budgetMin: 12000000, // 12M DZD
    budgetMax: 20000000, // 20M DZD
    locationWilayas: ['Algiers', 'Tipaza'],
    locationCities: ['Hydra', 'Cherchell'],
    propertyTypes: ['VILLA' as const, 'APARTMENT' as const],
    transactionType: 'SALE' as const, // Legacy field
    transactionTypes: ['SALE' as const, 'RENT' as const], // Enhanced field - very flexible
    primaryTransactionType: 'SALE' as const, // Prefers buying but open to renting
    transactionFlexibility: 0.9, // Very high flexibility
    familySize: 3,
    hasChildren: true,
    minRooms: 3,
    maxRooms: 4,
    minArea: 100,
    maxArea: 200,
    requiresParking: true,
    requiresSecurity: true
  }
];

// Sample properties data
const sampleProperties = [
  {
    title: 'Villa moderne avec jardin à Hydra',
    description: 'Magnifique villa de 200m² avec jardin privé, située dans le quartier résidentiel d\'Hydra. Vue panoramique sur la baie d\'Alger.',
    price: 22000000, // 22M DZD
    area: 200,
    rooms: 4,
    bathrooms: 3,
    wilaya: 'Algiers',
    city: 'Hydra',
    address: 'Rue des Oliviers, Hydra',
    latitude: 36.7333,
    longitude: 3.1167,
    propertyType: 'VILLA' as const,
    transactionType: 'SALE' as const,
    furnishing: 'SEMI_FURNISHED' as const,
    condition: 'EXCELLENT' as const,
    hasParking: true,
    hasSecurity: true,
    hasElevator: false,
    hasGarden: true,
    hasBalcony: true,
    hasSwimmingPool: false,
    buildingAge: 5,
    floor: 0,
    featured: true
  },
  {
    title: 'Appartement F3 à Es Senia',
    description: 'Appartement de 85m² au 3ème étage, proche des commodités. Idéal pour famille.',
    price: 65000, // 65K DZD/month
    area: 85,
    rooms: 3,
    bathrooms: 2,
    wilaya: 'Oran',
    city: 'Es Senia',
    address: 'Cité des Palmiers, Es Senia',
    latitude: 35.6500,
    longitude: -0.6167,
    propertyType: 'APARTMENT' as const,
    transactionType: 'RENT' as const,
    furnishing: 'FURNISHED' as const,
    condition: 'GOOD' as const,
    hasParking: true,
    hasSecurity: false,
    hasElevator: true,
    hasGarden: false,
    hasBalcony: true,
    hasSwimmingPool: false,
    buildingAge: 10,
    floor: 3,
    totalFloors: 5,
    featured: false
  },
  {
    title: 'Bureau 120m² Centre d\'Alger',
    description: 'Espace de bureau moderne au cœur d\'Alger, parfait pour entreprises. Accès facile et parking.',
    price: 45000000, // 45M DZD
    area: 120,
    rooms: 6,
    bathrooms: 2,
    wilaya: 'Algiers',
    city: 'Alger Centre',
    address: 'Rue Didouche Mourad, Alger',
    propertyType: 'OFFICE' as const,
    transactionType: 'SALE' as const,
    furnishing: 'UNFURNISHED' as const,
    condition: 'NEW' as const,
    hasParking: true,
    hasSecurity: true,
    hasElevator: true,
    hasGarden: false,
    hasBalcony: false,
    hasSwimmingPool: false,
    buildingAge: 1,
    floor: 2,
    totalFloors: 8,
    featured: true
  },
  {
    title: 'Maison traditionnelle à Constantine',
    description: 'Belle maison traditionnelle rénovée, 180m², avec cour intérieure. Quartier calme.',
    price: 12000000, // 12M DZD
    area: 180,
    rooms: 5,
    bathrooms: 3,
    wilaya: 'Constantine',
    city: 'Constantine',
    address: 'Vieille ville, Constantine',
    propertyType: 'HOUSE' as const,
    transactionType: 'SALE' as const,
    furnishing: 'UNFURNISHED' as const,
    condition: 'GOOD' as const,
    hasParking: false,
    hasSecurity: false,
    hasElevator: false,
    hasGarden: true,
    hasBalcony: false,
    hasSwimmingPool: false,
    buildingAge: 50,
    floor: 0,
    featured: false
  },
  {
    title: 'Studio meublé Ben Aknoun',
    description: 'Studio moderne et bien équipé, proche de l\'université. Parfait pour étudiant.',
    price: 35000, // 35K DZD/month
    area: 45,
    rooms: 1,
    bathrooms: 1,
    wilaya: 'Algiers',
    city: 'Ben Aknoun',
    address: 'Résidence El Yasmine, Ben Aknoun',
    propertyType: 'APARTMENT' as const,
    transactionType: 'RENT' as const,
    furnishing: 'FURNISHED' as const,
    condition: 'GOOD' as const,
    hasParking: false,
    hasSecurity: true,
    hasElevator: true,
    hasGarden: false,
    hasBalcony: true,
    hasSwimmingPool: false,
    buildingAge: 8,
    floor: 4,
    totalFloors: 6,
    featured: false
  },
  {
    title: 'Terrain constructible à Tipaza',
    description: 'Terrain de 500m² avec vue sur mer, proche de Tipaza. Idéal pour construction villa.',
    price: 8000000, // 8M DZD
    area: 500,
    rooms: 0,
    bathrooms: 0,
    wilaya: 'Tipaza',
    city: 'Tipaza',
    address: 'Route côtière, Tipaza',
    propertyType: 'LAND' as const,
    transactionType: 'SALE' as const,
    furnishing: 'UNFURNISHED' as const,
    condition: 'NEW' as const,
    hasParking: false,
    hasSecurity: false,
    hasElevator: false,
    hasGarden: false,
    hasBalcony: false,
    hasSwimmingPool: false,
    floor: 0,
    featured: true
  }
];

// Sample settings data
const sampleSettings = [
  {
    key: 'recommendation_threshold',
    value: '0.3',
    type: 'NUMBER' as const,
    category: 'algorithm',
    description: 'Minimum similarity threshold for recommendations',
    isPublic: false
  },
  {
    key: 'max_recommendations',
    value: '50',
    type: 'NUMBER' as const,
    category: 'algorithm',
    description: 'Maximum number of recommendations to return',
    isPublic: false
  },
  {
    key: 'learning_rate',
    value: '0.1',
    type: 'NUMBER' as const,
    category: 'algorithm',
    description: 'Learning rate for preference updates',
    isPublic: false
  },
  {
    key: 'cache_ttl_recommendations',
    value: '600',
    type: 'NUMBER' as const,
    category: 'system',
    description: 'Cache TTL for recommendations in seconds',
    isPublic: false
  },
  {
    key: 'enable_learning',
    value: 'true',
    type: 'BOOLEAN' as const,
    category: 'algorithm',
    description: 'Enable learning from successful sales',
    isPublic: false
  },
  {
    key: 'collaborative_learning_enabled',
    value: 'true',
    type: 'BOOLEAN' as const,
    category: 'algorithm',
    description: 'Enable collaborative learning from similar users and properties',
    isPublic: false
  },
  {
    key: 'user_similarity_threshold',
    value: '0.8',
    type: 'NUMBER' as const,
    category: 'algorithm',
    description: 'Minimum similarity threshold for users to learn from each other',
    isPublic: false
  },
  {
    key: 'property_similarity_threshold',
    value: '0.8',
    type: 'NUMBER' as const,
    category: 'algorithm',
    description: 'Minimum similarity threshold for properties to learn from sales',
    isPublic: false
  },
  {
    key: 'collaborative_learning_rate',
    value: '0.1',
    type: 'NUMBER' as const,
    category: 'algorithm',
    description: 'Base learning rate for collaborative learning algorithm',
    isPublic: false
  },
  {
    key: 'enable_time_weighting',
    value: 'true',
    type: 'BOOLEAN' as const,
    category: 'algorithm',
    description: 'Enable time-based weighting for learning (faster decisions = stronger signal)',
    isPublic: false
  },
  {
    key: 'enable_success_weighting',
    value: 'true',
    type: 'BOOLEAN' as const,
    category: 'algorithm',
    description: 'Enable success score weighting for learning',
    isPublic: false
  },
  {
    key: 'genetic_algorithm_enabled',
    value: 'false',
    type: 'BOOLEAN' as const,
    category: 'algorithm',
    description: 'Enable genetic algorithm optimization (experimental)',
    isPublic: false
  },
  {
    key: 'genetic_algorithm_population_size',
    value: '20',
    type: 'NUMBER' as const,
    category: 'algorithm',
    description: 'Population size for genetic algorithm',
    isPublic: false
  },
  {
    key: 'genetic_algorithm_generations',
    value: '50',
    type: 'NUMBER' as const,
    category: 'algorithm',
    description: 'Number of generations for genetic algorithm',
    isPublic: false
  },
  {
    key: 'genetic_algorithm_mutation_rate',
    value: '0.15',
    type: 'NUMBER' as const,
    category: 'algorithm',
    description: 'Mutation rate for genetic algorithm',
    isPublic: false
  },
  {
    key: 'auto_learn_on_sale',
    value: 'true',
    type: 'BOOLEAN' as const,
    category: 'algorithm',
    description: 'Automatically trigger learning when new sales are added',
    isPublic: false
  },
  {
    key: 'agent_commission_rate',
    value: '0.05',
    type: 'NUMBER' as const,
    category: 'quotes',
    description: 'Default agent commission rate (5%)',
    isPublic: false
  },
  {
    key: 'legal_fees_rate',
    value: '0.02',
    type: 'NUMBER' as const,
    category: 'quotes',
    description: 'Default legal fees rate (2%)',
    isPublic: false
  },
  {
    key: 'administrative_fees',
    value: '50000',
    type: 'NUMBER' as const,
    category: 'quotes',
    description: 'Fixed administrative fees in DZD',
    isPublic: false
  },
  {
    key: 'tax_rate',
    value: '0.19',
    type: 'NUMBER' as const,
    category: 'quotes',
    description: 'VAT/Tax rate (19%)',
    isPublic: false
  },
  {
    key: 'quote_validity_days',
    value: '30',
    type: 'NUMBER' as const,
    category: 'quotes',
    description: 'Default quote validity period in days',
    isPublic: false
  },
  {
    key: 'default_currency',
    value: 'DZD',
    type: 'STRING' as const,
    category: 'quotes',
    description: 'Default currency for quotes',
    isPublic: false
  },
  {
    key: 'default_language',
    value: 'fr',
    type: 'STRING' as const,
    category: 'quotes',
    description: 'Default language for quotes (ar/fr/en)',
    isPublic: false
  }
];

async function main() {
  console.log('🌱 Starting database seed...');

  try {
    // Clear existing data
    console.log('🧹 Cleaning existing data...');
    await prisma.sale.deleteMany();
    await prisma.contact.deleteMany();
    await prisma.property.deleteMany();
    await prisma.setting.deleteMany();

    // Create settings
    console.log('⚙️ Creating settings...');
    for (const setting of sampleSettings) {
      await prisma.setting.create({ data: setting });
    }

    // Create contacts with auto-generated scores
    console.log('👥 Creating contacts...');
    await seedContacts();

    // Create properties with auto-generated scores
    console.log('🏠 Creating properties...');
    for (const propertyData of sampleProperties) {
      const scores = generateScoresFromProperty(propertyData);
      const geohashData = updatePropertyGeohash(propertyData);
      await prisma.property.create({
        data: {
          ...propertyData,
          scores,
          ...geohashData
        }
      });
    }

    // Create some sample sales for learning data
    console.log('💰 Creating sample sales...');
    const contacts = await prisma.contact.findMany();
    const properties = await prisma.property.findMany();

    if (contacts.length > 0 && properties.length > 0) {
      // Create a few successful sales
      await prisma.sale.create({
        data: {
          contactId: contacts[0].id,
          propertyId: properties[0].id,
          salePrice: properties[0].price,
          successScore: 0.9,
          timeToDecision: 15,
          viewCount: 3,
          notes: 'Client très satisfait, villa correspondait parfaitement aux critères'
        }
      });

      await prisma.sale.create({
        data: {
          contactId: contacts[1].id,
          propertyId: properties[1].id,
          salePrice: properties[1].price * 12, // Annual rent
          successScore: 0.8,
          timeToDecision: 7,
          viewCount: 2,
          notes: 'Location rapide, appartement bien situé'
        }
      });
    }

    console.log('✅ Database seeded successfully!');
    console.log(`📊 Created:`);
    console.log(`   - ${sampleContacts.length} contacts`);
    console.log(`   - ${sampleProperties.length} properties`);
    console.log(`   - ${sampleSettings.length} settings`);
    console.log(`   - 2 sample sales`);

  } catch (error) {
    console.error('❌ Seed failed:', error);
    throw error;
  }
}

async function seedContacts() {
  console.log('📝 Seeding contacts...');
  
  for (const contactData of sampleContacts) {
    try {
      // Generate enhanced scores with dual transaction support
      const allScores = generateAllScoresFromContact(contactData);
      
      // Prepare contact data with backward compatibility
      const contact = await prisma.contact.create({
        data: {
          ...contactData,
          scores: allScores.scores,
          transactionScores: allScores.transactionScores,
          // Ensure legacy field is set for backward compatibility
          transactionType: (contactData.primaryTransactionType || contactData.transactionTypes?.[0] || contactData.transactionType) as 'RENT' | 'SALE'
        }
      });
      
      console.log(`   ✅ Created ${contact.name} (${contact.type}) - Transaction: ${contact.transactionType}`);
      if (contact.transactionTypes?.length > 1) {
        console.log(`      🔄 Flexible: ${contact.transactionTypes.join(', ')} (Primary: ${contact.primaryTransactionType})`);
      }
    } catch (error) {
      console.error(`   ❌ Failed to create contact ${contactData.name}:`, error);
    }
  }
  
  console.log(`📊 Created ${sampleContacts.length} contacts with enhanced transaction support`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  }); 