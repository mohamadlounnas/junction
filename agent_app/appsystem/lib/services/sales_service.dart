import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

/// Sale data model matching the API schema
class Sale {
  final String id;
  final String contactId;
  final String propertyId;
  final double salePrice;
  final double successScore;
  final int? timeToDecision;
  final int? viewCount;
  final String? notes;
  final DateTime saleDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Related data
  final Contact? contact;
  final Property? property;

  Sale({
    required this.id,
    required this.contactId,
    required this.propertyId,
    required this.salePrice,
    required this.successScore,
    this.timeToDecision,
    this.viewCount,
    this.notes,
    required this.saleDate,
    required this.createdAt,
    required this.updatedAt,
    this.contact,
    this.property,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'] ?? '',
      contactId: json['contactId'] ?? '',
      propertyId: json['propertyId'] ?? '',
      salePrice: (json['salePrice'] ?? 0.0).toDouble(),
      successScore: (json['successScore'] ?? 0.0).toDouble(),
      timeToDecision: json['timeToDecision'],
      viewCount: json['viewCount'],
      notes: json['notes'],
      saleDate: json['saleDate'] != null
          ? DateTime.parse(json['saleDate'])
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      contact: json['contact'] != null ? Contact.fromJson(Map<String, dynamic>.from(json['contact'] as Map)) : null,
      property: json['property'] != null ? Property.fromJson(Map<String, dynamic>.from(json['property'] as Map)) : null,
    );
  }

  /// Get formatted sale price
  String get formattedSalePrice {
    if (salePrice >= 1000000) {
      return '${(salePrice / 1000000).toStringAsFixed(1)}M دج';
    } else if (salePrice >= 1000) {
      return '${(salePrice / 1000).toStringAsFixed(0)}K دج';
    }
    return '${salePrice.toStringAsFixed(0)} دج';
  }

  /// Get success status
  String get successStatus {
    if (successScore >= 0.8) return 'ممتاز';
    if (successScore >= 0.6) return 'جيد';
    if (successScore >= 0.4) return 'مقبول';
    return 'ضعيف';
  }

  /// Get success status color
  Color get successStatusColor {
    if (successScore >= 0.8) return Colors.green;
    if (successScore >= 0.6) return Colors.blue;
    if (successScore >= 0.4) return Colors.orange;
    return Colors.red;
  }

  /// Get formatted sale date
  String get formattedSaleDate {
    return '${saleDate.day}/${saleDate.month}/${saleDate.year}';
  }

  /// Get time to decision text
  String get timeToDecisionText {
    if (timeToDecision == null) return 'غير محدد';
    if (timeToDecision! < 7) return 'أقل من أسبوع';
    if (timeToDecision! < 30) return 'أقل من شهر';
    if (timeToDecision! < 90) return 'أقل من 3 أشهر';
    return 'أكثر من 3 أشهر';
  }
}

/// Simplified Contact model for sales
class Contact {
  final String id;
  final String name;
  final String email;
  final String type;

  Contact({
    required this.id,
    required this.name,
    required this.email,
    required this.type,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      type: json['type'] ?? '',
    );
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
}

/// Simplified Property model for sales
class Property {
  final String id;
  final String title;
  final double price;
  final String wilaya;
  final String city;

  Property({
    required this.id,
    required this.title,
    required this.price,
    required this.wilaya,
    required this.city,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      wilaya: json['wilaya'] ?? '',
      city: json['city'] ?? '',
    );
  }

  /// Get formatted price
  String get formattedPrice {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M دج';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K دج';
    }
    return '${price.toStringAsFixed(0)} دج';
  }

  /// Get location display text
  String get locationDisplayText {
    if (city.isNotEmpty && wilaya.isNotEmpty) {
      return '$city، $wilaya';
    }
    return city.isNotEmpty ? city : wilaya;
  }
}

/// Sales Analytics data model
class SalesAnalytics {
  final Map<String, dynamic> overview;
  final Map<String, dynamic> trends;
  final Map<String, dynamic> performance;

  SalesAnalytics({
    required this.overview,
    required this.trends,
    required this.performance,
  });

  factory SalesAnalytics.fromJson(Map<String, dynamic> json) {
    return SalesAnalytics(
      overview: json['overview'] ?? {},
      trends: json['trends'] ?? {},
      performance: json['performance'] ?? {},
    );
  }

  /// Get total sales
  int get totalSales => overview['totalSales'] ?? 0;

  /// Get average success score
  double get averageSuccessScore => (overview['averageSuccessScore'] ?? 0.0).toDouble();

  /// Get average success score percentage
  int get averageSuccessScorePercentage => (averageSuccessScore * 100).round();

  /// Get sales by month
  List<Map<String, dynamic>> get salesByMonth {
    final data = trends['salesByMonth'] as List<dynamic>?;
    return data?.map((item) => Map<String, dynamic>.from(item)).toList() ?? [];
  }

