import { UserType, PropertyType, FurnishingType, ConditionType, TransactionType } from '../../generated/prisma';
import settingsService from './settings';

/**
 * Algeria-Optimized Vector Generation Service
 * Handles intelligent defaults for missing user preferences
 */

// Algeria-specific constants
const ALGERIAN_WILAYAS = {
  'Adrar': 0.02, 'Chlef': 0.04, 'Laghouat': 0.06, 'Oum El Bouaghi': 0.08,
  'Batna': 0.10, 'Béjaïa': 0.12, 'Biskra': 0.14, 'Béchar': 0.16,
  'Blida': 0.18, 'Bouira': 0.20, 'Tamanrasset': 0.22, 'Tébessa': 0.24,
  'Tlemcen': 0.26, 'Tiaret': 0.28, 'Tizi Ouzou': 0.30, 'Algiers': 0.95, // Capital gets high score
  'Djelfa': 0.32, 'Jijel': 0.34, 'Sétif': 0.36, 'Saïda': 0.38,
  'Skikda': 0.40, 'Sidi Bel Abbès': 0.42, 'Annaba': 0.85, // Major city
  'Guelma': 0.44, 'Constantine': 0.90, // Major city
  'Médéa': 0.46, 'Mostaganem': 0.48, 'MSila': 0.50, 'Mascara': 0.52,
  'Ouargla': 0.54, 'Oran': 0.92, // Major city
  'El Bayadh': 0.56, 'Illizi': 0.58, 'Bordj Bou Arréridj': 0.60,
  'Boumerdès': 0.75, // Near Algiers
  'El Tarf': 0.62, 'Tindouf': 0.64, 'Tissemsilt': 0.66, 'El Oued': 0.68,
  'Khenchela': 0.70, 'Souk Ahras': 0.72, 'Tipaza': 0.80, // Near Algiers
  'Mila': 0.74, 'Aïn Defla': 0.76, 'Naâma': 0.78, 'Aïn Témouchent': 0.82,
  'Ghardaïa': 0.84, 'Relizane': 0.86
};

const ALGERIA_PRICE_RANGES = {
  rural: { min: 2000000, max: 8000000 },     // 2M - 8M DZD
  suburban: { min: 5000000, max: 15000000 }, // 5M - 15M DZD  
  urban: { min: 8000000, max: 25000000 },    // 8M - 25M DZD
  premium: { min: 15000000, max: 50000000 }  // 15M - 50M DZD
};

interface UserPreferences {
  userType: UserType;
  budget?: number;
  preferredLocation?: string;
  roomsNeeded?: number;
  familySize?: number;
  hasChildren?: boolean;
  workLocation?: string;
  transportNeeded?: boolean;
  isFirstTimeBuyer?: boolean;
}

interface PropertyFeatures {
  price: number;
  area: number;
  rooms: number;
  location: string;
  propertyType: PropertyType;
  furnishing: FurnishingType;
  condition: ConditionType;
  transactionType: TransactionType;
  hasParking?: boolean;
  hasSecurity?: boolean;
  hasElevator?: boolean;
  nearMosque?: boolean;
  nearSchool?: boolean;
  nearTransport?: boolean;
}

class AlgerianVectorGenerator {
  
  /**
   * Generate intelligent user preference vector with smart defaults
   */
  async generateUserVector(preferences: UserPreferences): Promise<number[]> {
    const settings = await settingsService.getByCategory('algorithm');
    
    // Smart defaults based on user type and provided preferences
    const vector = [
      this.generatePricePreference(preferences),
      this.generateAreaPreference(preferences),
      this.generateRoomsPreference(preferences),
      this.generateLocationPreference(preferences),
      this.generatePropertyTypePreference(preferences),
      this.generateFurnishingPreference(preferences),
      this.generateConditionPreference(preferences),
      this.generateTransactionTypePreference(preferences),
      this.generateAmenitiesPreference(preferences),
      this.generateNeighborhoodPreference(preferences),
      this.generateAccessibilityPreference(preferences),
      this.generateFamilyFriendlyPreference(preferences)
    ];
    
    return vector;
  }
  
