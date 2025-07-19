import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart'; // Added for Color

// Conditional imports for platform-specific file handling
import 'property_service_platform.dart' if (dart.library.io) 'property_service_io.dart';

/// Property data model matching Prisma schema exactly
class Property {
  final String id;
  final String title;
  final String? description;
  final double price;
  final double area;
  final int rooms;
  final int? bathrooms;
  final String wilaya;
  final String city;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String propertyType; // APARTMENT, VILLA, HOUSE, OFFICE, SHOP, WAREHOUSE, LAND, GARAGE
  final String transactionType; // RENT, SALE
  final String furnishing; // FURNISHED, SEMI_FURNISHED, UNFURNISHED
  final String condition; // POOR, FAIR, GOOD, EXCELLENT, NEW
  final bool hasParking;
  final bool hasSecurity;
  final bool hasElevator;
  final bool hasGarden;
  final bool hasBalcony;
  final bool hasSwimmingPool;
  final int? buildingAge;
  final int? floor;
  final int? totalFloors;
  final String? imageUrl; // image_url from Prisma
  final List<String> images;
  final List<double> scores;
  final String status; // AVAILABLE, RESERVED, SOLD, RENTED, INACTIVE
  final String? ownerId;
  final int viewCount;
  final bool featured;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? geohash;
  final String? geohashPrecision5;
  final String? geohashPrecision6;
  final String? geohashPrecision7;

  Property({
    required this.id,
    required this.title,
    this.description,
    required this.price,
    required this.area,
    required this.rooms,
    this.bathrooms,
    required this.wilaya,
    required this.city,
    this.address,
    this.latitude,
    this.longitude,
    required this.propertyType,
    required this.transactionType,
    required this.furnishing,
    required this.condition,
    required this.hasParking,
    required this.hasSecurity,
    required this.hasElevator,
    required this.hasGarden,
    required this.hasBalcony,
    required this.hasSwimmingPool,
    this.buildingAge,
    this.floor,
    this.totalFloors,
    this.imageUrl,
    required this.images,
    required this.scores,
    required this.status,
    this.ownerId,
    required this.viewCount,
    required this.featured,
    required this.createdAt,
    required this.updatedAt,
    this.geohash,
    this.geohashPrecision5,
    this.geohashPrecision6,
    this.geohashPrecision7,
  });

  /// Create Property from JSON data (matching Prisma schema)
  factory Property.fromJson(Map<String, dynamic> json) {
    try {
      return Property(
        id: json['id']?.toString() ?? '',
        title: json['title'] ?? '',
        description: json['description'],
        price: (json['price'] ?? 0).toDouble(),
        area: (json['area'] ?? 0).toDouble(),
        rooms: json['rooms'] ?? 0,
        bathrooms: json['bathrooms'],
        wilaya: json['wilaya'] ?? '',
        city: json['city'] ?? '',
        address: json['address'],
        latitude: json['latitude']?.toDouble(),
        longitude: json['longitude']?.toDouble(),
        propertyType: json['propertyType'] ?? 'APARTMENT',
        transactionType: json['transactionType'] ?? 'SALE',
        furnishing: json['furnishing'] ?? 'UNFURNISHED',
        condition: json['condition'] ?? 'GOOD',
        hasParking: json['hasParking'] ?? false,
        hasSecurity: json['hasSecurity'] ?? false,
        hasElevator: json['hasElevator'] ?? false,
        hasGarden: json['hasGarden'] ?? false,
        hasBalcony: json['hasBalcony'] ?? false,
        hasSwimmingPool: json['hasSwimmingPool'] ?? false,
        buildingAge: json['buildingAge'],
        floor: json['floor'],
        totalFloors: json['totalFloors'],
        imageUrl: json['image_url'], // Note: Prisma uses image_url
        images: List<String>.from(json['images'] ?? []),
        scores: List<double>.from(json['scores'] ?? List.filled(12, 0.5)),
        status: json['status'] ?? 'AVAILABLE',
        ownerId: json['ownerId'],
        viewCount: json['viewCount'] ?? 0,
        featured: json['featured'] ?? false,
        createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
        updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
        geohash: json['geohash'],
        geohashPrecision5: json['geohashPrecision5'],
        geohashPrecision6: json['geohashPrecision6'],
        geohashPrecision7: json['geohashPrecision7'],
      );
    } catch (e) {
      throw Exception('Failed to parse property JSON: $e');
    }
  }

