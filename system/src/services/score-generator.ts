/**
 * Smart Contact Score Generation Service
 * 
 * Generates 12-dimensional vectors for contact preferences and property features
 * Optimized for the Algerian real estate market with cultural and geographic considerations
 * Enhanced with dual transaction type support
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
  transactionTypes?: ('RENT' | 'SALE')[];
  primaryTransactionType?: 'RENT' | 'SALE';
  transactionFlexibility?: number;
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
  transactionScores?: number[];
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
 * Generate transaction scores for dual transaction type support
 * Returns [rentScore, saleScore] where each score is 0-1
 */
export function generateTransactionScores(contact: Partial<Contact>): number[] {
  const rentScore = 0.0;
  const saleScore = 0.0;
  
  // If using legacy single transaction type
  if (contact.transactionType && !contact.transactionTypes?.length) {
    if (contact.transactionType === 'RENT') {
      return [1.0, 0.0];
    } else {
      return [0.0, 1.0];
    }
  }
  
  // Enhanced dual transaction type logic
  if (contact.transactionTypes?.length) {
    const hasRent = contact.transactionTypes.includes('RENT');
    const hasSale = contact.transactionTypes.includes('SALE');
    
    if (hasRent && hasSale) {
      // Interested in both - use primary preference and flexibility
      const primary = contact.primaryTransactionType || contact.transactionTypes[0];
      const flexibility = contact.transactionFlexibility || 0.5;
      
      if (primary === 'RENT') {
        return [1.0, flexibility];
      } else {
        return [flexibility, 1.0];
      }
    } else if (hasRent) {
      return [1.0, 0.0];
    } else if (hasSale) {
      return [0.0, 1.0];
    }
  }
  
  // Fallback to legacy behavior
  if (contact.transactionType === 'RENT') {
    return [1.0, 0.0];
  } else if (contact.transactionType === 'SALE') {
    return [0.0, 1.0];
  }
  
  return [0.5, 0.5]; // Default neutral scores
}

/**
 * Generate 12D score vector for a contact based on their preferences
 */
export function generateScoresFromContact(contact: Partial<Contact>): number[] {
  const scores = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5];

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

  // Dimension 11: Transaction type (enhanced for dual support)
  const transactionScores = generateTransactionScores(contact);
  const primaryTransaction = contact.primaryTransactionType || contact.transactionType;
  scores[VECTOR_DIMENSIONS.TRANSACTION] = primaryTransaction === 'SALE' ? 1.0 : 0.0;

  return scores;
}

/**
 * Generate both main scores and transaction scores
 */
