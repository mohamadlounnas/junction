/**
 * Smart Contact Score Generation Service
 * 
 * Generates 12-dimensional vectors for contact preferences and property features
 * Optimized for the Algerian real estate market with cultural and geographic considerations
 */

// Type definitions will be available after Prisma generation
type Contact = {
  id: string;
  email: string;
  name: string;
  phone?: string | null;
  type: 'BUYER' | 'TENANT' | 'INVESTOR';
  budgetMin?: number | null;
  budgetMax?: number | null;
  locationWilayas: string[];
  locationCities: string[];
  propertyTypes: ('APARTMENT' | 'VILLA' | 'HOUSE' | 'OFFICE' | 'SHOP' | 'WAREHOUSE' | 'LAND' | 'GARAGE')[];
  transactionType: 'RENT' | 'SALE';
  familySize?: number | null;
  hasChildren: boolean;
  minRooms?: number | null;
  maxRooms?: number | null;
  minArea?: number | null;
  maxArea?: number | null;
  furnishingType?: 'FURNISHED' | 'SEMI_FURNISHED' | 'UNFURNISHED' | null;
  preferredCondition?: 'POOR' | 'FAIR' | 'GOOD' | 'EXCELLENT' | 'NEW' | null;
  requiresParking: boolean;
  requiresSecurity: boolean;
  scores: number[];
  isActive: boolean;
  notes?: string | null;
  createdAt: Date;
  updatedAt: Date;
};

type Property = {
  id: string;
  title: string;
  description?: string | null;
  price: number;
  area: number;
  rooms: number;
  bathrooms?: number | null;
  wilaya: string;
  city: string;
  address?: string | null;
  latitude?: number | null;
  longitude?: number | null;
  propertyType: 'APARTMENT' | 'VILLA' | 'HOUSE' | 'OFFICE' | 'SHOP' | 'WAREHOUSE' | 'LAND' | 'GARAGE';
  transactionType: 'RENT' | 'SALE';
  furnishing: 'FURNISHED' | 'SEMI_FURNISHED' | 'UNFURNISHED';
  condition: 'POOR' | 'FAIR' | 'GOOD' | 'EXCELLENT' | 'NEW';
  hasParking: boolean;
  hasSecurity: boolean;
  hasElevator: boolean;
  hasGarden: boolean;
  hasBalcony: boolean;
  hasSwimmingPool: boolean;
  buildingAge?: number | null;
  floor?: number | null;
  totalFloors?: number | null;
  scores: number[];
  status: 'AVAILABLE' | 'RESERVED' | 'SOLD' | 'RENTED' | 'INACTIVE';
  ownerId?: string | null;
  viewCount: number;
  featured: boolean;
  createdAt: Date;
  updatedAt: Date;
};

type Sale = {
  id: string;
  contactId: string;
  propertyId: string;
  salePrice: number;
  saleDate: Date;
  successScore: number;
  timeToDecision?: number | null;
  viewCount?: number | null;
  notes?: string | null;
  createdAt: Date;
};

// Algeria-specific data mappings
export const ALGERIA_WILAYAS = {
  // Major cities (high scores)
  'Algiers': 0.95,
  'Alger': 0.95,
  'Oran': 0.92,
  'Constantine': 0.90,
  'Annaba': 0.85,
  'Batna': 0.75,
  'Djelfa': 0.70,
  'Sétif': 0.75,
  'Sidi Bel Abbès': 0.72,
  'El Oued': 0.60,
  'Skikda': 0.78,
  'Tiaret': 0.65,
  'Béjaïa': 0.80,
  'Tlemcen': 0.75,
  'Ouargla': 0.62,
  'Béchar': 0.58,
  'Mostaganem': 0.70,
  'Bordj Bou Arréridj': 0.68,
  'Chlef': 0.72,
  'Laghouat': 0.60,
  'Oum El Bouaghi': 0.62,
  'Bouira': 0.65,
  'Tamanrasset': 0.45,
  'Tébessa': 0.65,
  'Biskra': 0.68,
  'Guelma': 0.70,
  'Jijel': 0.75,
  'Médéa': 0.68,
  'Mascara': 0.67,
  'M\'Sila': 0.60,
  'Saïda': 0.62,
  'Souk Ahras': 0.63,
  'Tipaza': 0.88,
  'Mila': 0.65,
  'Aïn Defla': 0.65,
  'Naâma': 0.55,
  'Aïn Témouchent': 0.68,
  'Ghardaïa': 0.70,
  'Relizane': 0.63,
  'Boumerdès': 0.85,
  'El Tarf': 0.72,
  'Tindouf': 0.50,
  'Tissemsilt': 0.62,
  'El Bayadh': 0.58,
  'Khenchela': 0.60,
  'Illizi': 0.45
} as const;

