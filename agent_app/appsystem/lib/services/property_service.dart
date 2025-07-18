import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart'; // Added for Color

/// Property data model with JSON serialization
class Property {
  final String id;
  final String title;
  final String titleEn;
  final String price;
  final String currency;
  final LatLng location;
  final PropertyType type;
  final int bedrooms;
  final int bathrooms;
  final double area;
  final double rating;
  final String imageUrl;
  final String? wilaya;
  final String? city;
  final String? description;
  final String? transactionType;
  final String? condition;
  final List<String>? images;
  final Map<String, dynamic>? additionalData;

  Property({
    required this.id,
    required this.title,
    required this.titleEn,
    required this.price,
    required this.currency,
    required this.location,
    required this.type,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    required this.rating,
    required this.imageUrl,
    this.wilaya,
    this.city,
    this.description,
    this.transactionType,
    this.condition,
    this.images,
    this.additionalData,
  });

  /// Create Property from JSON data
  factory Property.fromJson(Map<String, dynamic> json) {
    try {
      // Extract coordinates
      final latitude = json['latitude'];
      final longitude = json['longitude'];

      if (latitude == null || longitude == null) {
        throw Exception(
          'Property missing coordinates: lat=$latitude, lng=$longitude',
        );
      }

      // Handle different property type formats
      String propertyTypeStr = json['propertyType'] ?? 'APARTMENT';
      if (propertyTypeStr is String) {
        propertyTypeStr = propertyTypeStr.toUpperCase();
      }

      // Handle bathrooms field - might be missing or named differently
      int bathrooms = 0;
      if (json['bathrooms'] != null) {
        bathrooms = (json['bathrooms'] is int)
            ? json['bathrooms']
            : int.tryParse(json['bathrooms'].toString()) ?? 0;
      }

      // Format price
      final rawPrice = json['price'] ?? 0;
      String formattedPrice;
      if (rawPrice is num) {
        if (rawPrice >= 1000000) {
          formattedPrice = '${(rawPrice / 1000000).toStringAsFixed(1)}M';
        } else if (rawPrice >= 1000) {
          formattedPrice = '${(rawPrice / 1000).toStringAsFixed(0)}K';
        } else {
          formattedPrice = rawPrice.toStringAsFixed(0);
        }
      } else {
        formattedPrice = rawPrice.toString();
      }

      // Convert property type
      PropertyType propertyType;
      switch (propertyTypeStr) {
        case 'APARTMENT':
          propertyType = PropertyType.apartment;
          break;
        case 'VILLA':
          propertyType = PropertyType.villa;
          break;
        case 'OFFICE':
          propertyType = PropertyType.office;
          break;
        case 'LAND':
          propertyType = PropertyType.land;
          break;
        case 'WAREHOUSE':
          propertyType = PropertyType.warehouse;
          break;
        case 'HOUSE':
          propertyType = PropertyType.villa; // Map HOUSE to villa
          break;
        case 'SHOP':
          propertyType = PropertyType.office; // Map SHOP to office
          break;
        case 'GARAGE':
          propertyType = PropertyType.warehouse; // Map GARAGE to warehouse
          break;
        default:
          propertyType = PropertyType.apartment;
      }

      // Handle images
      List<String> imageList = [];
      if (json['image_url'] != null) {
        imageList.add(json['image_url']);
      }
      if (json['images'] != null && json['images'] is List) {
        imageList.addAll((json['images'] as List).cast<String>());
      }

      return Property(
        id: json['id']?.toString() ?? '',
        title: json['title'] ?? '',
        titleEn: json['title'] ?? '', // Use title as fallback
        price: formattedPrice,
        currency: 'دج', // Algerian Dinar
        location: LatLng(
          (latitude is num)
              ? latitude.toDouble()
              : double.tryParse(latitude.toString()) ?? 0,
          (longitude is num)
              ? longitude.toDouble()
              : double.tryParse(longitude.toString()) ?? 0,
        ),
        type: propertyType,
        bedrooms: json['rooms'] ?? 0,
        bathrooms: bathrooms,
        area: (json['area'] ?? 0).toDouble(),
        rating: 4.5, // Default rating
        imageUrl: imageList.isNotEmpty
            ? imageList.first
            : _getDefaultImageUrl(),
        wilaya: json['wilaya'],
        city: json['city'],
        description: json['description'],
        transactionType: json['transactionType'],
        condition: json['condition'],
        images: imageList.isNotEmpty ? imageList : null,
        additionalData: json,
      );
    } catch (e) {
      throw Exception('Failed to parse property JSON: $e');
    }
  }

  /// Convert Property to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'titleEn': titleEn,
      'price': price,
      'currency': currency,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'propertyType': type.name.toUpperCase(),
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area': area,
      'rating': rating,
      'imageUrl': imageUrl,
      'wilaya': wilaya,
      'city': city,
      'description': description,
      'transactionType': transactionType,
      'condition': condition,
      'images': images,
    };
  }

  /// Get default image URL for properties without images
  static String _getDefaultImageUrl() {
    return 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=400';
  }

  /// Create a copy of this property with updated fields
  Property copyWith({
    String? id,
    String? title,
    String? titleEn,
    String? price,
    String? currency,
    LatLng? location,
    PropertyType? type,
    int? bedrooms,
    int? bathrooms,
    double? area,
    double? rating,
    String? imageUrl,
    String? wilaya,
    String? city,
    String? description,
    String? transactionType,
    String? condition,
    List<String>? images,
    Map<String, dynamic>? additionalData,
  }) {
    return Property(
      id: id ?? this.id,
      title: title ?? this.title,
      titleEn: titleEn ?? this.titleEn,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      location: location ?? this.location,
      type: type ?? this.type,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      area: area ?? this.area,
      rating: rating ?? this.rating,
      imageUrl: imageUrl ?? this.imageUrl,
      wilaya: wilaya ?? this.wilaya,
      city: city ?? this.city,
      description: description ?? this.description,
      transactionType: transactionType ?? this.transactionType,
      condition: condition ?? this.condition,
      images: images ?? this.images,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  @override
  String toString() {
    return 'Property(id: $id, title: $title, location: $location, price: $price)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Property && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Property types enum
enum PropertyType { apartment, villa, office, land, warehouse }

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
      print('PropertyService: Network error: $e');
      if (e.toString().contains('timeout')) {
        throw Exception(
          'Network timeout - please check your internet connection and try again',
        );
      } else if (e.toString().contains('SocketException')) {
        throw Exception(
          'Network connection failed - please check your internet connection',
        );
      } else if (e.toString().contains('HttpException')) {
        throw Exception('Server connection error - please try again later');
      } else {
        throw Exception('Network error: $e');
      }
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
    List<File>? images,
  }) async {
    try {
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/properties/'),
      );

      // Add form fields
      propertyData.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Add images if provided
      if (images != null && images.isNotEmpty) {
        for (int i = 0; i < images.length; i++) {
          final file = await http.MultipartFile.fromPath(
            'imageFiles',
            images[i].path,
          );
          request.files.add(file);
        }
      }

      // Send request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
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
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
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
    List<File>? images,
  }) async {
    try {
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$_baseUrl/api/properties/$id'),
      );

      // Add form fields
      propertyData.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Add images if provided
      if (images != null && images.isNotEmpty) {
        for (int i = 0; i < images.length; i++) {
          final file = await http.MultipartFile.fromPath(
            'imageFiles',
            images[i].path,
          );
          request.files.add(file);
        }
      }

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