export function generateAllScoresFromContact(contact: Partial<Contact>): {
  scores: number[];
  transactionScores: number[];
} {
  return {
    scores: generateScoresFromContact(contact),
    transactionScores: generateTransactionScores(contact)
  };
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
 * Advanced collaborative learning from sale
 * Learns based on user similarity and decision patterns
 */
export function collaborativeLearningFromSale(
  currentUser: { scores: number[] },
  buyerUser: { scores: number[] },
  property: { scores: number[] },
  sale: { 
    successScore: number; 
    timeToDecision?: number; 
    salePrice: number; 
    viewCount?: number 
  },
  userSimilarity: number,
  options: {
    baseLearningRate?: number;
    similarityThreshold?: number;
    enableTimeWeighting?: boolean;
    enableSuccessWeighting?: boolean;
  } = {}
): number[] {
  const {
    baseLearningRate = 0.1,
    similarityThreshold = 0.8,
    enableTimeWeighting = true,
    enableSuccessWeighting = true
  } = options;

  // Only learn if similarity is above threshold
  if (userSimilarity < similarityThreshold) {
    return [...currentUser.scores];
  }

  const updatedScores = [...currentUser.scores];
  const buyerScores = buyerUser.scores;
  const propertyScores = property.scores;
  
  // Calculate dynamic learning rate based on multiple factors
  let learningRate = baseLearningRate;
  
  // Adjust learning rate based on user similarity (higher similarity = more learning)
  learningRate *= userSimilarity;
  
  // Adjust learning rate based on success score
  if (enableSuccessWeighting) {
    if (sale.successScore >= 0.8) {
      learningRate *= 1.5; // Learn more from very successful sales
    } else if (sale.successScore <= 0.4) {
      learningRate *= 0.5; // Learn less from poor matches
    }
  }
  
  // Adjust learning rate based on decision speed (faster = stronger preference signal)
  if (enableTimeWeighting && sale.timeToDecision) {
    if (sale.timeToDecision < 7) {
      learningRate *= 1.3; // Very quick decisions show strong preference
    } else if (sale.timeToDecision < 14) {
      learningRate *= 1.1; // Quick decisions show preference  
    } else if (sale.timeToDecision > 60) {
      learningRate *= 0.7; // Slow decisions show uncertainty
    }
  }
  
  // Cap learning rate to prevent overfitting
  learningRate = Math.min(0.3, learningRate);
  
  // Update each dimension of the preference vector
  for (let i = 0; i < updatedScores.length; i++) {
    const currentPreference = updatedScores[i];
    const buyerPreference = buyerScores[i];
    const propertyFeature = propertyScores[i];
    
    // Calculate target preference based on buyer's preference and property features
    let targetPreference: number;
    
    if (sale.successScore >= 0.6) {
      // Successful sale: blend buyer preference and property features
      const buyerWeight = 0.7; // Trust buyer's preferences more
      const propertyWeight = 0.3; // But also consider what they actually bought
      targetPreference = buyerPreference * buyerWeight + propertyFeature * propertyWeight;
    } else {
      // Unsuccessful sale: slightly avoid both buyer preference and property features
      const avoidanceStrength = (1 - sale.successScore) * 0.3; // Max 30% avoidance
      targetPreference = currentPreference - 
        (buyerPreference - currentPreference) * avoidanceStrength * 0.5 -
        (propertyFeature - currentPreference) * avoidanceStrength * 0.5;
    }
    
    // Apply learning with calculated rate
    updatedScores[i] = currentPreference + (targetPreference - currentPreference) * learningRate;
    
    // Ensure scores stay within bounds [0, 1]
    updatedScores[i] = Math.max(0, Math.min(1, updatedScores[i]));
  }
  
  // Apply smoothing to prevent overfitting
  const smoothingFactor = 0.02;
  for (let i = 0; i < updatedScores.length; i++) {
    updatedScores[i] = updatedScores[i] * (1 - smoothingFactor) + 0.5 * smoothingFactor;
  }
  
  return updatedScores;
}

/**
 * Property learning from successful client interactions
 * Updates property feature representation based on successful matches
 */
export function propertyLearningFromSale(
  currentProperty: { scores: number[] },
  targetProperty: { scores: number[] },
  client: { scores: number[] },
  sale: { 
    successScore: number; 
    timeToDecision?: number; 
    salePrice: number;
    viewCount?: number 
  },
  propertySimilarity: number,
  options: {
    baseLearningRate?: number;
    similarityThreshold?: number;
    enablePriceWeighting?: boolean;
  } = {}
): number[] {
  const {
    baseLearningRate = 0.05, // Lower learning rate for properties
    similarityThreshold = 0.8,
    enablePriceWeighting = true
  } = options;

  // Only learn if similarity is above threshold
  if (propertySimilarity < similarityThreshold) {
    return [...currentProperty.scores];
  }

  const updatedScores = [...currentProperty.scores];
  const targetScores = targetProperty.scores;
  const clientScores = client.scores;
  
  // Calculate dynamic learning rate
  let learningRate = baseLearningRate;
  
  // Adjust based on property similarity
  learningRate *= propertySimilarity;
  
  // Adjust based on success score
  if (sale.successScore >= 0.8) {
    learningRate *= 1.3;
  } else if (sale.successScore <= 0.5) {
    learningRate *= 0.6;
  }
  
  // Consider price similarity for property learning
  if (enablePriceWeighting && currentProperty.hasOwnProperty('price') && targetProperty.hasOwnProperty('price')) {
    const currentPrice = (currentProperty as any).price;
    const targetPrice = (targetProperty as any).price;
    const priceRatio = Math.min(currentPrice, targetPrice) / Math.max(currentPrice, targetPrice);
    learningRate *= (0.5 + priceRatio * 0.5); // Weight by price similarity
  }
  
  // Cap learning rate
  learningRate = Math.min(0.2, learningRate);
  
  // Update property features
  for (let i = 0; i < updatedScores.length; i++) {
    const currentFeature = updatedScores[i];
    const targetFeature = targetScores[i];
    const clientPreference = clientScores[i];
    
    // Target should blend with successful property features and client preferences
    if (sale.successScore >= 0.6) {
      const targetWeight = 0.6; // What successful property had
      const clientWeight = 0.4; // What client preferred
      const adjustedTarget = targetFeature * targetWeight + clientPreference * clientWeight;
      
      updatedScores[i] = currentFeature + (adjustedTarget - currentFeature) * learningRate;
    } else {
      // For unsuccessful sales, slightly avoid the pattern
      const avoidanceStrength = (1 - sale.successScore) * 0.2;
      updatedScores[i] = currentFeature - (targetFeature - currentFeature) * learningRate * avoidanceStrength;
    }
    
    // Ensure bounds
    updatedScores[i] = Math.max(0, Math.min(1, updatedScores[i]));
  }
  
  // Minimal smoothing for properties
  const smoothingFactor = 0.01;
  for (let i = 0; i < updatedScores.length; i++) {
    updatedScores[i] = updatedScores[i] * (1 - smoothingFactor) + 0.5 * smoothingFactor;
  }
  
  return updatedScores;
}

/**
 * Calculate combined score for sale analysis
 * Combines user preferences and property features to predict match quality
 */
export function calculateCombinedScore(
  userScores: number[],
  propertyScores: number[],
  weights: {
    similarityWeight?: number;
    priceCompatibilityWeight?: number;
    transactionTypeWeight?: number;
  } = {}
): number {
  const {
    similarityWeight = 0.7,
    priceCompatibilityWeight = 0.2,
    transactionTypeWeight = 0.1
  } = weights;

  // Base similarity score
  const similarity = calculateSimilarity(userScores, propertyScores);
  
  // Combined score is primarily similarity-based
  // Additional weights can be applied based on business logic
  return similarity * similarityWeight + 
         0.8 * priceCompatibilityWeight + // Assume price is compatible for now
         0.9 * transactionTypeWeight; // Assume transaction type matches
}

/**
 * Batch learning function for processing multiple sales
 */
export function batchCollaborativeLearning(
  users: Array<{ id: string; scores: number[] }>,
  properties: Array<{ id: string; scores: number[] }>,
  sales: Array<{
    contactId: string;
    propertyId: string;
    successScore: number;
    timeToDecision?: number;
    salePrice: number;
    viewCount?: number;
  }>,
  options: {
    userSimilarityThreshold?: number;
    propertySimilarityThreshold?: number;
    baseLearningRate?: number;
  } = {}
): {
  updatedUsers: Array<{ id: string; scores: number[] }>;
  updatedProperties: Array<{ id: string; scores: number[] }>;
  learningStats: {
    usersAffected: number;
    propertiesAffected: number;
    totalLearningOperations: number;
  };
} {
  const {
    userSimilarityThreshold = 0.8,
    propertySimilarityThreshold = 0.8,
    baseLearningRate = 0.1
  } = options;

  const updatedUsers = users.map(user => ({ ...user, scores: [...user.scores] }));
  const updatedProperties = properties.map(prop => ({ ...prop, scores: [...prop.scores] }));
  
  let usersAffected = 0;
  let propertiesAffected = 0;
  let totalLearningOperations = 0;

  // Process each sale for collaborative learning
  for (const sale of sales) {
    const buyer = users.find(u => u.id === sale.contactId);
    const soldProperty = properties.find(p => p.id === sale.propertyId);
    
    if (!buyer || !soldProperty) continue;

    // Update similar users
    for (let i = 0; i < updatedUsers.length; i++) {
      if (updatedUsers[i].id === sale.contactId) continue; // Skip the buyer
      
      const similarity = calculateSimilarity(updatedUsers[i].scores, buyer.scores);
      
      if (similarity >= userSimilarityThreshold) {
        const newScores = collaborativeLearningFromSale(
          updatedUsers[i],
          buyer,
          soldProperty,
          sale,
          similarity,
          { baseLearningRate, similarityThreshold: userSimilarityThreshold }
        );
        
        // Check if scores actually changed
        const changed = newScores.some((score, idx) => 
          Math.abs(score - updatedUsers[i].scores[idx]) > 0.001
        );
        
        if (changed) {
          updatedUsers[i].scores = newScores;
          usersAffected++;
          totalLearningOperations++;
        }
      }
    }

    // Update similar properties
    for (let i = 0; i < updatedProperties.length; i++) {
      if (updatedProperties[i].id === sale.propertyId) continue; // Skip the sold property
      
      const similarity = calculateSimilarity(updatedProperties[i].scores, soldProperty.scores);
      
      if (similarity >= propertySimilarityThreshold) {
        const newScores = propertyLearningFromSale(
          updatedProperties[i],
          soldProperty,
          buyer,
          sale,
          similarity,
          { baseLearningRate: baseLearningRate * 0.5, similarityThreshold: propertySimilarityThreshold }
        );
        
        // Check if scores actually changed
        const changed = newScores.some((score, idx) => 
          Math.abs(score - updatedProperties[i].scores[idx]) > 0.001
        );
        
        if (changed) {
          updatedProperties[i].scores = newScores;
          propertiesAffected++;
          totalLearningOperations++;
        }
      }
    }
  }

  return {
    updatedUsers,
    updatedProperties,
    learningStats: {
      usersAffected,
      propertiesAffected,
      totalLearningOperations
    }
  };
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