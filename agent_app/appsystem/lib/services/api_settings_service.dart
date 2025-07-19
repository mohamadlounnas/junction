import 'dart:convert';
import 'package:http/http.dart' as http;

/// Setting model for API communication
class ApiSetting {
  final String key;
  final dynamic value;
  final String type;
  final String category;
  final String? description;
  final bool? isPublic;

  ApiSetting({
    required this.key,
    required this.value,
    required this.type,
    required this.category,
    this.description,
    this.isPublic,
  });

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
      'type': type,
      'category': category,
      if (description != null) 'description': description,
      if (isPublic != null) 'isPublic': isPublic,
    };
  }

  factory ApiSetting.fromJson(Map<String, dynamic> json) {
    return ApiSetting(
      key: json['key'] as String,
      value: json['value'],
      type: json['type'] as String,
      category: json['category'] as String,
      description: json['description'] as String?,
      isPublic: json['isPublic'] as bool?,
    );
  }
}

/// API Settings Service for Smart Contact Real Estate Application
///
/// Handles communication with the settings API endpoints based on the
/// actual API specification structure with key-value pairs and categories.
class ApiSettingsService {
  static const String _baseUrl = 'https://api.smartcontact.dz/api';
  static const Duration _timeout = Duration(seconds: 30);

  // Cache for settings
  static Map<String, dynamic>? _cachedSettings;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheExpiration = Duration(minutes: 5);