  /// Get top performing contacts
  List<Map<String, dynamic>> get topPerformingContacts {
    final data = performance['topContacts'] as List<dynamic>?;
    return data?.map((item) => Map<String, dynamic>.from(item)).toList() ?? [];
  }

  /// Get top performing properties
  List<Map<String, dynamic>> get topPerformingProperties {
    final data = performance['topProperties'] as List<dynamic>?;
    return data?.map((item) => Map<String, dynamic>.from(item)).toList() ?? [];
  }
}

/// Sales Service
/// Handles all sales-related API calls
class SalesService {
  final String _baseUrl;
  final http.Client _httpClient;

  SalesService({String? baseUrl, http.Client? httpClient})
    : _baseUrl = baseUrl ?? 'https://junction.feeef.org',
      _httpClient = httpClient ?? http.Client();

  /// Get sales with filtering and pagination
  Future<Map<String, dynamic>> getSales({
    int page = 1,
    int limit = 10,
    String? contactId,
    String? propertyId,
    double? successScoreMin,
    double? successScoreMax,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (contactId != null) queryParams['contactId'] = contactId;
      if (propertyId != null) queryParams['propertyId'] = propertyId;
      if (successScoreMin != null) queryParams['successScoreMin'] = successScoreMin.toString();
      if (successScoreMax != null) queryParams['successScoreMax'] = successScoreMax.toString();

      final uri = Uri.parse('$_baseUrl/api/sales/').replace(queryParameters: queryParams);
      
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
            'data': data.map((item) => Sale.fromJson(item)).toList(),
            'pagination': pagination,
          };
        } else {
          return {
            'success': false,
            'message': jsonResponse['message'] ?? 'Failed to fetch sales',
            'data': <Sale>[],
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          'data': <Sale>[],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': <Sale>[],
      };
    }
  }

  /// Get sale by ID
  Future<Map<String, dynamic>> getSale(String id) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/api/sales/$id'),
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
            'data': Sale.fromJson(jsonResponse['data']),
          };
        } else {
          return {
            'success': false,
            'message': jsonResponse['message'] ?? 'Failed to fetch sale',
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

  /// Create new sale
  Future<Map<String, dynamic>> createSale({
    required String contactId,
    required String propertyId,
    required double salePrice,
    required double successScore,
    int? timeToDecision,
    int? viewCount,
    String? notes,
  }) async {
    try {
      final body = {
        'contactId': contactId,
        'propertyId': propertyId,
        'salePrice': salePrice,
        'successScore': successScore,
        if (timeToDecision != null) 'timeToDecision': timeToDecision,
        if (viewCount != null) 'viewCount': viewCount,
        if (notes != null) 'notes': notes,
      };

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/api/sales/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
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
            'data': Sale.fromJson(jsonResponse['data']),
            'message': jsonResponse['message'] ?? 'Sale created successfully',
          };
        } else {
          return {
            'success': false,
            'message': jsonResponse['message'] ?? 'Failed to create sale',
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

  /// Update sale
  Future<Map<String, dynamic>> updateSale({
    required String id,
    double? salePrice,
    double? successScore,
    int? timeToDecision,
    int? viewCount,
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (salePrice != null) body['salePrice'] = salePrice;
      if (successScore != null) body['successScore'] = successScore;
      if (timeToDecision != null) body['timeToDecision'] = timeToDecision;
      if (viewCount != null) body['viewCount'] = viewCount;
      if (notes != null) body['notes'] = notes;

      final response = await _httpClient.put(
        Uri.parse('$_baseUrl/api/sales/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
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
            'data': Sale.fromJson(jsonResponse['data']),
            'message': jsonResponse['message'] ?? 'Sale updated successfully',
          };
        } else {
          return {
            'success': false,
            'message': jsonResponse['message'] ?? 'Failed to update sale',
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

  /// Delete sale
  Future<Map<String, dynamic>> deleteSale(String id) async {
    try {
      final response = await _httpClient.delete(
        Uri.parse('$_baseUrl/api/sales/$id'),
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
            'message': jsonResponse['message'] ?? 'Sale deleted successfully',
          };
        } else {
          return {
            'success': false,
            'message': jsonResponse['message'] ?? 'Failed to delete sale',
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

  /// Get sales analytics
  Future<Map<String, dynamic>> getSalesAnalytics() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/api/sales/analytics'),
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
            'data': SalesAnalytics.fromJson(jsonResponse['data']),
          };
        } else {
          return {
            'success': false,
            'message': jsonResponse['message'] ?? 'Failed to get analytics',
            'data': SalesAnalytics.fromJson({}),
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          'data': SalesAnalytics.fromJson({}),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': SalesAnalytics.fromJson({}),
      };
    }
  }

  /// Dispose of the HTTP client
  void dispose() {
    _httpClient.close();
  }
} 