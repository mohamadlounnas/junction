import 'dart:convert';
import 'package:http/http.dart' as http;

/// Property data model
class Property {
  final String id;
  final String title;
  final String? description;
  final double price;
  final double area;
  final int rooms;
  final String wilaya;
  final String city;
  final String propertyType;
  final String transactionType;
  final String condition;
  final String? imageUrl;
  final List<String> images;
  final List<double>? scores;
  final String? address;
  final double? latitude;
  final double? longitude;
  final int? bathrooms;
  final String? furnishing;
  final bool? hasParking;
  final bool? hasSecurity;
  final bool? hasElevator;
  final bool? hasGarden;
  final bool? hasBalcony;
  final bool? hasSwimmingPool;
  final int? buildingAge;
  final int? floor;
  final int? totalFloors;
  final bool? featured;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Property({
    required this.id,
    required this.title,
    this.description,
    required this.price,
    required this.area,
    required this.rooms,
    required this.wilaya,
    required this.city,
    required this.propertyType,
    required this.transactionType,
    required this.condition,
    this.imageUrl,
    this.images = const [],
    this.scores,
    this.address,
    this.latitude,
    this.longitude,
    this.bathrooms,
    this.furnishing,
    this.hasParking,
    this.hasSecurity,
    this.hasElevator,
    this.hasGarden,
    this.hasBalcony,
    this.hasSwimmingPool,
    this.buildingAge,
    this.floor,
    this.totalFloors,
    this.featured,
    this.createdAt,
    this.updatedAt,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      price: (json['price'] ?? 0).toDouble(),
      area: (json['area'] ?? 0).toDouble(),
      rooms: json['rooms'] ?? 0,
      wilaya: json['wilaya'] ?? '',
      city: json['city'] ?? '',
      propertyType: json['propertyType'] ?? '',
      transactionType: json['transactionType'] ?? '',
      condition: json['condition'] ?? '',
      imageUrl: json['image_url'],
      images: List<String>.from(json['images'] ?? []),
      scores: json['scores'] != null ? List<double>.from(json['scores']) : null,
      address: json['address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      bathrooms: json['bathrooms'],
      furnishing: json['furnishing'],
      hasParking: json['hasParking'],
      hasSecurity: json['hasSecurity'],
      hasElevator: json['hasElevator'],
      hasGarden: json['hasGarden'],
      hasBalcony: json['hasBalcony'],
      hasSwimmingPool: json['hasSwimmingPool'],
      buildingAge: json['buildingAge'],
      floor: json['floor'],
      totalFloors: json['totalFloors'],
      featured: json['featured'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  /// Get formatted price in DZD
  String get formattedPrice {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M دج';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K دج';
    }
    return '${price.toStringAsFixed(0)} دج';
  }

  /// Get formatted area
  String get formattedArea => '${area.toStringAsFixed(0)} م²';

  /// Get main image URL
  String? get mainImageUrl {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return imageUrl!.startsWith('http')
          ? imageUrl
          : '${PropertiesService._baseUrl}$imageUrl';
    }
    if (images.isNotEmpty) {
      final firstImage = images.first;
      return firstImage.startsWith('http')
          ? firstImage
          : '${PropertiesService._baseUrl}$firstImage';
    }
    return null;
  }

  /// Get all image URLs with base URL
  List<String> get allImageUrls {
    final List<String> urls = [];

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      urls.add(
        imageUrl!.startsWith('http')
            ? imageUrl!
            : '${PropertiesService._baseUrl}$imageUrl',
      );
    }

    for (final image in images) {
      urls.add(
        image.startsWith('http')
            ? image
            : '${PropertiesService._baseUrl}$image',
      );
    }

    return urls;
  }
}

/// Properties response wrapper
class PropertiesResponse {
  final List<Property> properties;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;

  PropertiesResponse({
    required this.properties,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  factory PropertiesResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final propertiesList = data['properties'] as List<dynamic>;

    return PropertiesResponse(
      properties: propertiesList.map((p) => Property.fromJson(p)).toList(),
      total: data['total'] ?? 0,
      page: data['page'] ?? 1,
      limit: data['limit'] ?? 10,
      hasMore: data['hasMore'] ?? false,
    );
  }
}

/// Properties Service for Real Estate Dashboard
///
/// Fetches properties from the Smart Contact API with filtering,
/// search, and geospatial capabilities
class PropertiesService {
  static const String _baseUrl = 'https://junction.feeef.org';

