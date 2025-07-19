import 'package:flutter_test/flutter_test.dart';
import 'package:appsystem/services/contacts_service.dart';

void main() {
  group('ContactsService Tests', () {
    test('Contact model creation from JSON', () {
      final jsonData = {
        'id': 'test-id',
        'email': 'test@example.com',
        'name': 'Test User',
        'phone': '+213 123 456 789',
        'type': 'INVESTOR',
        'budgetMin': 100000.0,
        'budgetMax': 500000.0,
        'locationWilayas': ['Alger'],
        'locationCities': ['Alger'],
        'propertyTypes': ['APARTMENT'],
        'transactionType': 'SALE',
        'familySize': 4,
        'hasChildren': true,
        'minRooms': 2,
        'maxRooms': 4,
        'minArea': 100.0,
        'maxArea': 150.0,
        'furnishingType': 'FURNISHED',
        'preferredCondition': 'GOOD',
        'requiresParking': true,
        'requiresSecurity': true,
        'scores': [0.8, 0.7, 0.9],
        'isActive': true,
        'notes': 'Test contact',
        'createdAt': '2025-01-01T00:00:00.000Z',
        'updatedAt': '2025-01-01T00:00:00.000Z',
        'primaryTransactionType': 'SALE',
        'transactionFlexibility': 0.5,
        'transactionScores': [0.0, 1.0],
        'transactionTypes': ['SALE'],
      };

      final contact = Contact.fromJson(jsonData);

      expect(contact.id, equals('test-id'));
      expect(contact.name, equals('Test User'));
      expect(contact.email, equals('test@example.com'));
      expect(contact.type, equals('INVESTOR'));
      expect(contact.budgetMin, equals(100000.0));
      expect(contact.budgetMax, equals(500000.0));
      expect(contact.locationWilayas, equals(['Alger']));
      expect(contact.propertyTypes, equals(['APARTMENT']));
      expect(contact.transactionType, equals('SALE'));
      expect(contact.familySize, equals(4));
      expect(contact.hasChildren, equals(true));
      expect(contact.isActive, equals(true));
      expect(contact.scores.length, equals(3));
    });

    test('Contact computed properties', () {
      final contact = Contact(
        id: 'test-id',
        email: 'test@example.com',
        name: 'Test User',
        phone: '+213 123 456 789',
        type: 'INVESTOR',
        budgetMin: 100000.0,
        budgetMax: 500000.0,
        locationWilayas: ['Alger'],
        locationCities: ['Alger'],
        propertyTypes: ['APARTMENT'],
        transactionType: 'SALE',
        familySize: 4,
        hasChildren: true,
        minRooms: 2,
        maxRooms: 4,
        minArea: 100.0,
        maxArea: 150.0,
        furnishingType: 'FURNISHED',
        preferredCondition: 'GOOD',
        requiresParking: true,
        requiresSecurity: true,
        scores: [0.8, 0.7, 0.9],
        isActive: true,
        notes: 'Test contact',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        primaryTransactionType: 'SALE',
        transactionFlexibility: 0.5,
        transactionScores: [0.0, 1.0],
        transactionTypes: ['SALE'],
      );

      expect(contact.formattedBudget, contains('100K - 500K'));
      expect(contact.typeDisplayName, equals('مستثمر'));
      expect(contact.transactionTypeDisplayName, equals('بيع'));
    });

    test('Contact urgency levels', () {
      // Test hot urgency
      final hotContact = Contact(
        id: 'hot-id',
        email: 'hot@example.com',
        name: 'Hot User',
        phone: '+213 123 456 789',
        type: 'INVESTOR',
        budgetMin: 100000.0,
        budgetMax: 500000.0,
        locationWilayas: ['Alger'],
        locationCities: ['Alger'],
        propertyTypes: ['APARTMENT'],
        transactionType: 'SALE',
        familySize: 4,
        hasChildren: true,
        minRooms: 2,
        maxRooms: 4,
        minArea: 100.0,
        maxArea: 150.0,
        furnishingType: 'FURNISHED',
        preferredCondition: 'GOOD',
        requiresParking: true,
        requiresSecurity: true,
        scores: [0.8, 0.9, 0.9], // High scores
        isActive: true,
        notes: 'Hot contact',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        primaryTransactionType: 'SALE',
        transactionFlexibility: 0.5,
        transactionScores: [0.0, 1.0],
        transactionTypes: ['SALE'],
      );


      // Test cold urgency
      final coldContact = Contact(
        id: 'cold-id',
        email: 'cold@example.com',
        name: 'Cold User',
        phone: '+213 123 456 789',
        type: 'INVESTOR',
        budgetMin: 100000.0,
        budgetMax: 500000.0,
        locationWilayas: ['Alger'],
        locationCities: ['Alger'],
        propertyTypes: ['APARTMENT'],
        transactionType: 'SALE',
        familySize: 4,
        hasChildren: true,
        minRooms: 2,
        maxRooms: 4,
        minArea: 100.0,
        maxArea: 150.0,
        furnishingType: 'FURNISHED',
        preferredCondition: 'GOOD',
        requiresParking: true,
        requiresSecurity: true,
        scores: [0.2, 0.3, 0.1], // Low scores
        isActive: false, // Inactive
        notes: 'Cold contact',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        primaryTransactionType: 'SALE',
        transactionFlexibility: 0.5,
        transactionScores: [0.0, 1.0],
        transactionTypes: ['SALE'],
      );

    });

    test('ContactsResponse model creation', () {
      final jsonData = {
        'success': true,
        'data': [
          {
            'id': 'test-id',
            'email': 'test@example.com',
            'name': 'Test User',
            'phone': '+213 123 456 789',
            'type': 'INVESTOR',
            'budgetMin': 100000.0,
            'budgetMax': 500000.0,
            'locationWilayas': ['Alger'],
            'locationCities': ['Alger'],
            'propertyTypes': ['APARTMENT'],
            'transactionType': 'SALE',
            'familySize': 4,
            'hasChildren': true,
            'minRooms': 2,
            'maxRooms': 4,
            'minArea': 100.0,
            'maxArea': 150.0,
            'furnishingType': 'FURNISHED',
            'preferredCondition': 'GOOD',
            'requiresParking': true,
            'requiresSecurity': true,
            'scores': [0.8, 0.7, 0.9],
            'isActive': true,
            'notes': 'Test contact',
            'createdAt': '2025-01-01T00:00:00.000Z',
            'updatedAt': '2025-01-01T00:00:00.000Z',
            'primaryTransactionType': 'SALE',
            'transactionFlexibility': 0.5,
            'transactionScores': [0.0, 1.0],
            'transactionTypes': ['SALE'],
          },
        ],
        'pagination': {'page': 1, 'limit': 10, 'total': 1, 'pages': 1},
        'filters': {},
      };

    });
  });
}