export const PROPERTY_TYPE_SCORES = {
  APARTMENT: 0.3,
  VILLA: 0.8,
  HOUSE: 0.6,
  OFFICE: 0.4,
  SHOP: 0.2,
  WAREHOUSE: 0.1,
  LAND: 0.1,
  GARAGE: 0.05
} as const;

export const CONDITION_SCORES = {
  POOR: 0.1,
  FAIR: 0.3,
  GOOD: 0.7,
  EXCELLENT: 0.9,
  NEW: 1.0
} as const;

export const FURNISHING_SCORES = {
  UNFURNISHED: 0.0,
  SEMI_FURNISHED: 0.5,
  FURNISHED: 1.0
} as const;

// 12D Vector Dimensions
export const VECTOR_DIMENSIONS = {
  BUDGET: 0,      // Budget preference/price (0-1, normalized)
  AREA: 1,        // Area preference (0-1, normalized)
  ROOMS: 2,       // Room count preference (0-1, normalized)
  LOCATION: 3,    // Location desirability (0-1, based on wilaya)
  PROPERTY_TYPE: 4, // Property type preference (0-1)
  CONDITION: 5,   // Property condition preference (0-1)
  FEATURES: 6,    // Amenities/features score (0-1)
  FAMILY: 7,      // Family-friendliness (0-1)
  MODERN: 8,      // Modernity/newness preference (0-1)
  INVESTMENT: 9,  // Investment potential (0-1)
  URGENCY: 10,    // Urgency to buy/rent (0-1)
  TRANSACTION: 11 // Transaction type (RENT=0, SALE=1)
} as const;

/**
 * Generate 12D score vector for a contact based on their preferences
 */
