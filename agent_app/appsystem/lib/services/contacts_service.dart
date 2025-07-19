import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

/// Contact data model matching the API schema
class Contact {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String type; // BUYER, TENANT, INVESTOR
  final double? budgetMin;
  final double? budgetMax;
  final List<String> locationWilayas;
  final List<String> locationCities;
  final List<String> propertyTypes;
  final String transactionType;
  final List<String>? transactionTypes;
  final String? primaryTransactionType;
  final double? transactionFlexibility;
  final int? familySize;
  final bool hasChildren;
  final int? minRooms;
  final int? maxRooms;
  final double? minArea;
  final double? maxArea;
  final String? furnishingType;
  final String? preferredCondition;
  final bool requiresParking;
  final bool requiresSecurity;
  final String? notes;
  final List<double> scores;
  final List<double>? transactionScores;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Contact({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.type,
    this.budgetMin,
    this.budgetMax,
    required this.locationWilayas,
    required this.locationCities,
    required this.propertyTypes,
    required this.transactionType,
    this.transactionTypes,
    this.primaryTransactionType,
    this.transactionFlexibility,
    this.familySize,
    required this.hasChildren,
    this.minRooms,
    this.maxRooms,
    this.minArea,
    this.maxArea,
    this.furnishingType,
    this.preferredCondition,
    required this.requiresParking,
    required this.requiresSecurity,
    this.notes,
    required this.scores,
    this.transactionScores,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      type: json['type'] ?? '',
      budgetMin: json['budgetMin']?.toDouble(),
      budgetMax: json['budgetMax']?.toDouble(),
      locationWilayas: List<String>.from(json['locationWilayas'] ?? []),
      locationCities: List<String>.from(json['locationCities'] ?? []),
      propertyTypes: List<String>.from(json['propertyTypes'] ?? []),
      transactionType: json['transactionType'] ?? '',
      transactionTypes: json['transactionTypes'] != null 
          ? List<String>.from(json['transactionTypes']) 
          : null,
      primaryTransactionType: json['primaryTransactionType'],
      transactionFlexibility: json['transactionFlexibility']?.toDouble(),
      familySize: json['familySize'],
      hasChildren: json['hasChildren'] ?? false,
      minRooms: json['minRooms'],
      maxRooms: json['maxRooms'],
      minArea: json['minArea']?.toDouble(),
      maxArea: json['maxArea']?.toDouble(),
      furnishingType: json['furnishingType'],
      preferredCondition: json['preferredCondition'],
      requiresParking: json['requiresParking'] ?? false,
      requiresSecurity: json['requiresSecurity'] ?? false,
      notes: json['notes'],
      scores: List<double>.from(json['scores'] ?? List.filled(12, 0.5)),
      transactionScores: json['transactionScores'] != null 
          ? List<double>.from(json['transactionScores']) 
          : null,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  /// Get formatted budget range
  String get formattedBudget {
    if (budgetMin == null && budgetMax == null) return 'غير محدد';
    if (budgetMin == null) return 'حتى ${_formatPrice(budgetMax!)}';
    if (budgetMax == null) return 'من ${_formatPrice(budgetMin!)}';
    return '${_formatPrice(budgetMin!)} - ${_formatPrice(budgetMax!)}';
  }

  /// Get contact type display name in Arabic
  String get typeDisplayName {
    switch (type) {
      case 'BUYER':
        return 'مشتري';
      case 'TENANT':
        return 'مستأجر';
      case 'INVESTOR':
        return 'مستثمر';
      default:
        return type;
    }
  }

  /// Get transaction type display name in Arabic
  String get transactionTypeDisplayName {
    if (transactionTypes != null && transactionTypes!.isNotEmpty) {
      if (transactionTypes!.length == 1) {
        return _getSingleTransactionTypeText(transactionTypes!.first);
      } else {
        return 'مرن (${transactionTypes!.map(_getSingleTransactionTypeText).join(' / ')})';
      }
    }
    return _getSingleTransactionTypeText(transactionType);
  }

  String _getSingleTransactionTypeText(String type) {
    switch (type) {
      case 'SALE':
        return 'بيع';
      case 'RENT':
        return 'إيجار';
      default:
        return type;
    }
  }

  /// Get property types display text
  String get propertyTypesDisplayText {
    if (propertyTypes.isEmpty) return 'غير محدد';
    return propertyTypes.map(_getPropertyTypeText).join('، ');
  }

  String _getPropertyTypeText(String type) {
    switch (type) {
      case 'APARTMENT':
        return 'شقة';
      case 'VILLA':
        return 'فيلا';
      case 'HOUSE':
        return 'منزل';
      case 'OFFICE':
        return 'مكتب';
      case 'SHOP':
        return 'محل';
      case 'WAREHOUSE':
        return 'مستودع';
      case 'LAND':
        return 'أرض';
      case 'GARAGE':
        return 'مرآب';
      default:
        return type;
    }
  }

  /// Get location display text
  String get locationDisplayText {
    if (locationWilayas.isEmpty) return 'غير محدد';
    return locationWilayas.join('، ');
  }

  /// Format price in Algerian Dinar
  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M دج';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K دج';
    }
    return '${price.toStringAsFixed(0)} دج';
  }