  /**
   * Generate property vector based on actual features
   */
  generatePropertyVector(features: PropertyFeatures): number[] {
    const vector = [
      this.normalizePrice(features.price),
      this.normalizeArea(features.area),
      this.normalizeRooms(features.rooms),
      this.encodeWilaya(features.location),
      this.encodePropertyType(features.propertyType),
      this.encodeFurnishing(features.furnishing),
      this.encodeCondition(features.condition),
      this.encodeTransactionType(features.transactionType),
      this.encodeAmenities(features),
      this.encodeNeighborhood(features),
      this.encodeAccessibility(features),
      this.encodeFamilyFriendly(features)
    ];
    
    return vector;
  }
  
  // Price preference based on user type and budget
  private generatePricePreference(preferences: UserPreferences): number {
    if (preferences.budget) {
      // Normalize based on provided budget
      const maxBudget = preferences.userType === UserType.TENANT ? 50000 : 50000000; // Monthly rent vs purchase
      return Math.min(preferences.budget / maxBudget, 1.0);
    }
    
    // Smart defaults based on user type
    switch (preferences.userType) {
      case UserType.TENANT:
        return preferences.isFirstTimeBuyer ? 0.3 : 0.5; // Lower budget for first-time
      case UserType.BUYER:
        return preferences.isFirstTimeBuyer ? 0.4 : 0.7; // Moderate to high budget
      case UserType.AGENT:
        return 0.6; // Agents typically know market ranges
      default:
        return 0.5; // Safe middle ground
    }
  }
  
  // Area preference based on family size
  private generateAreaPreference(preferences: UserPreferences): number {
    if (preferences.familySize) {
      // Algerian family standard: 20m² per person minimum
      const neededArea = preferences.familySize * 25; // 25m² per person for comfort
      return Math.min(neededArea / 200, 1.0); // Normalize to 200m² max
    }
    
    // Defaults based on user type
    switch (preferences.userType) {
      case UserType.TENANT:
        return preferences.hasChildren ? 0.7 : 0.4; // Families need more space
      case UserType.BUYER:
        return preferences.hasChildren ? 0.8 : 0.6; // Buyers generally want more space
      default:
        return 0.5;
    }
  }
  
  // Rooms preference based on family needs
  private generateRoomsPreference(preferences: UserPreferences): number {
    if (preferences.roomsNeeded) {
      return Math.min(preferences.roomsNeeded / 6, 1.0); // Max 6 rooms
    }
    
    if (preferences.familySize) {
      // Algerian standard: Parents room + children rooms + guest room
      const rooms = Math.max(2, Math.ceil(preferences.familySize / 2) + 1);
      return Math.min(rooms / 6, 1.0);
    }
    
    // Defaults
    return preferences.hasChildren ? 0.7 : 0.4;
  }
  
  // Location preference with Algerian wilaya encoding
  private generateLocationPreference(preferences: UserPreferences): number {
    if (preferences.preferredLocation) {
      return this.encodeWilaya(preferences.preferredLocation);
    }
    
    // Default to major cities for better opportunities
    const majorCities = ['Algiers', 'Oran', 'Constantine', 'Annaba'];
    const randomMajorCity = majorCities[Math.floor(Math.random() * majorCities.length)];
    return this.encodeWilaya(randomMajorCity);
  }
  
  // Property type preference based on Algerian market
  private generatePropertyTypePreference(preferences: UserPreferences): number {
    switch (preferences.userType) {
      case UserType.TENANT:
        return 0.2; // Apartments are common for rent
      case UserType.BUYER:
        return preferences.hasChildren ? 0.8 : 0.4; // Families prefer villas
      default:
        return 0.5;
    }
  }
  
  // Furnishing preference 
  private generateFurnishingPreference(preferences: UserPreferences): number {
    switch (preferences.userType) {
      case UserType.TENANT:
        return preferences.isFirstTimeBuyer ? 1.0 : 0.5; // First-time prefer furnished
      case UserType.BUYER:
        return 0.2; // Buyers usually prefer unfurnished
      default:
        return 0.5;
    }
  }
  
  // Condition preference
  private generateConditionPreference(preferences: UserPreferences): number {
    return preferences.isFirstTimeBuyer ? 1.0 : 0.8; // Everyone prefers good condition
  }
  
  // Transaction type preference
  private generateTransactionTypePreference(preferences: UserPreferences): number {
    switch (preferences.userType) {
      case UserType.TENANT:
        return 0.0; // Rent
      case UserType.BUYER:
        return 1.0; // Sale
      default:
        return 0.5;
    }
  }
  
