import 'package:flutter/material.dart';

class LeadsServices extends ChangeNotifier {
  List<ContactModel> _contacts = [];

  List<ContactModel> get contacts => _contacts;

  void addContact(ContactModel contact) {
    _contacts.add(contact);
    notifyListeners();
  }
}

class ContactModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String type; // INVESTOR, BUYER, SELLER, etc.
  final double budgetMin;
  final double budgetMax;
  final List<String> locationWilayas;
  final List<String> locationCities;
  final List<String> propertyTypes; // SHOP, LAND, etc.
  final String transactionType; // RENT, SALE
  final int familySize;
  final bool hasChildren;
  final int minRooms;
  final int maxRooms;
  final double minArea;
  final double maxArea;
  final String furnishingType; // FURNISHED, SEMI_FURNISHED, UNFURNISHED
  final String preferredCondition; // POOR, FAIR, GOOD, EXCELLENT, NEW
  final bool requiresParking;
  final bool requiresSecurity;
  final List<double> scores;
  final bool isActive;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String primaryTransactionType; // RENT, SALE
  final double transactionFlexibility;
  final List<double> transactionScores;
  final List<String> transactionTypes;

  ContactModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.type,
    required this.budgetMin,
    required this.budgetMax,
    required this.locationWilayas,
    required this.locationCities,
    required this.propertyTypes,
    required this.transactionType,
    required this.familySize,
    required this.hasChildren,
    required this.minRooms,
    required this.maxRooms,
    required this.minArea,
    required this.maxArea,
    required this.furnishingType,
    required this.preferredCondition,
    required this.requiresParking,
    required this.requiresSecurity,
    required this.scores,
    required this.isActive,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.primaryTransactionType,
    required this.transactionFlexibility,
    required this.transactionScores,
    required this.transactionTypes,
  });

  /// Factory method to create a ContactModel from a JSON map.
  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      type: json['type'] as String,
      budgetMin: (json['budgetMin'] as num).toDouble(),
      budgetMax: (json['budgetMax'] as num).toDouble(),
      locationWilayas: List<String>.from(json['locationWilayas']),
      locationCities: List<String>.from(json['locationCities']),
      propertyTypes: List<String>.from(json['propertyTypes']),
      transactionType: json['transactionType'] as String,
      familySize: json['familySize'] as int,
      hasChildren: json['hasChildren'] as bool,
      minRooms: json['minRooms'] as int,
      maxRooms: json['maxRooms'] as int,
      minArea: (json['minArea'] as num).toDouble(),
      maxArea: (json['maxArea'] as num).toDouble(),
      furnishingType: json['furnishingType'] as String,
      preferredCondition: json['preferredCondition'] as String,
      requiresParking: json['requiresParking'] as bool,
      requiresSecurity: json['requiresSecurity'] as bool,
      scores: List<double>.from(json['scores']),
      isActive: json['isActive'] as bool,
      notes: json['notes'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      primaryTransactionType: json['primaryTransactionType'] as String,
      transactionFlexibility: (json['transactionFlexibility'] as num)
          .toDouble(),
      transactionScores: List<double>.from(json['transactionScores']),
      transactionTypes: List<String>.from(json['transactionTypes']),
    );
  }

  /// Convert the ContactModel to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'type': type,
      'budgetMin': budgetMin,
      'budgetMax': budgetMax,
      'locationWilayas': locationWilayas,
      'locationCities': locationCities,
      'propertyTypes': propertyTypes,
      'transactionType': transactionType,
      'familySize': familySize,
      'hasChildren': hasChildren,
      'minRooms': minRooms,
      'maxRooms': maxRooms,
      'minArea': minArea,
      'maxArea': maxArea,
      'furnishingType': furnishingType,
      'preferredCondition': preferredCondition,
      'requiresParking': requiresParking,
      'requiresSecurity': requiresSecurity,
      'scores': scores,
      'isActive': isActive,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'primaryTransactionType': primaryTransactionType,
      'transactionFlexibility': transactionFlexibility,
      'transactionScores': transactionScores,
      'transactionTypes': transactionTypes,
    };
  }
}
