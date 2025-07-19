import 'package:flutter_test/flutter_test.dart';
import 'package:appsystem/services/property_service.dart' as property_service;
import 'package:appsystem/services/contacts_service.dart' as contact_service;

void main() {
  group('Type Casting Tests', () {
    test('ContactRecommendation.fromJson should handle LinkedMap correctly', () {
      // Simulate API response with LinkedMap
      final jsonData = {
        'contact': {
          'id': '123',
          'name': 'Test Contact',
          'email': 'test@example.com',
          'type': 'BUYER',
          'transactionType': 'SALE',
          'budgetMin': 1000000.0,
          'budgetMax': 2000000.0,
          'locationWilayas': ['Algiers', 'Oran'],
          'familySize': 4,
          'hasChildren': true,
          'scores': [0.8, 0.6, 0.9, 0.7, 0.5, 0.8, 0.6, 0.9, 0.7, 0.5, 0.8, 0.6],
        },
        'similarity': 0.85,
        'explanation': 'This contact matches the property requirements well',
      };

      // This should not throw a TypeError
      expect(() {
        final recommendation = property_service.ContactRecommendation.fromJson(jsonData);
        expect(recommendation.contact.name, 'Test Contact');
        expect(recommendation.similarity, 0.85);
        expect(recommendation.explanation, 'This contact matches the property requirements well');
        expect(recommendation.similarityPercentage, 85);
        expect(recommendation.matchStatus, 'مطابقة ممتازة');
      }, returnsNormally);
    });

    test('PropertyRecommendation.fromJson should handle LinkedMap correctly', () {
      // Simulate API response with LinkedMap
      final jsonData = {
        'property': {
          'id': '456',
          'title': 'Beautiful Villa in Algiers',
          'description': 'A stunning villa with garden',
          'price': 15000000.0,
          'area': 200.0,
          'rooms': 4,
          'wilaya': 'Algiers',
          'city': 'Algiers',
          'propertyType': 'VILLA',
          'transactionType': 'SALE',
          'condition': 'EXCELLENT',
          'image_url': '/uploads/villa-456.jpg',
          'images': ['/uploads/villa-456-1.jpg', '/uploads/villa-456-2.jpg'],
          'scores': [0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1, 0.0, 0.9, 0.8],
        },
        'similarity': 0.92,
        'combinedScore': 0.88,
        'matchType': 'primary',
        'explanation': 'This property perfectly matches the contact preferences',
      };

      // This should not throw a TypeError
      expect(() {
        final recommendation = contact_service.PropertyRecommendation.fromJson(jsonData);
        expect(recommendation.property['title'], 'Beautiful Villa in Algiers');
        expect(recommendation.similarity, 0.92);
        expect(recommendation.combinedScore, 0.88);
        expect(recommendation.matchType, 'primary');
        expect(recommendation.explanation, 'This property perfectly matches the contact preferences');
        expect(recommendation.similarityPercentage, 92);
        expect(recommendation.matchStatus, 'مطابقة ممتازة');
        expect(recommendation.propertyPrice, '15.0M دج');
        expect(recommendation.propertyLocation, 'Algiers، Algiers');
        expect(recommendation.propertyType, 'فيلا');
      }, returnsNormally);
    });

    test('Contact.fromJson should handle LinkedMap correctly', () {
      // Simulate API response with LinkedMap
      final jsonData = {
        'id': '789',
        'name': 'Ahmed Ben Ali',
        'email': 'ahmed@example.com',
        'phone': '+213 123 456 789',
        'type': 'TENANT',
        'transactionType': 'RENT',
        'budgetMin': 50000.0,
        'budgetMax': 80000.0,
        'locationWilayas': ['Algiers', 'Tipaza'],
        'familySize': 3,
        'hasChildren': false,
        'scores': [0.7, 0.6, 0.8, 0.5, 0.9, 0.7, 0.6, 0.8, 0.5, 0.9, 0.7, 0.6],
      };

      // This should not throw a TypeError
      expect(() {
        final contact = property_service.Contact.fromJson(jsonData);
        expect(contact.name, 'Ahmed Ben Ali');
        expect(contact.email, 'ahmed@example.com');
        expect(contact.type, 'TENANT');
        expect(contact.transactionType, 'RENT');
        expect(contact.budgetMin, 50000.0);
        expect(contact.budgetMax, 80000.0);
        expect(contact.locationWilayas, ['Algiers', 'Tipaza']);
        expect(contact.familySize, 3);
        expect(contact.hasChildren, false);
        expect(contact.locationWilayas.length, 2);
      }, returnsNormally);
    });

    test('Property.fromJson should handle LinkedMap correctly', () {
      // Simulate API response with LinkedMap
      final jsonData = {
        'id': '101',
        'title': 'Modern Apartment in Oran',
        'description': 'Spacious apartment with sea view',
        'price': 8000000.0,
        'area': 120.0,
        'rooms': 3,
        'wilaya': 'Oran',
        'city': 'Oran',
        'propertyType': 'APARTMENT',
        'transactionType': 'SALE',
        'condition': 'GOOD',
        'image_url': '/uploads/apartment-101.jpg',
        'images': ['/uploads/apartment-101-1.jpg'],
        'scores': [0.6, 0.7, 0.8, 0.5, 0.9, 0.6, 0.7, 0.8, 0.5, 0.9, 0.6, 0.7],
      };

      // This should not throw a TypeError
      expect(() {
        final property = property_service.Property.fromJson(jsonData);
        expect(property.title, 'Modern Apartment in Oran');
        expect(property.price, 8000000.0);
        expect(property.area, 120.0);
        expect(property.rooms, 3);
        expect(property.wilaya, 'Oran');
        expect(property.city, 'Oran');
        expect(property.propertyType, 'APARTMENT');
        expect(property.transactionType, 'SALE');
        expect(property.condition, 'GOOD');
        expect(property.imageUrl, '/uploads/apartment-101.jpg');
        expect(property.images.length, 1);
        expect(property.scores.length, 12);
      }, returnsNormally);
    });

    test('Should handle null values gracefully', () {
      final jsonData = {
        'contact': null,
        'similarity': 0.75,
        'explanation': 'Test explanation',
      };

      // This should not throw an error
      expect(() {
        final recommendation = property_service.ContactRecommendation.fromJson(jsonData);
        expect(recommendation.similarity, 0.75);
        expect(recommendation.explanation, 'Test explanation');
      }, returnsNormally);
    });

    test('Should handle empty maps gracefully', () {
      final jsonData = {
        'contact': <String, dynamic>{},
        'similarity': 0.65,
        'explanation': '',
      };

      // This should not throw an error
      expect(() {
        final recommendation = property_service.ContactRecommendation.fromJson(jsonData);
        expect(recommendation.similarity, 0.65);
        expect(recommendation.explanation, '');
      }, returnsNormally);
    });
  });
} 