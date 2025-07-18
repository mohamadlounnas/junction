import 'dart:convert';
import 'package:http/http.dart' as http;

/// Statistics data model
class StatisticsData {
  final int totalContacts;
  final int totalProperties;
  final List<ContactTypeStats> contactTypeStats;
  final List<PropertyTypeStats> propertyTypeStats;
  final List<WilayaStats> wilayaStats;
  final List<PropertyStatusStats> propertyStatusStats;

  StatisticsData({
    required this.totalContacts,
    required this.totalProperties,
    required this.contactTypeStats,
    required this.propertyTypeStats,
    required this.wilayaStats,
    required this.propertyStatusStats,
  });

  factory StatisticsData.fromJson(Map<String, dynamic> json) {
    final contacts = json['contacts'] as Map<String, dynamic>;
    final properties = json['properties'] as Map<String, dynamic>;

    return StatisticsData(
      totalContacts: contacts['total'] ?? 0,
      totalProperties: properties['total'] ?? 0,
      contactTypeStats:
          (contacts['byType'] as List<dynamic>?)
              ?.map((e) => ContactTypeStats.fromJson(e))
              .toList() ??
          [],
      propertyTypeStats:
          (properties['byType'] as List<dynamic>?)
              ?.map((e) => PropertyTypeStats.fromJson(e))
              .toList() ??
          [],
      wilayaStats:
          (json['wilayas'] as List<dynamic>?)
              ?.map((e) => WilayaStats.fromJson(e))
              .toList() ??
          [],
      propertyStatusStats:
          (properties['byStatus'] as List<dynamic>?)
              ?.map((e) => PropertyStatusStats.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// Contact type statistics
class ContactTypeStats {
  final String type;
  final int count;

  ContactTypeStats({required this.type, required this.count});

  factory ContactTypeStats.fromJson(Map<String, dynamic> json) {
    return ContactTypeStats(
      type: json['type'] ?? '',
      count: json['_count']?['type'] ?? 0,
    );
  }
}

/// Property type statistics
class PropertyTypeStats {
  final String propertyType;
  final int count;

  PropertyTypeStats({required this.propertyType, required this.count});

  factory PropertyTypeStats.fromJson(Map<String, dynamic> json) {
    return PropertyTypeStats(
      propertyType: json['propertyType'] ?? '',
      count: json['_count']?['propertyType'] ?? 0,
    );
  }
}

/// Wilaya statistics
class WilayaStats {
  final String wilaya;
  final int count;

  WilayaStats({required this.wilaya, required this.count});

  factory WilayaStats.fromJson(Map<String, dynamic> json) {
    return WilayaStats(
      wilaya: json['wilaya'] ?? '',
      count: json['_count']?['wilaya'] ?? 0,
    );
  }
}

/// Property status statistics
class PropertyStatusStats {
  final String status;
  final int count;

  PropertyStatusStats({required this.status, required this.count});

  factory PropertyStatusStats.fromJson(Map<String, dynamic> json) {
    return PropertyStatusStats(
      status: json['status'] ?? '',
      count: json['_count']?['status'] ?? 0,
    );
  }
}

/// Statistics Service for Real Estate Dashboard
///
/// Fetches comprehensive statistics from the Smart Contact API
/// including contacts, properties, and market insights
class StatisticsService {
  static const String _baseUrl = 'https://junction.feeef.org';

  /// Fetch statistics from the API
  static Future<StatisticsData> fetchStatistics() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/stats'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          return StatisticsData.fromJson(jsonResponse['data']);
        } else {
          throw Exception(
            'Failed to fetch statistics: ${jsonResponse['message']}',
          );
        }
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      // Return mock data for development/testing
      return _getMockStatistics();
    }
  }

  /// Mock statistics for development/testing
  static StatisticsData _getMockStatistics() {
    return StatisticsData(
      totalContacts: 5,
      totalProperties: 6,
      contactTypeStats: [
        ContactTypeStats(type: 'BUYER', count: 2),
        ContactTypeStats(type: 'TENANT', count: 2),
        ContactTypeStats(type: 'INVESTOR', count: 1),
      ],
      propertyTypeStats: [
        PropertyTypeStats(propertyType: 'APARTMENT', count: 2),
        PropertyTypeStats(propertyType: 'VILLA', count: 1),
        PropertyTypeStats(propertyType: 'HOUSE', count: 1),
        PropertyTypeStats(propertyType: 'OFFICE', count: 1),
        PropertyTypeStats(propertyType: 'LAND', count: 1),
      ],
      wilayaStats: [
        WilayaStats(wilaya: 'Algiers', count: 3),
        WilayaStats(wilaya: 'Oran', count: 1),
        WilayaStats(wilaya: 'Constantine', count: 1),
        WilayaStats(wilaya: 'Tipaza', count: 1),
      ],
      propertyStatusStats: [PropertyStatusStats(status: 'AVAILABLE', count: 6)],
    );
  }

  /// Get contact type display name in Arabic
  static String getContactTypeDisplayName(String type) {
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
      case 'LAND':
        return 'أرض';
      default:
        return type;
    }
  }

  /// Get property status display name in Arabic
  static String getPropertyStatusDisplayName(String status) {
    switch (status) {
      case 'AVAILABLE':
        return 'متاح';
      case 'SOLD':
        return 'مباع';
      case 'RENTED':
        return 'مؤجر';
      default:
        return status;
    }
  }
}