  // Amenities preference (parking, security, elevator)
  private generateAmenitiesPreference(preferences: UserPreferences): number {
    let score = 0.3; // Base amenities preference
    
    if (preferences.hasChildren) score += 0.3; // Security important for families
    if (preferences.familySize && preferences.familySize > 4) score += 0.2; // Large families need parking
    
    return Math.min(score, 1.0);
  }
  
  // Neighborhood preference
  private generateNeighborhoodPreference(preferences: UserPreferences): number {
    return preferences.hasChildren ? 0.8 : 0.6; // Families prefer residential areas
  }
  
  // Accessibility preference (transport, mosque, market)
  private generateAccessibilityPreference(preferences: UserPreferences): number {
    let score = 0.5; // Base accessibility need
    
    if (preferences.transportNeeded) score += 0.3;
    if (preferences.workLocation) score += 0.2; // Need transport to work
    
    return Math.min(score, 1.0);
  }
  
  // Family-friendly preference
  private generateFamilyFriendlyPreference(preferences: UserPreferences): number {
    if (preferences.hasChildren) return 1.0;
    if (preferences.familySize && preferences.familySize > 2) return 0.8;
    return 0.3;
  }
  
  // Property vector generation methods
  private normalizePrice(price: number): number {
    // Updated for realistic Algerian prices (2M - 50M DZD)
    return Math.min(Math.max((price - 2000000) / (50000000 - 2000000), 0), 1);
  }
  
  private normalizeArea(area: number): number {
    // Algerian standard: 30-500m²
    return Math.min(Math.max((area - 30) / (500 - 30), 0), 1);
  }
  
  private normalizeRooms(rooms: number): number {
    return Math.min(rooms / 6, 1);
  }
  
  private encodeWilaya(location: string): number {
    // Find closest match for wilaya
    for (const [wilaya, score] of Object.entries(ALGERIAN_WILAYAS)) {
      if (location.toLowerCase().includes(wilaya.toLowerCase())) {
        return score;
      }
    }
    // Default to moderate score for unknown locations
    return 0.5;
  }
  
  private encodePropertyType(type: PropertyType): number {
    switch (type) {
      case PropertyType.APARTMENT: return 0.2;
      case PropertyType.VILLA: return 0.8;
      case PropertyType.OFFICE: return 0.5;
      case PropertyType.LAND: return 0.1;
      default: return 0.5;
    }
  }
  
  private encodeFurnishing(furnishing: FurnishingType): number {
    switch (furnishing) {
      case FurnishingType.UNFURNISHED: return 0.0;
      case FurnishingType.SEMI_FURNISHED: return 0.5;
      case FurnishingType.FURNISHED: return 1.0;
      default: return 0.5;
    }
  }
  
  private encodeCondition(condition: ConditionType): number {
    switch (condition) {
      case ConditionType.POOR: return 0.0;
      case ConditionType.FAIR: return 0.3;
      case ConditionType.GOOD: return 0.7;
      case ConditionType.EXCELLENT: return 1.0;
      default: return 0.7;
    }
  }
  
  private encodeTransactionType(type: TransactionType): number {
    return type === TransactionType.SALE ? 1.0 : 0.0;
  }
  
  private encodeAmenities(features: PropertyFeatures): number {
    let score = 0;
    if (features.hasParking) score += 0.4;
    if (features.hasSecurity) score += 0.4;
    if (features.hasElevator) score += 0.2;
    return Math.min(score, 1.0);
  }
  
  private encodeNeighborhood(features: PropertyFeatures): number {
    // Based on property type and location
    if (features.propertyType === PropertyType.VILLA) return 0.8;
    if (features.propertyType === PropertyType.APARTMENT) return 0.6;
    return 0.4;
  }
  
  private encodeAccessibility(features: PropertyFeatures): number {
    let score = 0.3; // Base accessibility
    if (features.nearTransport) score += 0.3;
    if (features.nearMosque) score += 0.2;
    return Math.min(score, 1.0);
  }
  
  private encodeFamilyFriendly(features: PropertyFeatures): number {
    let score = 0.2; // Base score
    if (features.nearSchool) score += 0.4;
    if (features.hasParking) score += 0.2;
    if (features.hasSecurity) score += 0.2;
    return Math.min(score, 1.0);
  }
}

export default new AlgerianVectorGenerator(); 