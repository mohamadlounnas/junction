/**
 * Smart Contact API Tests
 * Comprehensive test suite for all endpoints
 */

import { describe, it, expect, beforeAll, afterAll } from 'bun:test';

const BASE_URL = 'http://localhost:3001';

// Test data
let testContactId: string;
let testPropertyId: string;
let testSaleId: string;

describe('Smart Contact API Tests', () => {
  
  // Health check
  describe('Health Check', () => {
    it('should return health status', async () => {
      const response = await fetch(`${BASE_URL}/health`);
      const data = await response.json();
      
      expect(response.status).toBe(200);
      expect(data.success).toBe(true);
      expect(data.message).toContain('Smart Contact API is running');
    });
  });

  // System stats
  describe('System Stats', () => {
    it('should return system statistics', async () => {
      const response = await fetch(`${BASE_URL}/api/stats`);
      const data = await response.json();
      
      expect(response.status).toBe(200);
      expect(data.success).toBe(true);
      expect(data.data).toHaveProperty('contacts');
      expect(data.data).toHaveProperty('properties');
    });
  });

  // Contacts API
  describe('Contacts API', () => {
    it('should list contacts', async () => {
      const response = await fetch(`${BASE_URL}/api/contacts`);
      const data = await response.json();
      
      expect(response.status).toBe(200);
      expect(data.success).toBe(true);
      expect(Array.isArray(data.data)).toBe(true);
      expect(data).toHaveProperty('pagination');
    });

    it('should create a new contact', async () => {
      const newContact = {
        email: 'test@example.dz',
        name: 'Test Contact',
        phone: '+213 555 000 111',
        type: 'BUYER',
        budgetMin: 10000000,
        budgetMax: 20000000,
        locationWilayas: ['Algiers'],
        locationCities: ['Hydra'],
        propertyTypes: ['VILLA'],
        transactionType: 'SALE',
        familySize: 3,
        hasChildren: true,
        requiresParking: true,
        requiresSecurity: true
      };

      const response = await fetch(`${BASE_URL}/api/contacts`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(newContact)
      });
      
      const data = await response.json();
      
      expect(response.status).toBe(200);
      expect(data.success).toBe(true);
      expect(data.data).toHaveProperty('id');
      expect(data.data.scores).toHaveLength(12);
      
      testContactId = data.data.id;
    });

    it('should get contact by ID', async () => {
      const response = await fetch(`${BASE_URL}/api/contacts/${testContactId}`);
      const data = await response.json();
      
      expect(response.status).toBe(200);
      expect(data.success).toBe(true);
      expect(data.data.id).toBe(testContactId);
    });

    it('should get contact scores', async () => {
      const response = await fetch(`${BASE_URL}/api/contacts/${testContactId}/scores`);
      const data = await response.json();
      
      expect(response.status).toBe(200);
      expect(data.success).toBe(true);
      expect(data.data.scores).toHaveLength(12);
      expect(data.data.dimensions).toHaveLength(12);
    });

    it('should filter contacts by type', async () => {
      const response = await fetch(`${BASE_URL}/api/contacts?type=BUYER`);
      const data = await response.json();
      
      expect(response.status).toBe(200);
      expect(data.success).toBe(true);
      expect(data.filters.type).toBe('BUYER');
    });
  });

  // Properties API
  describe('Properties API', () => {
    it('should list properties', async () => {
      const response = await fetch(`${BASE_URL}/api/properties`);
      const data = await response.json();
      
      expect(response.status).toBe(200);
      expect(data.success).toBe(true);
      expect(Array.isArray(data.data)).toBe(true);
      expect(data).toHaveProperty('pagination');
    });

    it('should create a new property', async () => {
      const newProperty = {
        title: 'Test Villa Moderne',
        description: 'Villa de test avec jardin',
        price: 18000000,
        area: 180,
        rooms: 4,
        bathrooms: 3,
        wilaya: 'Algiers',
        city: 'Hydra',
        address: 'Rue des Tests, Hydra',
        propertyType: 'VILLA',
        transactionType: 'SALE',
        furnishing: 'SEMI_FURNISHED',
        condition: 'EXCELLENT',
        hasParking: true,
        hasSecurity: true,
        hasElevator: false,
        hasGarden: true,
        hasBalcony: true,
        hasSwimmingPool: false,
        featured: false
      };

      const response = await fetch(`${BASE_URL}/api/properties`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(newProperty)
      });
      
      const data = await response.json();
      
      expect(response.status).toBe(200);
      expect(data.success).toBe(true);
      expect(data.data).toHaveProperty('id');
      expect(data.data.scores).toHaveLength(12);
      
      testPropertyId = data.data.id;
    });

    it('should get property by ID', async () => {
      const response = await fetch(`${BASE_URL}/api/properties/${testPropertyId}`);
      const data = await response.json();
      
      expect(response.status).toBe(200);
      expect(data.success).toBe(true);
      expect(data.data.id).toBe(testPropertyId);
    });

    it('should filter properties by wilaya', async () => {
      const response = await fetch(`${BASE_URL}/api/properties?wilaya=Algiers`);
      const data = await response.json();
      
      expect(response.status).toBe(200);
      expect(data.success).toBe(true);
      expect(data.filters.wilaya).toBe('Algiers');
    });

    it('should sync property scores', async () => {
      const response = await fetch(`${BASE_URL}/api/properties/${testPropertyId}/sync-scores`, {
        method: 'POST'
      });
      const data = await response.json();
      
      expect(response.status).toBe(200);
      expect(data.success).toBe(true);
      expect(data.message).toContain('synchronized');
    });

    it('should create property with image_url', async () => {
      const propertyWithImage = {
        title: 'Villa with Image URL',
        description: 'Villa with direct image URL',
        price: 20000000,
        area: 200,
        rooms: 5,
        bathrooms: 3,
        wilaya: 'Algiers',
        city: 'Cheraga',
        propertyType: 'VILLA',
        transactionType: 'SALE',
        furnishing: 'FURNISHED',
        condition: 'EXCELLENT',
        hasParking: true,
        hasSecurity: true,
        hasElevator: false,
        hasGarden: true,
        hasBalcony: true,
        hasSwimmingPool: true,
        image_url: 'https://example.com/villa-image.jpg',
        featured: false
      };

      const response = await fetch(`${BASE_URL}/api/properties`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(propertyWithImage)
      });
      
      const data = await response.json();
      
      expect(response.status).toBe(200);
      expect(data.success).toBe(true);
      expect(data.data.image_url).toBe('https://example.com/villa-image.jpg');
    });

    it('should create property with multiple images', async () => {
      const propertyWithImages = {
        title: 'Apartment with Multiple Images',
        description: 'Modern apartment with gallery',
        price: 15000000,
        area: 120,
        rooms: 3,
        bathrooms: 2,
        wilaya: 'Algiers',
        city: 'Bab Ezzouar',
        propertyType: 'APARTMENT',
        transactionType: 'SALE',
        furnishing: 'SEMI_FURNISHED',
        condition: 'GOOD',
        hasParking: true,
        hasSecurity: true,
        hasElevator: true,
        hasGarden: false,
        hasBalcony: true,
        hasSwimmingPool: false,
        images: [
          'https://example.com/apt-living.jpg',
          'https://example.com/apt-kitchen.jpg',
          'https://example.com/apt-bedroom.jpg'
        ],
        featured: false
      };

      const response = await fetch(`${BASE_URL}/api/properties`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(propertyWithImages)
      });
      
      const data = await response.json();
      
      expect(response.status).toBe(200);
      expect(data.success).toBe(true);
      expect(Array.isArray(data.data.images)).toBe(true);
      expect(data.data.images).toHaveLength(3);
      expect(data.data.images[0]).toBe('https://example.com/apt-living.jpg');
    });

    it('should create property with both image_url and images', async () => {
      const propertyWithBothImages = {
        title: 'House with Complete Gallery',
        description: 'House with main image and gallery',
        price: 12000000,
        area: 150,
        rooms: 4,
        bathrooms: 2,
        wilaya: 'Oran',
        city: 'Oran Center',
        propertyType: 'HOUSE',
        transactionType: 'SALE',
        furnishing: 'UNFURNISHED',
        condition: 'GOOD',
        hasParking: true,
        hasSecurity: false,
        hasElevator: false,
        hasGarden: true,
        hasBalcony: false,
        hasSwimmingPool: false,
        image_url: 'https://example.com/house-main.jpg',
        images: [
          'https://example.com/house-interior1.jpg',
          'https://example.com/house-interior2.jpg'
        ],
        featured: true
      };

      const response = await fetch(`${BASE_URL}/api/properties`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(propertyWithBothImages)
      });
      
      const data = await response.json();
      
      expect(response.status).toBe(200);
      expect(data.success).toBe(true);
      expect(data.data.image_url).toBe('https://example.com/house-main.jpg');
      expect(Array.isArray(data.data.images)).toBe(true);
      expect(data.data.images).toHaveLength(2);
    });
  });

  // Recommendations API (Core AI Feature)
  describe('Recommendations API', () => {
    it('should get property recommendations for contact', async () => {
      const response = await fetch(`${BASE_URL}/api/recommendations/contact/${testContactId}?limit=5`);
      const data = await response.json();
      
      expect(response.status).toBe(200);
      expect(data.success).toBe(true);
      expect(data.data).toHaveProperty('contact');
      expect(data.data).toHaveProperty('recommendations');
      expect(data.data).toHaveProperty('metadata');
      expect(data.data.metadata.algorithm).toBe('12D Vector Similarity');
    });

    it('should get contact recommendations for property', async () => {
      const response = await fetch(`${BASE_URL}/api/recommendations/property/${testPropertyId}?limit=5`);
      const data = await response.json();
      
      expect(response.status).toBe(200);
      expect(data.success).toBe(true);
      expect(data.data).toHaveProperty('property');
      expect(data.data).toHaveProperty('recommendations');
      expect(data.data.metadata.algorithm).toBe('12D Vector Similarity');
    });

    it('should handle bulk recommendations', async () => {
      const bulkRequest = {
        propertyIds: [testPropertyId],
        minSimilarity: 0.3,
        limit: 5
      };

      const response = await fetch(`${BASE_URL}/api/recommendations/bulk`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(bulkRequest)
      });
      
      const data = await response.json();
      
      expect(response.status).toBe(200);
      expect(data.success).toBe(true);
      expect(Array.isArray(data.data)).toBe(true);
      expect(data.metadata.propertiesProcessed).toBe(1);
    });

    it('should filter recommendations by similarity threshold', async () => {
      const response = await fetch(`${BASE_URL}/api/recommendations/contact/${testContactId}?minSimilarity=0.7`);
      const data = await response.json();
      
      expect(response.status).toBe(200);
      expect(data.success).toBe(true);
      expect(data.data.metadata.minSimilarity).toBe(0.7);
    });
  });

  // Sales API (Learning System)
  describe('Sales API', () => {
    it('should list sales', async () => {
      const response = await fetch(`${BASE_URL}/api/sales`);
      const data = await response.json();
      
      expect(response.status).toBe(200);
      expect(data.success).toBe(true);
      expect(Array.isArray(data.data)).toBe(true);
    });

    it('should create a sale and trigger learning', async () => {
      const newSale = {
        contactId: testContactId,
        propertyId: testPropertyId,
        salePrice: 17500000,
        successScore: 0.9,
        timeToDecision: 14,
        viewCount: 3,
        notes: 'Test sale - excellent match'
      };

      const response = await fetch(`${BASE_URL}/api/sales`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(newSale)
      });
      
      const data = await response.json();
      
      expect(response.status).toBe(200);
      expect(data.success).toBe(true);
      expect(data.message).toContain('learning applied');
      
      testSaleId = data.data.id;
    });

    it('should get sale by ID', async () => {
      const response = await fetch(`${BASE_URL}/api/sales/${testSaleId}`);
      const data = await response.json();
      
      expect(response.status).toBe(200);
      expect(data.success).toBe(true);
      expect(data.data.id).toBe(testSaleId);
      expect(data.data).toHaveProperty('contact');
      expect(data.data).toHaveProperty('property');
    });

    it('should get sales analytics', async () => {
      const response = await fetch(`${BASE_URL}/api/sales/analytics`);
      const data = await response.json();
      
      expect(response.status).toBe(200);
      expect(data.success).toBe(true);
      expect(data.data).toHaveProperty('overview');
      expect(data.data).toHaveProperty('trends');
      expect(data.data).toHaveProperty('performance');
    });
  });

  // File Upload and Static Serving
  describe('File Upload and Static Serving', () => {
    it('should serve static files from uploads directory', async () => {
      // Create a test file path (this assumes a test file exists or we're testing the 404 case)
      const response = await fetch(`${BASE_URL}/uploads/test-non-existent-file.jpg`);
      
      // Should return 404 for non-existent file, but with proper error structure
      expect(response.status).toBe(404);
      
      const data = await response.json();
      expect(data.success).toBe(false);
      expect(data.error).toBe('File not found');
    });

    it('should reject access to files outside uploads directory', async () => {
      const response = await fetch(`${BASE_URL}/uploads/../package.json`);
      
      expect(response.status).toBe(403);
      const data = await response.json();
      expect(data.success).toBe(false);
      expect(data.error).toBe('Access denied');
    });
  });

  // Settings API
  describe('Settings API', () => {
    it('should list settings', async () => {
      const response = await fetch(`${BASE_URL}/api/settings`);
      const data = await response.json();
      
      expect(response.status).toBe(200);
      expect(data.success).toBe(true);
      expect(Array.isArray(data.data)).toBe(true);
    });

    it('should get setting by key', async () => {
      const response = await fetch(`${BASE_URL}/api/settings/recommendation_threshold`);
      const data = await response.json();
      
      expect(response.status).toBe(200);
      expect(data.success).toBe(true);
      expect(data.data.key).toBe('recommendation_threshold');
    });

    it('should create/update setting', async () => {
      const newSetting = {
        key: 'test_setting',
        value: '42',
        type: 'NUMBER',
        category: 'test',
        description: 'Test setting for API tests'
      };

      const response = await fetch(`${BASE_URL}/api/settings`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(newSetting)
      });
      
      const data = await response.json();
      
      expect(response.status).toBe(200);
      expect(data.success).toBe(true);
      expect(data.data.key).toBe('test_setting');
    });

    it('should get settings by category', async () => {
      const response = await fetch(`${BASE_URL}/api/settings/category/algorithm`);
      const data = await response.json();
      
      expect(response.status).toBe(200);
      expect(data.success).toBe(true);
      expect(data.category).toBe('algorithm');
      expect(Array.isArray(data.data)).toBe(true);
    });
  });

  // Vector System Tests
  describe('Vector System', () => {
    it('should verify contact has 12D vector', async () => {
      const response = await fetch(`${BASE_URL}/api/contacts/${testContactId}/scores`);
      const data = await response.json();
      
      expect(data.success).toBe(true);
      expect(data.data.scores).toHaveLength(12);
      expect(data.data.dimensions).toContain('Budget');
      expect(data.data.dimensions).toContain('Location');
      expect(data.data.dimensions).toContain('Transaction');
    });

    it('should verify property has 12D vector', async () => {
      const response = await fetch(`${BASE_URL}/api/properties/${testPropertyId}/scores`);
      const data = await response.json();
      
      expect(data.success).toBe(true);
      expect(data.data.scores).toHaveLength(12);
      
      // Verify all scores are between 0 and 1
      data.data.scores.forEach((score: number) => {
        expect(score).toBeGreaterThanOrEqual(0);
        expect(score).toBeLessThanOrEqual(1);
      });
    });

    it('should calculate meaningful similarities', async () => {
      const response = await fetch(`${BASE_URL}/api/recommendations/contact/${testContactId}?limit=1`);
      const data = await response.json();
      
      expect(data.success).toBe(true);
      if (data.data.recommendations.length > 0) {
        const recommendation = data.data.recommendations[0];
        expect(recommendation.similarity).toBeGreaterThanOrEqual(0);
        expect(recommendation.similarity).toBeLessThanOrEqual(1);
        expect(recommendation.explanation).toContain('match');
      }
    });
  });

  // Edge Cases and Error Handling
  describe('Error Handling', () => {
    it('should handle non-existent contact', async () => {
      const response = await fetch(`${BASE_URL}/api/contacts/non-existent-id`);
      const data = await response.json();
      
      expect(data.success).toBe(false);
      expect(data.error).toContain('not found');
    });

    it('should handle non-existent property', async () => {
      const response = await fetch(`${BASE_URL}/api/properties/non-existent-id`);
      const data = await response.json();
      
      expect(data.success).toBe(false);
      expect(data.error).toContain('not found');
    });

    it('should validate email format', async () => {
      const invalidContact = {
        email: 'invalid-email',
        name: 'Test Contact',
        type: 'BUYER',
        transactionType: 'SALE',
        hasChildren: false,
        requiresParking: false,
        requiresSecurity: false,
        locationWilayas: [],
        locationCities: [],
        propertyTypes: []
      };

      const response = await fetch(`${BASE_URL}/api/contacts`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(invalidContact)
      });
      
      expect(response.status).toBe(400);
    });
  });

  // Performance Tests
  describe('Performance', () => {
    it('should handle pagination efficiently', async () => {
      const start = Date.now();
      const response = await fetch(`${BASE_URL}/api/contacts?limit=5`);
      const duration = Date.now() - start;
      
      expect(response.status).toBe(200);
      expect(duration).toBeLessThan(1000); // Should respond within 1 second
    });

    it('should handle bulk recommendations efficiently', async () => {
      // Get some property IDs first
      const propertiesResponse = await fetch(`${BASE_URL}/api/properties?limit=3`);
      const propertiesData = await propertiesResponse.json();
      const propertyIds = propertiesData.data.map((p: any) => p.id);

      const start = Date.now();
      const response = await fetch(`${BASE_URL}/api/recommendations/bulk`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ propertyIds, limit: 5 })
      });
      const duration = Date.now() - start;
      
      expect(response.status).toBe(200);
      expect(duration).toBeLessThan(2000); // Bulk operations should be reasonably fast
    });
  });

  // Cleanup
  describe('Cleanup', () => {
    it('should cleanup test data', async () => {
      // Delete test sale
      if (testSaleId) {
        const saleResponse = await fetch(`${BASE_URL}/api/sales/${testSaleId}`, {
          method: 'DELETE'
        });
        expect(saleResponse.status).toBe(200);
      }

      // Delete test contact
      if (testContactId) {
        const contactResponse = await fetch(`${BASE_URL}/api/contacts/${testContactId}`, {
          method: 'DELETE'
        });
        expect(contactResponse.status).toBe(200);
      }

      // Delete test property
      if (testPropertyId) {
        const propertyResponse = await fetch(`${BASE_URL}/api/properties/${testPropertyId}`, {
          method: 'DELETE'
        });
        expect(propertyResponse.status).toBe(200);
      }

      // Delete test setting
      const settingResponse = await fetch(`${BASE_URL}/api/settings/test_setting`, {
        method: 'DELETE'
      });
      expect(settingResponse.status).toBe(200);
    });
  });
}); 