export function generateScoresFromContact(contact: Partial<Contact>): number[] {
  const scores = new Array(12).fill(0.5); // Default neutral scores

  // Dimension 0: Budget (normalized based on contact's budget range)
  if (contact.budgetMin && contact.budgetMax) {
    const avgBudget = (contact.budgetMin + contact.budgetMax) / 2;
    // Normalize budget: 2M DZD = 0.1, 50M DZD = 1.0
    scores[VECTOR_DIMENSIONS.BUDGET] = Math.min(1.0, Math.max(0.1, (avgBudget - 2000000) / 48000000));
  } else if (contact.budgetMax) {
    scores[VECTOR_DIMENSIONS.BUDGET] = Math.min(1.0, Math.max(0.1, (contact.budgetMax - 2000000) / 48000000));
  }

  // Dimension 1: Area preference
  if (contact.minArea && contact.maxArea) {
    const avgArea = (contact.minArea + contact.maxArea) / 2;
    // Normalize area: 30m² = 0.1, 500m² = 1.0
    scores[VECTOR_DIMENSIONS.AREA] = Math.min(1.0, Math.max(0.1, (avgArea - 30) / 470));
  } else if (contact.maxArea) {
    scores[VECTOR_DIMENSIONS.AREA] = Math.min(1.0, Math.max(0.1, (contact.maxArea - 30) / 470));
  }

  // Dimension 2: Rooms preference
  if (contact.minRooms && contact.maxRooms) {
    const avgRooms = (contact.minRooms + contact.maxRooms) / 2;
    // Normalize rooms: 1 room = 0.1, 6+ rooms = 1.0
    scores[VECTOR_DIMENSIONS.ROOMS] = Math.min(1.0, Math.max(0.1, (avgRooms - 1) / 5));
  } else if (contact.maxRooms) {
    scores[VECTOR_DIMENSIONS.ROOMS] = Math.min(1.0, Math.max(0.1, (contact.maxRooms - 1) / 5));
  }

  // Dimension 3: Location preference (average of preferred wilayas)
  if (contact.locationWilayas && contact.locationWilayas.length > 0) {
    const wilayaScores = contact.locationWilayas.map((w: string) => ALGERIA_WILAYAS[w as keyof typeof ALGERIA_WILAYAS] || 0.3);
    scores[VECTOR_DIMENSIONS.LOCATION] = wilayaScores.reduce((sum: number, score: number) => sum + score, 0) / wilayaScores.length;
  }

  // Dimension 4: Property type preference
  if (contact.propertyTypes && contact.propertyTypes.length > 0) {
    const typeScores = contact.propertyTypes.map((t: string) => PROPERTY_TYPE_SCORES[t as keyof typeof PROPERTY_TYPE_SCORES]);
    scores[VECTOR_DIMENSIONS.PROPERTY_TYPE] = typeScores.reduce((sum: number, score: number) => sum + score, 0) / typeScores.length;
  }

  // Dimension 5: Condition preference
  if (contact.preferredCondition) {
    scores[VECTOR_DIMENSIONS.CONDITION] = CONDITION_SCORES[contact.preferredCondition as keyof typeof CONDITION_SCORES];
  }

  // Dimension 6: Features/amenities preference
  let featuresScore = 0.5;
  if (contact.requiresParking) featuresScore += 0.2;
  if (contact.requiresSecurity) featuresScore += 0.3;
  scores[VECTOR_DIMENSIONS.FEATURES] = Math.min(1.0, featuresScore);

  // Dimension 7: Family-friendliness
  if (contact.hasChildren || (contact.familySize && contact.familySize > 2)) {
    scores[VECTOR_DIMENSIONS.FAMILY] = 0.9; // High family preference
  } else if (contact.familySize === 1) {
    scores[VECTOR_DIMENSIONS.FAMILY] = 0.2; // Low family preference
  }

  // Dimension 8: Modernity preference (based on condition and features)
  if (contact.preferredCondition === 'NEW' || contact.preferredCondition === 'EXCELLENT') {
    scores[VECTOR_DIMENSIONS.MODERN] = 0.8;
  } else if (contact.preferredCondition === 'POOR' || contact.preferredCondition === 'FAIR') {
    scores[VECTOR_DIMENSIONS.MODERN] = 0.2;
  }

  // Dimension 9: Investment potential (based on contact type and budget)
  if (contact.type === 'INVESTOR') {
    scores[VECTOR_DIMENSIONS.INVESTMENT] = 0.9;
  } else if (contact.type === 'BUYER' && scores[VECTOR_DIMENSIONS.BUDGET] > 0.7) {
    scores[VECTOR_DIMENSIONS.INVESTMENT] = 0.6;
  } else {
    scores[VECTOR_DIMENSIONS.INVESTMENT] = 0.3;
  }

  // Dimension 10: Urgency (based on contact type)
  if (contact.type === 'TENANT') {
    scores[VECTOR_DIMENSIONS.URGENCY] = 0.7; // Tenants usually have higher urgency
  } else if (contact.type === 'BUYER') {
    scores[VECTOR_DIMENSIONS.URGENCY] = 0.5;
  } else {
    scores[VECTOR_DIMENSIONS.URGENCY] = 0.3;
  }

  // Dimension 11: Transaction type
  scores[VECTOR_DIMENSIONS.TRANSACTION] = contact.transactionType === 'SALE' ? 1.0 : 0.0;

  return scores;
}

