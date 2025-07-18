/**
 * Geospatial Service for Algeria Real Estate System
 * 
 * Handles geohash generation, distance calculations, and radius-based search
 * Optimized for Algerian geography and urban areas
 */

// Base32 alphabet for geohash
const BASE32 = '0123456789bcdefghjkmnpqrstuvwxyz';

/**
 * Generate geohash from latitude and longitude
 */
export function generateGeohash(latitude: number, longitude: number, precision: number = 8): string {
  let lat = latitude;
  let lon = longitude;
  
  let geohash = '';
  let bits = 0;
  let bit = 0;
  let ch = 0;
  
  let latRange = [-90.0, 90.0];
  let lonRange = [-180.0, 180.0];
  
  let isEven = true;
  
  while (geohash.length < precision) {
    if (isEven) {
      // longitude
      const mid = (lonRange[0] + lonRange[1]) / 2;
      if (lon >= mid) {
        ch |= (1 << (4 - bits));
        lonRange[0] = mid;
      } else {
        lonRange[1] = mid;
      }
    } else {
      // latitude
      const mid = (latRange[0] + latRange[1]) / 2;
      if (lat >= mid) {
        ch |= (1 << (4 - bits));
        latRange[0] = mid;
      } else {
        latRange[1] = mid;
      }
    }
    
    isEven = !isEven;
    
    if (bits < 4) {
      bits++;
    } else {
      geohash += BASE32[ch];
      bits = 0;
      ch = 0;
    }
  }
  
  return geohash;
}

/**
 * Generate multiple precision geohashes for a location
 */
export function generateGeohashPrecisions(latitude: number, longitude: number) {
  return {
    geohash: generateGeohash(latitude, longitude, 8),          // ~19m precision
    geohashPrecision5: generateGeohash(latitude, longitude, 5), // ~2.4km precision
    geohashPrecision6: generateGeohash(latitude, longitude, 6), // ~610m precision
    geohashPrecision7: generateGeohash(latitude, longitude, 7)  // ~76m precision
  };
}

/**
 * Calculate distance between two points using Haversine formula
 * Returns distance in kilometers
 */
export function calculateDistance(
  lat1: number, lon1: number, 
  lat2: number, lon2: number
): number {
  const R = 6371; // Earth's radius in kilometers
  
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  
  const a = 
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * 
    Math.sin(dLon/2) * Math.sin(dLon/2);
    
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  
  return R * c;
}

/**
 * Get geohash neighbors for radius search
 */
export function getGeohashNeighbors(geohash: string): string[] {
  // This is a simplified version - in production, use a proper geohash library
  const neighbors: string[] = [geohash];
  
  // For now, we'll use prefix matching with slight variations
  // In production, implement proper geohash neighbor calculation
  if (geohash.length > 1) {
    const prefix = geohash.slice(0, -1);
    // Add neighboring cells by varying the last character
    for (let i = 0; i < BASE32.length; i++) {
      const neighbor = prefix + BASE32[i];
      if (neighbor !== geohash) {
        neighbors.push(neighbor);
      }
    }
  }
  
  return neighbors;
}

/**
 * Generate geohash query for radius search
 */
export function generateRadiusQuery(
  centerLat: number, 
  centerLon: number, 
  radiusKm: number
): {
  precision: number;
  geohashes: string[];
  centerGeohash: string;
} {
  // Choose precision based on radius
  let precision: number;
  if (radiusKm <= 0.1) precision = 7;      // ~76m precision for very local search
  else if (radiusKm <= 0.5) precision = 6; // ~610m precision for neighborhood
  else if (radiusKm <= 2) precision = 5;   // ~2.4km precision for area
  else precision = 4;                      // ~20km precision for city-wide

  const centerGeohash = generateGeohash(centerLat, centerLon, precision);
  const neighbors = getGeohashNeighbors(centerGeohash);
  
  return {
    precision,
    geohashes: neighbors,
    centerGeohash
  };
}

/**
 * Algeria-specific landmark coordinates for common searches
 */
export const ALGERIA_LANDMARKS = {
  // Algiers
  'algiers_center': { lat: 36.7538, lon: 3.0588, name: 'Algiers Center' },
  'houari_boumediene_airport': { lat: 36.6910, lon: 3.2154, name: 'Houari Boumediene Airport' },
  'university_algiers': { lat: 36.7167, lon: 3.1833, name: 'University of Algiers' },
  'port_algiers': { lat: 36.7833, lon: 3.0500, name: 'Port of Algiers' },
  
  // Oran
  'oran_center': { lat: 35.6976, lon: -0.6335, name: 'Oran Center' },
  'oran_airport': { lat: 35.6239, lon: -0.6172, name: 'Ahmed Ben Bella Airport' },
  'university_oran': { lat: 35.6500, lon: -0.6167, name: 'University of Oran' },
  'port_oran': { lat: 35.7167, lon: -0.6333, name: 'Port of Oran' },
  
  // Constantine
  'constantine_center': { lat: 36.3650, lon: 6.6147, name: 'Constantine Center' },
  'constantine_airport': { lat: 36.2764, lon: 6.6206, name: 'Mohamed Boudiaf Airport' },
  'university_constantine': { lat: 36.3167, lon: 6.6167, name: 'University of Constantine' },
  
  // Business districts
  'hydra_algiers': { lat: 36.7333, lon: 3.1167, name: 'Hydra Business District' },
  'ben_aknoun': { lat: 36.7167, lon: 3.0833, name: 'Ben Aknoun' },
  'rouiba': { lat: 36.7333, lon: 3.2833, name: 'Rouiba Industrial Zone' }
} as const;

/**
 * Convert landmark name to coordinates
 */
export function getLandmarkCoordinates(landmarkKey: string): { lat: number; lon: number; name: string } | null {
  return ALGERIA_LANDMARKS[landmarkKey as keyof typeof ALGERIA_LANDMARKS] || null;
}

/**
 * Validate coordinates are within Algeria bounds
 */
export function isValidAlgeriaLocation(latitude: number, longitude: number): boolean {
  // Algeria approximate bounds
  const ALGERIA_BOUNDS = {
    north: 37.2,
    south: 18.8,
    east: 12.0,
    west: -8.7
  };
  
  return latitude >= ALGERIA_BOUNDS.south && 
         latitude <= ALGERIA_BOUNDS.north &&
         longitude >= ALGERIA_BOUNDS.west && 
         longitude <= ALGERIA_BOUNDS.east;
}

/**
 * Update property with geohash data
 */
export function updatePropertyGeohash(property: { latitude?: number; longitude?: number }) {
  if (!property.latitude || !property.longitude) {
    return {};
  }
  
  if (!isValidAlgeriaLocation(property.latitude, property.longitude)) {
    console.warn(`Invalid coordinates for Algeria: ${property.latitude}, ${property.longitude}`);
    return {};
  }
  
  return generateGeohashPrecisions(property.latitude, property.longitude);
} 