  /// Convert Property to JSON (matching Prisma schema)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'area': area,
      'rooms': rooms,
      'bathrooms': bathrooms,
      'wilaya': wilaya,
      'city': city,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'propertyType': propertyType,
      'transactionType': transactionType,
      'furnishing': furnishing,
      'condition': condition,
      'hasParking': hasParking,
      'hasSecurity': hasSecurity,
      'hasElevator': hasElevator,
      'hasGarden': hasGarden,
      'hasBalcony': hasBalcony,
      'hasSwimmingPool': hasSwimmingPool,
      'buildingAge': buildingAge,
      'floor': floor,
      'totalFloors': totalFloors,
      'image_url': imageUrl, // Note: Prisma uses image_url
      'images': images,
      'scores': scores,
      'status': status,
      'ownerId': ownerId,
      'viewCount': viewCount,
      'featured': featured,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'geohash': geohash,
      'geohashPrecision5': geohashPrecision5,
      'geohashPrecision6': geohashPrecision6,
      'geohashPrecision7': geohashPrecision7,
    };
  }

  /// Get formatted price in Algerian Dinar
  String get formattedPrice {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M دج';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K دج';
    }
    return '${price.toStringAsFixed(0)} دج';
  }

  /// Get main image URL with fallback
  String get mainImageUrl {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return imageUrl!.startsWith('http') ? imageUrl! : 'https://junction.feeef.org$imageUrl';
    }
    if (images.isNotEmpty) {
      final img = images.first;
      return img.startsWith('http') ? img : 'https://junction.feeef.org$img';
    }
    return _getDefaultImageUrl();
  }

  /// Get property type display name in Arabic
  String get propertyTypeDisplayName {
    switch (propertyType) {
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
        return propertyType;
    }
  }

  /// Get transaction type display name in Arabic
  String get transactionTypeDisplayName {
    switch (transactionType) {
      case 'SALE':
        return 'للبيع';
      case 'RENT':
        return 'للإيجار';
      default:
        return transactionType;
    }
  }

  /// Get condition display name in Arabic
  String get conditionDisplayName {
    switch (condition) {
      case 'NEW':
        return 'جديد';
      case 'EXCELLENT':
        return 'ممتاز';
      case 'GOOD':
        return 'جيد';
      case 'FAIR':
        return 'مقبول';
      case 'POOR':
        return 'سيء';
      default:
        return condition;
    }
  }

  /// Get status display name in Arabic
  String get statusDisplayName {
    switch (status) {
      case 'AVAILABLE':
        return 'متاح';
      case 'RESERVED':
        return 'محجوز';
      case 'SOLD':
        return 'مباع';
      case 'RENTED':
        return 'مؤجر';
      case 'INACTIVE':
        return 'غير نشط';
      default:
        return status;
    }
  }

  /// Get default image URL for properties without images
  static String _getDefaultImageUrl() {
    return 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=400';
  }

  /// Create a copy of this property with updated fields
  Property copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    double? area,
    int? rooms,
    int? bathrooms,
    String? wilaya,
    String? city,
    String? address,
    double? latitude,
    double? longitude,
    String? propertyType,
    String? transactionType,
    String? furnishing,
    String? condition,
    bool? hasParking,
    bool? hasSecurity,
    bool? hasElevator,
    bool? hasGarden,
    bool? hasBalcony,
    bool? hasSwimmingPool,
    int? buildingAge,
    int? floor,
    int? totalFloors,
    String? imageUrl,
    List<String>? images,
    List<double>? scores,
    String? status,
    String? ownerId,
    int? viewCount,
    bool? featured,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? geohash,
    String? geohashPrecision5,
    String? geohashPrecision6,
    String? geohashPrecision7,
  }) {
    return Property(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      area: area ?? this.area,
      rooms: rooms ?? this.rooms,
      bathrooms: bathrooms ?? this.bathrooms,
      wilaya: wilaya ?? this.wilaya,
      city: city ?? this.city,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      propertyType: propertyType ?? this.propertyType,
      transactionType: transactionType ?? this.transactionType,
      furnishing: furnishing ?? this.furnishing,
      condition: condition ?? this.condition,
      hasParking: hasParking ?? this.hasParking,
      hasSecurity: hasSecurity ?? this.hasSecurity,
      hasElevator: hasElevator ?? this.hasElevator,
      hasGarden: hasGarden ?? this.hasGarden,
      hasBalcony: hasBalcony ?? this.hasBalcony,
      hasSwimmingPool: hasSwimmingPool ?? this.hasSwimmingPool,
      buildingAge: buildingAge ?? this.buildingAge,
      floor: floor ?? this.floor,
      totalFloors: totalFloors ?? this.totalFloors,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      scores: scores ?? this.scores,
      status: status ?? this.status,
      ownerId: ownerId ?? this.ownerId,
      viewCount: viewCount ?? this.viewCount,
      featured: featured ?? this.featured,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      geohash: geohash ?? this.geohash,
      geohashPrecision5: geohashPrecision5 ?? this.geohashPrecision5,
      geohashPrecision6: geohashPrecision6 ?? this.geohashPrecision6,
      geohashPrecision7: geohashPrecision7 ?? this.geohashPrecision7,
    );
  }

  @override
  String toString() {
    return 'Property(id: $id, title: $title, price: $price, wilaya: $wilaya)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Property && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// PropertyType enum removed - now using string values matching Prisma schema

/// Contact data model for potential clients
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
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    this.createdAt,
    this.updatedAt,
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
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
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
    switch (transactionType) {
      case 'SALE':
        return 'بيع';
      case 'RENT':
        return 'إيجار';
      default:
        return transactionType;
    }
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
}