/**
 * Generate 12D score vector for a property based on its characteristics
 */
export function generateScoresFromProperty(property: Partial<Property>): number[] {
  const scores = new Array(12).fill(0.5); // Default neutral scores

  // Dimension 0: Budget/Price
  if (property.price) {
    // Normalize price: 2M DZD = 0.1, 50M DZD = 1.0
    scores[VECTOR_DIMENSIONS.BUDGET] = Math.min(1.0, Math.max(0.1, (property.price - 2000000) / 48000000));
  }

  // Dimension 1: Area
  if (property.area) {
    // Normalize area: 30m² = 0.1, 500m² = 1.0
    scores[VECTOR_DIMENSIONS.AREA] = Math.min(1.0, Math.max(0.1, (property.area - 30) / 470));
  }

  // Dimension 2: Rooms
  if (property.rooms) {
    // Normalize rooms: 1 room = 0.1, 6+ rooms = 1.0
    scores[VECTOR_DIMENSIONS.ROOMS] = Math.min(1.0, Math.max(0.1, (property.rooms - 1) / 5));
  }

  // Dimension 3: Location (wilaya desirability)
  if (property.wilaya) {
    scores[VECTOR_DIMENSIONS.LOCATION] = ALGERIA_WILAYAS[property.wilaya as keyof typeof ALGERIA_WILAYAS] || 0.3;
  }

  // Dimension 4: Property type
  if (property.propertyType) {
    scores[VECTOR_DIMENSIONS.PROPERTY_TYPE] = PROPERTY_TYPE_SCORES[property.propertyType as keyof typeof PROPERTY_TYPE_SCORES];
  }

  // Dimension 5: Condition
  if (property.condition) {
    scores[VECTOR_DIMENSIONS.CONDITION] = CONDITION_SCORES[property.condition as keyof typeof CONDITION_SCORES];
  }

  // Dimension 6: Features/amenities
  let featuresScore = 0.0;
  if (property.hasParking) featuresScore += 0.15;
  if (property.hasSecurity) featuresScore += 0.2;
  if (property.hasElevator) featuresScore += 0.1;
  if (property.hasGarden) featuresScore += 0.15;
  if (property.hasBalcony) featuresScore += 0.1;
  if (property.hasSwimmingPool) featuresScore += 0.3;
  scores[VECTOR_DIMENSIONS.FEATURES] = Math.min(1.0, featuresScore);

  // Dimension 7: Family-friendliness
  let familyScore = 0.5;
  if (property.rooms && property.rooms >= 3) familyScore += 0.2;
  if (property.hasGarden) familyScore += 0.2;
  if (property.hasSecurity) familyScore += 0.1;
  if (property.propertyType === 'VILLA' || property.propertyType === 'HOUSE') familyScore += 0.2;
  scores[VECTOR_DIMENSIONS.FAMILY] = Math.min(1.0, familyScore);

  // Dimension 8: Modernity
  let modernScore = 0.5;
  if (property.condition === 'NEW') modernScore = 1.0;
  else if (property.condition === 'EXCELLENT') modernScore = 0.8;
  else if (property.condition === 'GOOD') modernScore = 0.6;
  if (property.hasElevator) modernScore += 0.1;
  if (property.hasSecurity) modernScore += 0.1;
  scores[VECTOR_DIMENSIONS.MODERN] = Math.min(1.0, modernScore);

  // Dimension 9: Investment potential
  let investmentScore = 0.5;
  // Location factor
  if (scores[VECTOR_DIMENSIONS.LOCATION] > 0.8) investmentScore += 0.2;
  // Property type factor
  if (property.propertyType === 'APARTMENT' || property.propertyType === 'OFFICE') investmentScore += 0.1;
  if (property.propertyType === 'VILLA') investmentScore += 0.2;
  // Condition factor
  if (property.condition === 'NEW' || property.condition === 'EXCELLENT') investmentScore += 0.2;
  scores[VECTOR_DIMENSIONS.INVESTMENT] = Math.min(1.0, investmentScore);

  // Dimension 10: Urgency (property's marketability)
  let urgencyScore = 0.5;
  if (property.status === 'AVAILABLE') urgencyScore += 0.2;
  if (property.featured) urgencyScore += 0.2;
  if (scores[VECTOR_DIMENSIONS.BUDGET] < 0.5) urgencyScore += 0.1; // Lower priced properties move faster
  scores[VECTOR_DIMENSIONS.URGENCY] = Math.min(1.0, urgencyScore);

  // Dimension 11: Transaction type
  scores[VECTOR_DIMENSIONS.TRANSACTION] = property.transactionType === 'SALE' ? 1.0 : 0.0;

  return scores;
}