  /// Get all settings from the API
  static Future<Map<String, dynamic>> getAllSettings() async {
    // Check cache first
    if (_cachedSettings != null && _cacheTimestamp != null) {
      final cacheAge = DateTime.now().difference(_cacheTimestamp!);
      if (cacheAge < _cacheExpiration) {
        return _cachedSettings!;
      }
    }

    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/settings/'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _cachedSettings = data;
        _cacheTimestamp = DateTime.now();
        return data;
      } else {
        throw Exception('Failed to load settings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get settings by category
  static Future<List<ApiSetting>> getSettingsByCategory(String category) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/settings/category/$category'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final settingsList = data['data'] as List? ?? [];
        return settingsList.map((json) => ApiSetting.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load settings for category $category: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get a specific setting by key
  static Future<ApiSetting?> getSettingByKey(String key) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/settings/$key'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiSetting.fromJson(data['data']);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load setting $key: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Create or update a setting
  static Future<bool> createOrUpdateSetting(ApiSetting setting) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/settings/'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(setting.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Clear cache to force refresh
        _cachedSettings = null;
        _cacheTimestamp = null;
        return true;
      } else {
        throw Exception('Failed to save setting: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Update a specific setting by key
  static Future<bool> updateSettingByKey(String key, ApiSetting setting) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/settings/$key'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(setting.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        // Clear cache to force refresh
        _cachedSettings = null;
        _cacheTimestamp = null;
        return true;
      } else {
        throw Exception(
          'Failed to update setting $key: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Bulk update multiple settings
  static Future<bool> bulkUpdateSettings(List<ApiSetting> settings) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/settings/bulk'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({
              'settings': settings.map((s) => s.toJson()).toList(),
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        // Clear cache to force refresh
        _cachedSettings = null;
        _cacheTimestamp = null;
        return true;
      } else {
        throw Exception(
          'Failed to bulk update settings: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Delete a setting by key
  static Future<bool> deleteSettingByKey(String key) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/settings/$key'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        // Clear cache to force refresh
        _cachedSettings = null;
        _cacheTimestamp = null;
        return true;
      } else {
        throw Exception(
          'Failed to delete setting $key: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Reset all settings to default values
  static Future<bool> resetSettings() async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/settings/reset'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        // Clear cache to force refresh
        _cachedSettings = null;
        _cacheTimestamp = null;
        return true;
      } else {
        throw Exception('Failed to reset settings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Clear settings cache
  static Future<bool> clearCache() async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/settings/clear-cache'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        // Clear local cache
        _cachedSettings = null;
        _cacheTimestamp = null;
        return true;
      } else {
        throw Exception('Failed to clear cache: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Clear local cache
  static void clearLocalCache() {
    _cachedSettings = null;
    _cacheTimestamp = null;
  }

  /// Convert AppSettings to API settings format
  static List<ApiSetting> convertAppSettingsToApiSettings(
    Map<String, dynamic> appSettings,
  ) {
    final List<ApiSetting> apiSettings = [];

    // AI Threshold
    apiSettings.add(
      ApiSetting(
        key: 'ai_threshold',
        value: appSettings['aiThreshold'],
        type: 'NUMBER',
        category: 'ai',
        description: 'AI similarity threshold for property matching',
        isPublic: true,
      ),
    );

    // Transaction Flexibility
    apiSettings.add(
      ApiSetting(
        key: 'transaction_flexibility',
        value: appSettings['transactionFlexibilityEnabled'],
        type: 'BOOLEAN',
        category: 'ai',
        description: 'Allow contacts to match with multiple transaction types',
        isPublic: true,
      ),
    );

    // Default Language
    apiSettings.add(
      ApiSetting(
        key: 'default_language',
        value: appSettings['defaultLanguage'],
        type: 'STRING',
        category: 'ui',
        description: 'Default application language',
        isPublic: true,
      ),
    );

    // Recommendation Weight Vector
    apiSettings.add(
      ApiSetting(
        key: 'recommendation_weights',
        value: json.encode(appSettings['recommendationWeightVector']),
        type: 'JSON',
        category: 'ai',
        description: '12D recommendation weight vector',
        isPublic: false,
      ),
    );

    return apiSettings;
  }

  /// Convert API settings to AppSettings format
  static Map<String, dynamic> convertApiSettingsToAppSettings(
    List<ApiSetting> apiSettings,
  ) {
    final Map<String, dynamic> appSettings = {
      'aiThreshold': 0.5,
      'transactionFlexibilityEnabled': false,
      'defaultLanguage': 'ar',
      'recommendationWeightVector': List.filled(12, 0.5),
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    for (final setting in apiSettings) {
      switch (setting.key) {
        case 'ai_threshold':
          appSettings['aiThreshold'] = (setting.value as num).toDouble();
          break;
        case 'transaction_flexibility':
          appSettings['transactionFlexibilityEnabled'] = setting.value as bool;
          break;
        case 'default_language':
          appSettings['defaultLanguage'] = setting.value as String;
          break;
        case 'recommendation_weights':
          try {
            final weights = json.decode(setting.value as String) as List;
            appSettings['recommendationWeightVector'] = weights.cast<double>();
          } catch (e) {
            // Use default weights if parsing fails
            appSettings['recommendationWeightVector'] = List.filled(12, 0.5);
          }
          break;
      }
    }

    return appSettings;
  }

  /// Get AI-specific settings
  static Future<Map<String, dynamic>> getAISettings() async {
    try {
      final aiSettings = await getSettingsByCategory('ai');
      return convertApiSettingsToAppSettings(aiSettings);
    } catch (e) {
      // Return default AI settings if API fails
      return {
        'aiThreshold': 0.5,
        'transactionFlexibilityEnabled': false,
        'recommendationWeightVector': List.filled(12, 0.5),
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Save AI-specific settings
  static Future<bool> saveAISettings(Map<String, dynamic> appSettings) async {
    try {
      final apiSettings = convertAppSettingsToApiSettings(appSettings);
      return await bulkUpdateSettings(apiSettings);
    } catch (e) {
      throw Exception('Failed to save AI settings: $e');
    }
  }

  /// Get UI-specific settings
  static Future<Map<String, dynamic>> getUISettings() async {
    try {
      final uiSettings = await getSettingsByCategory('ui');
      return convertApiSettingsToAppSettings(uiSettings);
    } catch (e) {
      // Return default UI settings if API fails
      return {
        'defaultLanguage': 'ar',
        'darkMode': true,
        'notifications': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Save UI-specific settings
  static Future<bool> saveUISettings(Map<String, dynamic> uiSettings) async {
    try {
      final apiSettings = <ApiSetting>[];

      // Default Language
      apiSettings.add(
        ApiSetting(
          key: 'default_language',
          value: uiSettings['defaultLanguage'] ?? 'ar',
          type: 'STRING',
          category: 'ui',
          description: 'Default application language',
          isPublic: true,
        ),
      );

      // Dark Mode
      apiSettings.add(
        ApiSetting(
          key: 'dark_mode',
          value: uiSettings['darkMode'] ?? true,
          type: 'BOOLEAN',
          category: 'ui',
          description: 'Dark mode preference',
          isPublic: true,
        ),
      );

      // Notifications
      apiSettings.add(
        ApiSetting(
          key: 'notifications',
          value: uiSettings['notifications'] ?? true,
          type: 'BOOLEAN',
          category: 'ui',
          description: 'Push notifications preference',
          isPublic: true,
        ),
      );

      return await bulkUpdateSettings(apiSettings);
    } catch (e) {
      throw Exception('Failed to save UI settings: $e');
    }
  }
}