  /// Get transaction flexibility text
  String get transactionFlexibilityText {
    if (transactionFlexibility == null) return 'غير محدد';
    if (transactionFlexibility! >= 0.8) return 'مرن جداً';
    if (transactionFlexibility! >= 0.6) return 'مرن';
    if (transactionFlexibility! >= 0.4) return 'متوسط';
    return 'غير مرن';
  }

  /// Get transaction flexibility color
  Color get transactionFlexibilityColor {
    if (transactionFlexibility == null) return Colors.grey;
    if (transactionFlexibility! >= 0.8) return Colors.green;
    if (transactionFlexibility! >= 0.6) return Colors.blue;
    if (transactionFlexibility! >= 0.4) return Colors.orange;
    return Colors.red;
  }
}

/// Property recommendation for a contact
class PropertyRecommendation {
  final Map<String, dynamic> property;
  final double similarity;
  final double combinedScore;
  final String matchType;
  final String explanation;

  PropertyRecommendation({
    required this.property,
    required this.similarity,
    required this.combinedScore,
    required this.matchType,
    required this.explanation,
  });

  factory PropertyRecommendation.fromJson(Map<String, dynamic> json) {
    return PropertyRecommendation(
      property: json['property'] != null 
        ? Map<String, dynamic>.from(json['property'] as Map<dynamic, dynamic>)
        : <String, dynamic>{},
      similarity: (json['similarity'] ?? 0.0).toDouble(),
      combinedScore: (json['combinedScore'] ?? 0.0).toDouble(),
      matchType: json['matchType'] ?? 'primary',
      explanation: json['explanation'] ?? '',
    );
  }

  /// Get similarity percentage
  int get similarityPercentage => (similarity * 100).round();

  /// Get match status based on similarity score
  String get matchStatus {
    if (similarity >= 0.8) return 'مطابقة ممتازة';
    if (similarity >= 0.6) return 'مطابقة جيدة';
    if (similarity >= 0.4) return 'مطابقة مقبولة';
    return 'مطابقة ضعيفة';
  }

  /// Get status color
  Color get statusColor {
    if (similarity >= 0.8) return Colors.green;
    if (similarity >= 0.6) return Colors.blue;
    if (similarity >= 0.4) return Colors.orange;
    return Colors.grey;
  }

  /// Get property title
  String get propertyTitle => property['title'] ?? 'عقار بدون عنوان';

  /// Get property price
  String get propertyPrice {
    final price = property['price']?.toDouble() ?? 0.0;
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M دج';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K دج';
    }
    return '${price.toStringAsFixed(0)} دج';
  }

  /// Get property location
  String get propertyLocation {
    final city = property['city'] ?? '';
    final wilaya = property['wilaya'] ?? '';
    if (city.isNotEmpty && wilaya.isNotEmpty) {
      return '$city، $wilaya';
    }
    return city.isNotEmpty ? city : wilaya;
  }

  /// Get property type
  String get propertyType {
    final type = property['propertyType'] ?? '';
    switch (type) {
      case 'APARTMENT':
        return 'شقة';
      case 'VILLA':
        return 'فيلا';
      case 'HOUSE':
        return 'منزل';
      case 'OFFICE':
        return 'مكتب';
      case 'SHOP':
        return 'محل';
      case 'WAREHOUSE':
        return 'مستودع';
      case 'LAND':
        return 'أرض';
      case 'GARAGE':
        return 'مرآب';
      default:
        return type;
    }
  }
}

/// Contacts Service
/// Handles all contact-related API calls
class ContactsService {
  final String _baseUrl;
  final http.Client _httpClient;

  ContactsService({String? baseUrl, http.Client? httpClient})
    : _baseUrl = baseUrl ?? 'https://junction.feeef.org',
      _httpClient = httpClient ?? http.Client();