/**
 * Calculate cosine similarity between two vectors
 */
export function calculateSimilarity(vector1: number[], vector2: number[]): number {
  if (vector1.length !== vector2.length || vector1.length !== 12) {
    throw new Error('Vectors must be 12-dimensional');
  }

  const dotProduct = vector1.reduce((sum, v1, i) => sum + v1 * vector2[i], 0);
  const magnitude1 = Math.sqrt(vector1.reduce((sum, v) => sum + v * v, 0));
  const magnitude2 = Math.sqrt(vector2.reduce((sum, v) => sum + v * v, 0));

  if (magnitude1 === 0 || magnitude2 === 0) return 0;
  
  return dotProduct / (magnitude1 * magnitude2);
}

/**
 * Learn from successful sales to improve contact preferences
 */
export function learnFromSale(
  contact: Contact,
  property: Property,
  sale: Pick<Sale, 'successScore' | 'salePrice'>
): number[] {
  const currentScores = [...contact.scores];
  const propertyScores = property.scores;
  const learningRate = 0.1; // Configurable learning rate
  const successWeight = sale.successScore; // 0-1 scale

  // Update contact preferences based on the successful match
  for (let i = 0; i < 12; i++) {
    const difference = propertyScores[i] - currentScores[i];
    const adjustment = learningRate * successWeight * difference;
    currentScores[i] = Math.max(0, Math.min(1, currentScores[i] + adjustment));
  }

  return currentScores;
}

/**
 * Validate that a score vector is properly formatted
 */
export function validateScoreVector(scores: number[]): boolean {
  if (!Array.isArray(scores) || scores.length !== 12) {
    return false;
  }
  
  return scores.every(score => 
    typeof score === 'number' && 
    score >= 0 && 
    score <= 1 && 
    !isNaN(score)
  );
}

/**
 * Normalize a score vector to ensure all values are between 0 and 1
 */
export function normalizeScoreVector(scores: number[]): number[] {
  return scores.map(score => Math.max(0, Math.min(1, score)));
}

/**
 * Get default score vector for new contacts/properties
 */
export function getDefaultScoreVector(): number[] {
  return [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5];
}

/**
 * Get score vector explanation for debugging
 */
export function explainScoreVector(scores: number[]): Record<string, { value: number; meaning: string }> {
  const dimensions = [
    'Budget', 'Area', 'Rooms', 'Location', 'Property Type',
    'Condition', 'Features', 'Family', 'Modern', 'Investment', 'Urgency', 'Transaction'
  ];
  
  const explanation: Record<string, { value: number; meaning: string }> = {};
  
  scores.forEach((score, index) => {
    const dim = dimensions[index];
    let meaning = '';
    
    if (score < 0.3) meaning = 'Low preference/value';
    else if (score < 0.7) meaning = 'Moderate preference/value';
    else meaning = 'High preference/value';
    
    explanation[dim] = { value: score, meaning };
  });
  
  return explanation;
} 