/// Contact recommendation with similarity score
class ContactRecommendation {
  final Contact contact;
  final double similarity;
  final String explanation;

  ContactRecommendation({
    required this.contact,
    required this.similarity,
    required this.explanation,
  });

  factory ContactRecommendation.fromJson(Map<String, dynamic> json) {
    return ContactRecommendation(
      contact: Contact.fromJson(json['contact'] ?? {}),
      similarity: (json['similarity'] ?? 0.0).toDouble(),
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
}

/// Property Service
/// Handles all property-related API calls to the Algeria Real Estate backend
class PropertyService {
  final String _baseUrl;
  final http.Client _httpClient;

  /// Constructor with configurable base URL and HTTP client
  PropertyService({String? baseUrl, http.Client? httpClient})
    : _baseUrl = baseUrl ?? 'https://junction.feeef.org',
      _httpClient = httpClient ?? http.Client();

  /// Standardized error handling for consistent error responses
  Map<String, dynamic> _handleError(dynamic error, String operation) {
    String errorMessage;
    
    if (error.toString().contains('timeout')) {
      errorMessage = 'مهلة الانتظار انتهت - يرجى التحقق من اتصال الإنترنت\nNetwork timeout - please check your internet connection';
    } else if (error.toString().contains('SocketException')) {
      errorMessage = 'فشل الاتصال بالشبكة - يرجى التحقق من اتصال الإنترنت\nNetwork connection failed - please check your internet connection';
    } else if (error.toString().contains('HttpException')) {
      errorMessage = 'خطأ في الاتصال بالخادم - يرجى المحاولة لاحقاً\nServer connection error - please try again later';
    } else if (error.toString().contains('FormatException')) {
      errorMessage = 'خطأ في تنسيق البيانات المستلمة\nData format error received from server';
    } else {
      errorMessage = 'خطأ في الشبكة: $error\nNetwork error: $error';
    }

    print('PropertyService: $operation failed - $error');
    
    return {
      'success': false,
      'message': errorMessage,
      'error': error.toString(),
      'operation': operation,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Get all properties with optional filtering - returns List<Property>
  /// This method implements pagination to fetch ALL properties from the API
  Future<List<Property>> getPropertiesList({
    String? wilaya,
    String? city,
    String? propertyType,
    String? transactionType,
    double? minPrice,
    double? maxPrice,
    double? minArea,
    double? maxArea,
    int? rooms,
    double? latitude,
    double? longitude,
    double? radius,
    String? landmark,
    bool? sortByDistance,
    int? page,
    int? limit,
  }) async {
    try {
      print('PropertyService: Starting to fetch all properties...');

      final allProperties = <Property>[];
      int currentPage = 1;
      const int maxLimit = 50; // API maximum limit
      const int maxPages = 10; // Safety limit to prevent infinite loops

      // Build base query parameters (excluding pagination)
      final baseQueryParams = <String, String>{};
      if (wilaya != null) baseQueryParams['wilaya'] = wilaya;
      if (city != null) baseQueryParams['city'] = city;
      if (propertyType != null) baseQueryParams['propertyType'] = propertyType;
      if (transactionType != null)
        baseQueryParams['transactionType'] = transactionType;
      if (minPrice != null) baseQueryParams['minPrice'] = minPrice.toString();
      if (maxPrice != null) baseQueryParams['maxPrice'] = maxPrice.toString();
      if (minArea != null) baseQueryParams['minArea'] = minArea.toString();
      if (maxArea != null) baseQueryParams['maxArea'] = maxArea.toString();
      if (rooms != null) baseQueryParams['rooms'] = rooms.toString();
      if (latitude != null) baseQueryParams['latitude'] = latitude.toString();
      if (longitude != null)
        baseQueryParams['longitude'] = longitude.toString();
      if (radius != null) baseQueryParams['radius'] = radius.toString();
      if (landmark != null) baseQueryParams['landmark'] = landmark;
      if (sortByDistance != null)
        baseQueryParams['sortByDistance'] = sortByDistance.toString();

      // Fetch all pages
      bool hasMorePages = true;
      while (hasMorePages && currentPage <= maxPages) {
        print('PropertyService: Fetching page $currentPage...');

        // Add pagination parameters
        final queryParams = Map<String, String>.from(baseQueryParams);
        queryParams['page'] = currentPage.toString();
        queryParams['limit'] = maxLimit.toString();

        final uri = Uri.parse(
          '$_baseUrl/api/properties/',
        ).replace(queryParameters: queryParams);
        print('PropertyService: Making request to $uri');

        final response = await _httpClient
            .get(uri)
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw Exception('Request timeout - server not responding');
              },
            );
        print('PropertyService: Response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          print(
            'PropertyService: Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
          );

          // Handle different possible response structures
          List<dynamic> propertiesData;
          bool hasMore = false;
          int totalProperties = 0;

          if (jsonResponse['data'] is Map<String, dynamic>) {
            final data = jsonResponse['data'] as Map<String, dynamic>;

            if (data['properties'] != null) {
              // Structure: { data: { properties: [...], total: X, hasMore: Y } }
              propertiesData = data['properties'] as List<dynamic>;
              totalProperties = data['total'] ?? 0;
              hasMore = data['hasMore'] ?? false;
            } else if (data['data'] != null && data['data'] is List) {
              // Structure: { data: { data: [...], total: X, hasMore: Y } }
              propertiesData = data['data'] as List<dynamic>;
              totalProperties = data['total'] ?? 0;
              hasMore = data['hasMore'] ?? false;
            } else {
              // Structure: { data: [...] }
              propertiesData =
                  data.values.where((v) => v is List).first as List<dynamic>;
              totalProperties = propertiesData.length;
              hasMore = false;
            }
          } else if (jsonResponse['data'] is List) {
            // Structure: { data: [...] }
            propertiesData = jsonResponse['data'] as List<dynamic>;
            totalProperties = propertiesData.length;
            hasMore = false;
          } else {
            throw Exception(
              'Unexpected API response structure: ${jsonResponse['data']}',
            );
          }

          print(
            'PropertyService: Found ${propertiesData.length} properties on page $currentPage',
          );
          print(
            'PropertyService: Total properties: $totalProperties, Has more: $hasMore',
          );

          // If we got no properties, we've reached the end
          if (propertiesData.isEmpty) {
            print(
              'PropertyService: No properties returned, stopping pagination',
            );
            hasMorePages = false;
            break;
          }

          // Convert JSON data to Property objects
          for (final propertyData in propertiesData) {
            try {
              final property = Property.fromJson(propertyData);
              allProperties.add(property);
            } catch (e) {
              print('PropertyService: Failed to parse property: $e');
              // Continue with other properties instead of failing completely
            }
          }

          // Check if we should continue to next page
          // Continue if:
          // 1. API says there are more pages (hasMore = true)
          // 2. We got a full page of results (indicating there might be more)
          // 3. We haven't reached the safety limit
          if (hasMore || propertiesData.length == maxLimit) {
            currentPage++;
            // Add a small delay to avoid overwhelming the API
            await Future.delayed(const Duration(milliseconds: 100));
          } else {
            hasMorePages = false;
          }
        } else {
          print(
            'PropertyService: API error - Status: ${response.statusCode}, Body: ${response.body}',
          );
          throw Exception(
            'Failed to retrieve properties: HTTP ${response.statusCode} - ${response.reasonPhrase}',
          );
        }
      }

      print(
        'PropertyService: Successfully fetched ${allProperties.length} total properties',
      );
      print('PropertyService: Fetched from $currentPage pages');

      // Get system stats to compare
      try {
        final stats = await getSystemStats();
        if (stats['success'] == true) {
          final data = stats['data'] as Map<String, dynamic>;
          if (data['properties'] != null) {
            final propsData = data['properties'] as Map<String, dynamic>;
            final apiTotalProps = propsData['total'] ?? 0;
            print(
              'PropertyService: API reports $apiTotalProps total properties',
            );
            if (apiTotalProps > 0 && allProperties.length < apiTotalProps) {
              print(
                'PropertyService: Warning: Only fetched ${allProperties.length}/${apiTotalProps} properties',
              );
            }
          }
        }
      } catch (e) {
        print('PropertyService: Could not verify total property count: $e');
      }

      return allProperties;
    } catch (e) {
      // For this method that returns List<Property>, we still throw but with consistent message
      final errorResponse = _handleError(e, 'fetch all properties');
      throw Exception(errorResponse['message']);
    }
  }

  /// Get a specific property by ID - returns Property
  Future<Property> getPropertyById(String id) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/api/properties/$id'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return Property.fromJson(jsonResponse['data']);
      } else {
        throw Exception('Failed to retrieve property: ${response.statusCode}');
      }
    } catch (e) {
      print('PropertyService: Error getting property $id: $e');
      rethrow;
    }
  }

  /// Create a new property with images
  Future<Map<String, dynamic>> createProperty({
    required Map<String, dynamic> propertyData,
    List<dynamic>? images,
  }) async {
    try {
      // Prepare and validate property data with correct types
      final Map<String, dynamic> validatedData = {
        'title': propertyData['title']?.toString().trim() ?? '',
        'description': propertyData['description']?.toString().trim() ?? '',
        'price': double.tryParse(propertyData['price']?.toString() ?? '0') ?? 0.0,
        'area': double.tryParse(propertyData['area']?.toString() ?? '0') ?? 0.0,
        'rooms': int.tryParse(propertyData['rooms']?.toString() ?? '0') ?? 0,
        'bathrooms': int.tryParse(propertyData['bathrooms']?.toString() ?? '0') ?? 0,
        'wilaya': propertyData['wilaya']?.toString().trim() ?? '',
        'city': propertyData['city']?.toString().trim() ?? '',
        'address': propertyData['address']?.toString().trim() ?? '',
        'propertyType': propertyData['propertyType']?.toString() ?? 'APARTMENT',
        'transactionType': propertyData['transactionType']?.toString() ?? 'SALE',
        'furnishing': propertyData['furnishing']?.toString() ?? 'UNFURNISHED',
        'condition': propertyData['condition']?.toString() ?? 'GOOD',
        'hasParking': _parseBoolean(propertyData['hasParking']),
        'hasSecurity': _parseBoolean(propertyData['hasSecurity']),
        'hasElevator': _parseBoolean(propertyData['hasElevator']),
        'hasGarden': _parseBoolean(propertyData['hasGarden'] ?? false),
        'hasBalcony': _parseBoolean(propertyData['hasBalcony'] ?? false),
        'hasSwimmingPool': _parseBoolean(propertyData['hasSwimmingPool'] ?? false),
        'featured': _parseBoolean(propertyData['featured'] ?? false),
      };

      // For now, let's try creating the property without images first
      // We can add image upload functionality later if needed
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/api/properties/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(validatedData),
      );

      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        // If images are provided, we can handle them separately later
        // For now, just return success
        return {
          'success': true,
          'data': jsonResponse['data'],
          'message': jsonResponse['message'] ?? 'Property created successfully',
        };
      } else {
        return {
          'success': false,
          'message': jsonResponse['message'] ?? 'Failed to create property',
          'error': jsonResponse['error'],
        };
      }
    } catch (e) {
      return _handleError(e, 'create property');
    }
  }

  /// Helper method to parse boolean values
  bool _parseBoolean(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value != 0;
    return false;
  }

  /// Get all properties with optional filtering - legacy method for backward compatibility
  Future<Map<String, dynamic>> getProperties({
    String? wilaya,
    String? city,
    String? propertyType,
    String? transactionType,
    double? minPrice,
    double? maxPrice,
    double? minArea,
    double? maxArea,
    int? rooms,
    double? latitude,
    double? longitude,
    double? radius,
    String? landmark,
    bool? sortByDistance,
    int? page,
    int? limit,
  }) async {
    try {
      final properties = await getPropertiesList(
        wilaya: wilaya,
        city: city,
        propertyType: propertyType,
        transactionType: transactionType,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minArea: minArea,
        maxArea: maxArea,
        rooms: rooms,
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        landmark: landmark,
        sortByDistance: sortByDistance,
        page: page,
        limit: limit,
      );

      return {
        'success': true,
        'data': properties.map((p) => p.toJson()).toList(),
        'message': 'Properties retrieved successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to retrieve properties',
        'error': e.toString(),
      };
    }
  }

  /// Get a specific property by ID - legacy method for backward compatibility
  Future<Map<String, dynamic>> getProperty(String id) async {
    try {
      final property = await getPropertyById(id);
      return {
        'success': true,
        'data': property.toJson(),
        'message': 'Property retrieved successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to retrieve property',
        'error': e.toString(),
      };
    }
  }

  /// Update a property
  Future<Map<String, dynamic>> updateProperty({
    required String id,
    required Map<String, dynamic> propertyData,
    List<dynamic>? images,
  }) async {
    try {
      // Prepare and validate property data with correct types
      final Map<String, dynamic> validatedData = {
        'title': propertyData['title']?.toString().trim() ?? '',
        'description': propertyData['description']?.toString().trim() ?? '',
        'price': double.tryParse(propertyData['price']?.toString() ?? '0') ?? 0.0,
        'area': double.tryParse(propertyData['area']?.toString() ?? '0') ?? 0.0,
        'rooms': int.tryParse(propertyData['rooms']?.toString() ?? '0') ?? 0,
        'bathrooms': int.tryParse(propertyData['bathrooms']?.toString() ?? '0') ?? 0,
        'wilaya': propertyData['wilaya']?.toString().trim() ?? '',
        'city': propertyData['city']?.toString().trim() ?? '',
        'address': propertyData['address']?.toString().trim() ?? '',
        'propertyType': propertyData['propertyType']?.toString() ?? 'APARTMENT',
        'transactionType': propertyData['transactionType']?.toString() ?? 'SALE',
        'furnishing': propertyData['furnishing']?.toString() ?? 'UNFURNISHED',
        'condition': propertyData['condition']?.toString() ?? 'GOOD',
        'hasParking': _parseBoolean(propertyData['hasParking']),
        'hasSecurity': _parseBoolean(propertyData['hasSecurity']),
        'hasElevator': _parseBoolean(propertyData['hasElevator']),
        'hasGarden': _parseBoolean(propertyData['hasGarden'] ?? false),
        'hasBalcony': _parseBoolean(propertyData['hasBalcony'] ?? false),
        'hasSwimmingPool': _parseBoolean(propertyData['hasSwimmingPool'] ?? false),
        'featured': _parseBoolean(propertyData['featured'] ?? false),
      };

      // If no images, send as JSON
      if (images == null || images.isEmpty) {
        final response = await _httpClient.put(
          Uri.parse('$_baseUrl/api/properties/$id'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode(validatedData),
        );

        final jsonResponse = json.decode(response.body);

        if (response.statusCode == 200 && jsonResponse['success'] == true) {
          return {
            'success': true,
            'data': jsonResponse['data'],
            'message': jsonResponse['message'] ?? 'Property updated successfully',
          };
        } else {
          return {
            'success': false,
            'message': jsonResponse['message'] ?? 'Failed to update property',
            'error': jsonResponse['error'],
          };
        }
      } else {
        // If images are provided, use multipart request
        final request = http.MultipartRequest(
          'PUT',
          Uri.parse('$_baseUrl/api/properties/$id'),
        );

        // Add form fields with proper type conversion
        validatedData.forEach((key, value) {
          if (value != null) {
            // Convert booleans to "true"/"false" strings
            if (value is bool) {
              request.fields[key] = value.toString();
            } else {
              request.fields[key] = value.toString();
            }
          }
        });

        // Add images using platform-specific method
        await PropertyServicePlatform.addImagesToRequest(request, images);

        final response = await request.send();
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);

        if (response.statusCode == 200 && jsonResponse['success'] == true) {
          return {
            'success': true,
            'data': jsonResponse['data'],
            'message': jsonResponse['message'] ?? 'Property updated successfully',
          };
        } else {
          return {
            'success': false,
            'message': jsonResponse['message'] ?? 'Failed to update property',
            'error': jsonResponse['error'],
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  /// Delete a property
  Future<Map<String, dynamic>> deleteProperty(String id) async {
    try {
      final response = await _httpClient.delete(
        Uri.parse('$_baseUrl/api/properties/$id'),
      );
      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': jsonResponse['message'] ?? 'Property deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': jsonResponse['message'] ?? 'Failed to delete property',
          'error': jsonResponse['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  /// Get property analytics
  Future<Map<String, dynamic>> getPropertyAnalytics() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/api/properties/analytics'),
      );
      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonResponse['data'],
          'message':
              jsonResponse['message'] ?? 'Analytics retrieved successfully',
        };
      } else {
        return {
          'success': false,
          'message': jsonResponse['message'] ?? 'Failed to retrieve analytics',
          'error': jsonResponse['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  /// Get contact recommendations for a specific property
  Future<Map<String, dynamic>> getPropertyRecommendations(
    String propertyId,
  ) async {
    try {
      print(
        'PropertyService: Getting contact recommendations for property $propertyId',
      );

      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/api/recommendations/property/$propertyId'),
      );

      print(
        'PropertyService: Recommendations response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          print(
            'PropertyService: Successfully retrieved contact recommendations',
          );
          return {
            'success': true,
            'data':
                (jsonResponse['data'] as List<dynamic>?)
                    ?.map((item) => ContactRecommendation.fromJson(item))
                    .toList() ??
                [],
            'message':
                jsonResponse['message'] ??
                'Contact recommendations retrieved successfully',
          };
        } else {
          print(
            'PropertyService: API returned error: ${jsonResponse['message']}',
          );
          return {
            'success': false,
            'message':
                jsonResponse['message'] ??
                'Failed to get contact recommendations',
            'data': [],
          };
        }
      } else {
        print(
          'PropertyService: HTTP error ${response.statusCode}: ${response.body}',
        );
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          'data': [],
        };
      }
    } catch (e) {
      print('PropertyService: Error getting contact recommendations: $e');
      return {'success': false, 'message': 'Network error: $e', 'data': []};
    }
  }

  /// Get system statistics
  Future<Map<String, dynamic>> getSystemStats() async {
    try {
      print('PropertyService: Getting system statistics...');

      final response = await _httpClient.get(Uri.parse('$_baseUrl/api/stats'));

      print('PropertyService: Stats response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          print('PropertyService: Successfully retrieved system stats');
          return {
            'success': true,
            'data': jsonResponse['data'] ?? {},
            'message':
                jsonResponse['message'] ?? 'Statistics retrieved successfully',
          };
        } else {
          print(
            'PropertyService: API returned error: ${jsonResponse['message']}',
          );
          return {
            'success': false,
            'message': jsonResponse['message'] ?? 'Failed to get statistics',
            'data': {},
          };
        }
      } else {
        print(
          'PropertyService: HTTP error ${response.statusCode}: ${response.body}',
        );
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          'data': {},
        };
      }
    } catch (e) {
      print('PropertyService: Error getting statistics: $e');
      return {'success': false, 'message': 'Network error: $e', 'data': {}};
    }
  }

  /// Dispose of the HTTP client
  void dispose() {
    _httpClient.close();
  }
}