  /// Get contacts with filtering and pagination
  Future<Map<String, dynamic>> getContacts({
    int page = 1,
    int limit = 10,
    String? type,
    String? search,
    String? wilaya,
    String? transactionType,
    List<String>? transactionTypes,
    String? primaryTransactionType,
    double? budgetMin,
    double? budgetMax,
    bool? hasChildren,
    bool isActive = true,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'isActive': isActive.toString(),
      };

      if (type != null) queryParams['type'] = type;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (wilaya != null) queryParams['wilaya'] = wilaya;
      if (transactionType != null) queryParams['transactionType'] = transactionType;
      if (primaryTransactionType != null) queryParams['primaryTransactionType'] = primaryTransactionType;
      if (budgetMin != null) queryParams['budgetMin'] = budgetMin.toString();
      if (budgetMax != null) queryParams['budgetMax'] = budgetMax.toString();
      if (hasChildren != null) queryParams['hasChildren'] = hasChildren.toString();

      // Handle transactionTypes array
      if (transactionTypes != null && transactionTypes.isNotEmpty) {
        for (int i = 0; i < transactionTypes.length; i++) {
          queryParams['transactionTypes[$i]'] = transactionTypes[i];
        }
      }

      final uri = Uri.parse('$_baseUrl/api/contacts/').replace(queryParameters: queryParams);
      
      final response = await _httpClient.get(uri).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - server not responding');
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        if (jsonResponse['success'] == true) {
          final data = jsonResponse['data'] as List<dynamic>;
          final pagination = jsonResponse['pagination'] ?? {};
          
          return {
            'success': true,
            'data': data.map((item) => Contact.fromJson(Map<String, dynamic>.from(item as Map<dynamic, dynamic>))).toList(),
            'pagination': pagination,
            'filters': jsonResponse['filters'] ?? {},
          };
        } else {
          return {
            'success': false,
            'message': jsonResponse['message'] ?? 'Failed to fetch contacts',
            'data': <Contact>[],
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          'data': <Contact>[],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': <Contact>[],
      };
    }
  }

  /// Get contact by ID
  Future<Map<String, dynamic>> getContact(String id) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/api/contacts/$id'),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - server not responding');
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        if (jsonResponse['success'] == true) {
          return {
            'success': true,
            'data': Contact.fromJson(Map<String, dynamic>.from(jsonResponse['data'] as Map<dynamic, dynamic>)),
          };
        } else {
          return {
            'success': false,
            'message': jsonResponse['message'] ?? 'Failed to fetch contact',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Get property recommendations for a contact
  Future<Map<String, dynamic>> getContactRecommendations(
    String contactId, {
    int limit = 10,
    double minSimilarity = 0.3,
    String? propertyType,
    String? transactionType,
    String? wilaya,
    double? priceMin,
    double? priceMax,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'minSimilarity': minSimilarity.toString(),
      };

      if (propertyType != null) queryParams['propertyType'] = propertyType;
      if (transactionType != null) queryParams['transactionType'] = transactionType;
      if (wilaya != null) queryParams['wilaya'] = wilaya;
      if (priceMin != null) queryParams['priceMin'] = priceMin.toString();
      if (priceMax != null) queryParams['priceMax'] = priceMax.toString();

      final uri = Uri.parse('$_baseUrl/api/recommendations/contact/$contactId')
          .replace(queryParameters: queryParams);

      final response = await _httpClient.get(uri).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - server not responding');
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        if (jsonResponse['success'] == true) {
          final data = jsonResponse['data'];
          List<PropertyRecommendation> recommendations = [];
          
          if (data != null && data['recommendations'] != null) {
            final recommendationsList = data['recommendations'] as List<dynamic>;
            recommendations = recommendationsList
                .map((item) => PropertyRecommendation.fromJson(Map<String, dynamic>.from(item as Map<dynamic, dynamic>)))
                .toList();
          }
          
          return {
            'success': true,
            'data': recommendations,
            'metadata': data['metadata'] ?? {},
            'contact': data['contact'] ?? {},
            'filters': data['filters'] ?? {},
            'total': data['total'] ?? 0,
          };
        } else {
          return {
            'success': false,
            'message': jsonResponse['message'] ?? 'Failed to get recommendations',
            'data': <PropertyRecommendation>[],
            'metadata': {},
            'contact': {},
            'filters': {},
            'total': 0,
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          'data': <PropertyRecommendation>[],
          'metadata': {},
          'contact': {},
          'filters': {},
          'total': 0,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': <PropertyRecommendation>[],
        'metadata': {},
        'contact': {},
        'filters': {},
        'total': 0,
      };
    }
  }

  /// Get contact analytics
  Future<Map<String, dynamic>> getContactAnalytics() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/api/contacts/analytics'),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - server not responding');
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        if (jsonResponse['success'] == true) {
          return {
            'success': true,
            'data': jsonResponse['data'] ?? {},
          };
        } else {
          return {
            'success': false,
            'message': jsonResponse['message'] ?? 'Failed to get analytics',
            'data': {},
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          'data': {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': {},
      };
    }
  }

  /// Dispose of the HTTP client
  void dispose() {
    _httpClient.close();
  }
} 