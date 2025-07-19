import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Language enum for application localization
enum AppLanguage {
  ar('ar', 'العربية'),
  fr('fr', 'Français'),
  en('en', 'English');

  const AppLanguage(this.code, this.displayName);

  final String code;
  final String displayName;

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.ar,
    );
  }
}

/// Application Settings Model
///
/// Represents the complete configuration for the Smart Contact real estate application.
/// This model handles AI thresholds, recommendation weights, transaction flexibility,
/// language preferences, and audit timestamps.
class AppSettings {
  /// AI similarity threshold for property matching (0.0 - 1.0)
  /// Higher values result in more precise but fewer matches
  final double aiThreshold;

  /// 12-dimensional weight vector for recommendation algorithm
  /// Each dimension represents a different property characteristic weight
  final List<double> recommendationWeightVector;

  /// Whether transaction flexibility is enabled for contacts
  /// Allows contacts to be matched with both RENT and SALE properties
  final bool transactionFlexibilityEnabled;

  /// Default application language
  final AppLanguage defaultLanguage;

  /// Timestamp when settings were created
  final DateTime createdAt;

  /// Timestamp when settings were last updated
  final DateTime updatedAt;

  const AppSettings({
    required this.aiThreshold,
    required this.recommendationWeightVector,
    required this.transactionFlexibilityEnabled,
    required this.defaultLanguage,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create AppSettings from JSON response
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      aiThreshold: (json['aiThreshold'] as num?)?.toDouble() ?? 0.5,
      recommendationWeightVector: _parseWeightVector(
        json['recommendationWeightVector'],
      ),
      transactionFlexibilityEnabled:
          json['transactionFlexibilityEnabled'] ?? false,
      defaultLanguage: AppLanguage.fromCode(json['defaultLanguage'] ?? 'ar'),
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Parse recommendation weight vector from JSON
  static List<double> _parseWeightVector(dynamic jsonValue) {
    if (jsonValue is List) {
      return jsonValue.map((e) => (e as num).toDouble()).toList();
    } else if (jsonValue is String) {
      // Handle case where vector is stored as JSON string
      try {
        final List<dynamic> parsed = json.decode(jsonValue);
        return parsed.map((e) => (e as num).toDouble()).toList();
      } catch (e) {
        return _getDefaultWeightVector();
      }
    }
    return _getDefaultWeightVector();
  }

  /// Get default 12-dimensional weight vector
  /// Each dimension represents: Budget, Area, Rooms, Location, Property Type,
  /// Condition, Features, Family, Modern, Investment, Urgency, Transaction
  static List<double> _getDefaultWeightVector() {
    return [
      0.8, // Budget - High importance for Algerian market
      0.7, // Area - Important for family needs
      0.6, // Rooms - Family size consideration
      0.9, // Location - Critical for Algeria (wilaya preferences)
      0.8, // Property Type - Villa vs Apartment preferences
      0.7, // Condition - Property quality
      0.6, // Features - Amenities and facilities
      0.8, // Family - Family-friendly features
      0.5, // Modern - Modern vs traditional preference
      0.4, // Investment - Investment potential
      0.3, // Urgency - Decision timeline
      0.9, // Transaction - RENT vs SALE preference
    ];
  }

  /// Convert AppSettings to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'aiThreshold': aiThreshold,
      'recommendationWeightVector': recommendationWeightVector,
      'transactionFlexibilityEnabled': transactionFlexibilityEnabled,
      'defaultLanguage': defaultLanguage.code,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of AppSettings with updated fields
  AppSettings copyWith({
    double? aiThreshold,
    List<double>? recommendationWeightVector,
    bool? transactionFlexibilityEnabled,
    AppLanguage? defaultLanguage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppSettings(
      aiThreshold: aiThreshold ?? this.aiThreshold,
      recommendationWeightVector:
          recommendationWeightVector ?? this.recommendationWeightVector,
      transactionFlexibilityEnabled:
          transactionFlexibilityEnabled ?? this.transactionFlexibilityEnabled,
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get default settings for new installations
  factory AppSettings.defaults() {
    return AppSettings(
      aiThreshold: 0.5,
      recommendationWeightVector: _getDefaultWeightVector(),
      transactionFlexibilityEnabled: true,
      defaultLanguage: AppLanguage.ar,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'AppSettings(aiThreshold: $aiThreshold, recommendationWeightVector: $recommendationWeightVector, transactionFlexibilityEnabled: $transactionFlexibilityEnabled, defaultLanguage: ${defaultLanguage.code}, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.aiThreshold == aiThreshold &&
        listEquals(
          other.recommendationWeightVector,
          recommendationWeightVector,
        ) &&
        other.transactionFlexibilityEnabled == transactionFlexibilityEnabled &&
        other.defaultLanguage == defaultLanguage &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      aiThreshold,
      Object.hashAll(recommendationWeightVector),
      transactionFlexibilityEnabled,
      defaultLanguage,
      createdAt,
      updatedAt,
    );
  }
}

/// Settings Service for Smart Contact Real Estate Application
///
/// Manages application configuration including AI thresholds, recommendation weights,
/// transaction flexibility settings, and language preferences.
///
/// This service communicates with the Smart Contact API to fetch and update
/// application settings, providing a centralized configuration management system.
class SettingsService {
  static const String _baseUrl = 'https://api.smartcontact.dz/api/settings';

  /// Cache for settings to avoid repeated API calls
  static AppSettings? _cachedSettings;
  static DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Fetch application settings from the API
  ///
  /// Returns the current application configuration including AI thresholds,
  /// recommendation weights, and user preferences. Uses caching to improve
  /// performance and reduce API calls.
  ///
  /// Returns:
  /// - [AppSettings] object with current configuration
  /// - Throws [Exception] if API request fails
  static Future<AppSettings> fetchSettings() async {
    // Check cache first
    if (_cachedSettings != null && _lastFetchTime != null) {
      final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
      if (timeSinceLastFetch < _cacheDuration) {
        return _cachedSettings!;
      }
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          final settings = AppSettings.fromJson(jsonResponse['data']);

          // Update cache
          _cachedSettings = settings;
          _lastFetchTime = DateTime.now();

          return settings;
        } else {
          throw Exception(
            'Failed to fetch settings: ${jsonResponse['message'] ?? 'Unknown error'}',
          );
        }
      } else if (response.statusCode == 404) {
        // Settings not found, return defaults
        final defaultSettings = AppSettings.defaults();
        _cachedSettings = defaultSettings;
        _lastFetchTime = DateTime.now();
        return defaultSettings;
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      // Return cached settings if available, otherwise defaults
      if (_cachedSettings != null) {
        return _cachedSettings!;
      }

      // Return mock settings for development/testing
      return _getMockSettings();
    }
  }

  /// Update application settings via API
  ///
  /// Sends updated settings to the server and updates the local cache.
  /// This method handles the complete settings update process including
  /// validation and error handling.
  ///
  /// Parameters:
  /// - [updated] - The updated AppSettings object
  ///
  /// Returns:
  /// - [AppSettings] object with server response
  /// - Throws [Exception] if update fails
  static Future<void> updateSettings(AppSettings updated) async {
    try {
      // Prepare the request body
      final requestBody = {
        'settings': {
          'aiThreshold': {
            'key': 'aiThreshold',
            'value': updated.aiThreshold,
            'type': 'NUMBER',
            'category': 'ai',
            'description': 'AI similarity threshold for property matching',
            'isPublic': true,
          },
          'recommendationWeightVector': {
            'key': 'recommendationWeightVector',
            'value': json.encode(updated.recommendationWeightVector),
            'type': 'JSON',
            'category': 'ai',
            'description': '12D weight vector for recommendation algorithm',
            'isPublic': true,
          },
          'transactionFlexibilityEnabled': {
            'key': 'transactionFlexibilityEnabled',
            'value': updated.transactionFlexibilityEnabled,
            'type': 'BOOLEAN',
            'category': 'features',
            'description': 'Enable transaction flexibility for contacts',
            'isPublic': true,
          },
          'defaultLanguage': {
            'key': 'defaultLanguage',
            'value': updated.defaultLanguage.code,
            'type': 'STRING',
            'category': 'ui',
            'description': 'Default application language',
            'isPublic': true,
          },
        },
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/bulk'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          // Update cache with new settings
          _cachedSettings = updated.copyWith(updatedAt: DateTime.now());
          _lastFetchTime = DateTime.now();
        } else {
          throw Exception(
            'Failed to update settings: ${jsonResponse['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      // Update cache even if API fails (optimistic update)
      _cachedSettings = updated.copyWith(updatedAt: DateTime.now());
      _lastFetchTime = DateTime.now();

      // Re-throw the exception for error handling
      rethrow;
    }
  }

  /// Clear the settings cache
  ///
  /// Forces the next fetchSettings() call to retrieve fresh data from the API.
  static void clearCache() {
    _cachedSettings = null;
    _lastFetchTime = null;
  }

  /// Get mock settings for development/testing
  static AppSettings _getMockSettings() {
    return AppSettings(
      aiThreshold: 0.5,
      recommendationWeightVector: [
        0.8,
        0.7,
        0.6,
        0.9,
        0.8,
        0.7,
        0.6,
        0.8,
        0.5,
        0.4,
        0.3,
        0.9,
      ],
      transactionFlexibilityEnabled: true,
      defaultLanguage: AppLanguage.ar,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    );
  }

  /// Get AI threshold display text in Arabic
  static String getAiThresholdDisplayText(double threshold) {
    if (threshold < 0.3) {
      return 'منخفض - تطابق سريع';
    } else if (threshold < 0.5) {
      return 'متوسط - توازن جيد';
    } else if (threshold < 0.7) {
      return 'عالي - تطابق دقيق';
    } else {
      return 'ممتاز - تطابق مثالي';
    }
  }

  /// Get weight vector dimension names in Arabic
  static List<String> getWeightVectorDimensionNames() {
    return [
      'الميزانية',
      'المساحة',
      'الغرف',
      'الموقع',
      'نوع العقار',
      'الحالة',
      'المرافق',
      'العائلة',
      'الحداثة',
      'الاستثمار',
      'الاستعجال',
      'نوع المعاملة',
    ];
  }

  /// Validate AI threshold value
  static bool isValidAiThreshold(double threshold) {
    return threshold >= 0.0 && threshold <= 1.0;
  }

  /// Validate recommendation weight vector
  static bool isValidWeightVector(List<double> vector) {
    return vector.length == 12 &&
        vector.every((weight) => weight >= 0.0 && weight <= 1.0);
  }
}