  /// Fetch properties with optional filtering
  static Future<PropertiesResponse> fetchProperties({
    int page = 1,
    int limit = 10,
    String? propertyType,
    String? transactionType,
    String? wilaya,
    String? city,
    double? minPrice,
    double? maxPrice,
    double? minArea,
    double? maxArea,
    int? minRooms,
    String? condition,
    bool? featured,
    String? sortBy,
    String? sortOrder,
    double? latitude,
    double? longitude,
    double? radius,
    String? landmark,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      // Add optional filters
      if (propertyType != null) queryParams['propertyType'] = propertyType;
      if (transactionType != null)
        queryParams['transactionType'] = transactionType;
      if (wilaya != null) queryParams['wilaya'] = wilaya;
      if (city != null) queryParams['city'] = city;
      if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
      if (minArea != null) queryParams['minArea'] = minArea.toString();
      if (maxArea != null) queryParams['maxArea'] = maxArea.toString();
      if (minRooms != null) queryParams['minRooms'] = minRooms.toString();
      if (condition != null) queryParams['condition'] = condition;
      if (featured != null) queryParams['featured'] = featured.toString();
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (sortOrder != null) queryParams['sortOrder'] = sortOrder;
      if (latitude != null) queryParams['latitude'] = latitude.toString();
      if (longitude != null) queryParams['longitude'] = longitude.toString();
      if (radius != null) queryParams['radius'] = radius.toString();
      if (landmark != null) queryParams['landmark'] = landmark;

      final uri = Uri.parse(
        '$_baseUrl/api/properties/',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          return PropertiesResponse.fromJson(jsonResponse);
        } else {
          throw Exception(
            'Failed to fetch properties: ${jsonResponse['message']}',
          );
        }
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      // Return mock data for development/testing
      return _getMockPropertiesResponse();
    }
  }

  /// Fetch a single property by ID
  static Future<Property?> fetchPropertyById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/properties/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          return Property.fromJson(jsonResponse['data']);
        } else {
          throw Exception(
            'Failed to fetch property: ${jsonResponse['message']}',
          );
        }
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return null;
    }
  }

  /// Search properties by landmark and radius
  static Future<PropertiesResponse> searchByLandmark(
    String landmark,
    double radius,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/properties/radius/$landmark/$radius'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          return PropertiesResponse.fromJson(jsonResponse);
        } else {
          throw Exception(
            'Failed to search properties: ${jsonResponse['message']}',
          );
        }
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return _getMockPropertiesResponse();
    }
  }

  /// Mock properties for development/testing
  static PropertiesResponse _getMockPropertiesResponse() {
    final mockProperties = [
      Property(
        id: '1',
        title: 'فيلا فاخرة في الرياض',
        description: 'فيلا حديثة مع حديقة وموقف سيارات',
        price: 25000000,
        area: 200,
        rooms: 4,
        wilaya: 'Algiers',
        city: 'Hydra',
        propertyType: 'VILLA',
        transactionType: 'SALE',
        condition: 'EXCELLENT',
        imageUrl: '/uploads/villa1.jpg',
        images: ['/uploads/villa1.jpg', '/uploads/villa2.jpg'],
        address: 'شارع الرياض، حيدرة',
        bathrooms: 3,
        hasParking: true,
        hasGarden: true,
        hasBalcony: true,
        featured: true,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Property(
        id: '2',
        title: 'شقة مميزة في جدة',
        description: 'شقة في قلب المدينة مع إطلالة رائعة',
        price: 18000000,
        area: 120,
        rooms: 3,
        wilaya: 'Oran',
        city: 'Oran',
        propertyType: 'APARTMENT',
        transactionType: 'SALE',
        condition: 'GOOD',
        imageUrl: '/uploads/apartment1.jpg',
        images: ['/uploads/apartment1.jpg'],
        address: 'شارع الجمهورية، وهران',
        bathrooms: 2,
        hasElevator: true,
        hasBalcony: true,
        floor: 5,
        totalFloors: 8,
        featured: false,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Property(
        id: '3',
        title: 'منزل عائلي في قسنطينة',
        description: 'منزل مناسب للعائلة مع حديقة كبيرة',
        price: 15000000,
        area: 150,
        rooms: 5,
        wilaya: 'Constantine',
        city: 'Constantine',
        propertyType: 'HOUSE',
        transactionType: 'SALE',
        condition: 'FAIR',
        imageUrl: '/uploads/house1.jpg',
        images: ['/uploads/house1.jpg'],
        address: 'شارع الأمير عبد القادر',
        bathrooms: 2,
        hasGarden: true,
        hasParking: true,
        featured: false,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    return PropertiesResponse(
      properties: mockProperties,
      total: mockProperties.length,
      page: 1,
      limit: 10,
      hasMore: false,
    );
  }

  /// Get property type display name in Arabic
  static String getPropertyTypeDisplayName(String type) {
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
        return 'كراج';
      default:
        return type;
    }
  }

  /// Get transaction type display name in Arabic
  static String getTransactionTypeDisplayName(String type) {
    switch (type) {
      case 'SALE':
        return 'بيع';
      case 'RENT':
        return 'إيجار';
      default:
        return type;
    }
  }

  /// Get condition display name in Arabic
  static String getConditionDisplayName(String condition) {
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

  /// Get furnishing display name in Arabic
  static String getFurnishingDisplayName(String? furnishing) {
    switch (furnishing) {
      case 'FURNISHED':
        return 'مفروش';
      case 'SEMI_FURNISHED':
        return 'نصف مفروش';
      case 'UNFURNISHED':
        return 'غير مفروش';
      default:
        return 'غير محدد';
    }
  }
}
