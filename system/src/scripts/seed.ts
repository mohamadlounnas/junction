/**
 * Seed Script - Smart Contact System
 * Populates database with sample Algerian real estate data
 */

import { PrismaClient } from '@prisma/client';
import { generateScoresFromContact, generateScoresFromProperty } from '../services/score-generator';
import { updatePropertyGeohash } from '../services/geospatial';

const prisma = new PrismaClient();

// Sample contacts data
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
    transactionType: 'SALE' as const,
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
    transactionType: 'RENT' as const,
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
    transactionType: 'SALE' as const,
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
    transactionType: 'SALE' as const,
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
    transactionType: 'RENT' as const,
    familySize: 1,
    hasChildren: false,
    minRooms: 1,
    maxRooms: 2,
    minArea: 40,
    maxArea: 80,
    requiresParking: false,
    requiresSecurity: false
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
    for (const contactData of sampleContacts) {
      const scores = generateScoresFromContact(contactData);
      await prisma.contact.create({
        data: {
          ...contactData,
          scores
        }
      });
    }

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

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  }); 