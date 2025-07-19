# Settings Service Documentation

## Overview

The `SettingsService` provides a comprehensive configuration management system for the Smart Contact real estate application. It handles AI thresholds, recommendation weights, transaction flexibility settings, and language preferences through a RESTful API.

## Features

- **AI Threshold Management**: Configure similarity thresholds for property matching
- **Recommendation Weights**: 12-dimensional weight vector for the recommendation algorithm
- **Transaction Flexibility**: Enable/disable multi-transaction type matching
- **Language Preferences**: Support for Arabic, French, and English
- **Caching**: Built-in caching to improve performance
- **Error Handling**: Comprehensive error handling with fallback options
- **Validation**: Input validation for all settings

## Quick Start

### 1. Basic Usage

```dart
import 'package:appsystem/services/settings_service.dart';

// Fetch current settings
final settings = await SettingsService.fetchSettings();

// Update AI threshold
final updatedSettings = settings.copyWith(aiThreshold: 0.7);
await SettingsService.updateSettings(updatedSettings);
```

### 2. Using with State Management

```dart
class SettingsProvider extends ChangeNotifier {
  AppSettings? _settings;
  
  Future<void> loadSettings() async {
    _settings = await SettingsService.fetchSettings();
    notifyListeners();
  }
  
  Future<void> updateSettings(AppSettings newSettings) async {
    await SettingsService.updateSettings(newSettings);
    _settings = newSettings;
    notifyListeners();
  }
}
```

## API Reference

### AppSettings Class

#### Properties

- `aiThreshold` (double): AI similarity threshold (0.0 - 1.0)
- `recommendationWeightVector` (List<double>): 12D weight vector for recommendations
- `transactionFlexibilityEnabled` (bool): Enable multi-transaction matching
- `defaultLanguage` (AppLanguage): Default application language
- `createdAt` (DateTime): Settings creation timestamp
- `updatedAt` (DateTime): Last update timestamp

#### Methods

- `fromJson(Map<String, dynamic>)`: Create from JSON response
- `toJson()`: Convert to JSON for API requests
- `copyWith(...)`: Create copy with updated fields
- `defaults()`: Get default settings

### SettingsService Class

#### Static Methods

- `fetchSettings()`: Fetch settings from API
- `updateSettings(AppSettings)`: Update settings via API
- `clearCache()`: Clear local cache
- `isValidAiThreshold(double)`: Validate AI threshold
- `isValidWeightVector(List<double>)`: Validate weight vector

#### Utility Methods

- `getAiThresholdDisplayText(double)`: Get Arabic display text
- `getWeightVectorDimensionNames()`: Get Arabic dimension names

### AppLanguage Enum

#### Values

- `ar`: Arabic (العربية)
- `fr`: French (Français)
- `en`: English (English)

#### Methods

- `fromCode(String)`: Create from language code
- `code`: Get language code
- `displayName`: Get display name

## Configuration Details

### AI Threshold

The AI threshold controls the similarity score required for property matching:

- **0.0 - 0.3**: Low threshold (more matches, lower quality)
- **0.3 - 0.5**: Medium threshold (balanced approach)
- **0.5 - 0.7**: High threshold (fewer matches, higher quality)
- **0.7 - 1.0**: Very high threshold (premium matches only)

### Recommendation Weight Vector

The 12-dimensional weight vector controls the importance of different property characteristics:

1. **Budget** (الميزانية): Price sensitivity and range
2. **Area** (المساحة): Size requirements importance
3. **Rooms** (الغرف): Room count preference strength
4. **Location** (الموقع): Geographic preference (Algeria-optimized)
5. **Property Type** (نوع العقار): Villa, apartment, house preference
6. **Condition** (الحالة): Property condition importance
7. **Features** (المرافق): Amenities and facilities importance
8. **Family** (العائلة): Family-friendliness needs
9. **Modern** (الحداثة): Modernity vs traditional preference
10. **Investment** (الاستثمار): Investment potential interest
11. **Urgency** (الاستعجال): Decision timeline pressure
12. **Transaction** (نوع المعاملة): RENT vs SALE preference

### Transaction Flexibility

When enabled, contacts can be matched with properties of multiple transaction types (RENT and SALE). This is particularly useful for:

- Investors open to both buying and renting
- Families considering both options
- Flexible buyers/tenants

## Error Handling

The service includes comprehensive error handling:

```dart
try {
  final settings = await SettingsService.fetchSettings();
  // Use settings
} catch (e) {
  // Handle error - service returns defaults or cached settings
  print('Error loading settings: $e');
}
```

### Fallback Behavior

- **API Unavailable**: Returns cached settings or defaults
- **Network Error**: Uses cached settings if available
- **Invalid Data**: Falls back to default values
- **404 Response**: Creates default settings

## Caching

The service implements intelligent caching:

- **Cache Duration**: 5 minutes
- **Automatic Refresh**: On next fetch after cache expires
- **Manual Clear**: `SettingsService.clearCache()`
- **Optimistic Updates**: Cache updated immediately on changes

## API Endpoints

### Base URL
```
https://api.smartcontact.dz/api/settings
```

### Endpoints

- `GET /`: Fetch all settings
- `POST /bulk`: Update multiple settings
- `GET /{key}`: Get specific setting
- `PUT /{key}`: Update specific setting
- `DELETE /{key}`: Delete setting
- `POST /reset`: Reset to defaults
- `POST /clear-cache`: Clear server cache

### Request Format

```json
{
  "settings": {
    "aiThreshold": {
      "key": "aiThreshold",
      "value": 0.5,
      "type": "NUMBER",
      "category": "ai",
      "description": "AI similarity threshold",
      "isPublic": true
    }
  }
}
```

## Integration Examples

### 1. Settings Page Integration

```dart
class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AppSettings? _settings;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final settings = await SettingsService.fetchSettings();
    setState(() => _settings = settings);
  }
  
  Future<void> _updateAiThreshold(double value) async {
    if (_settings == null) return;
    
    final updated = _settings!.copyWith(aiThreshold: value);
    await SettingsService.updateSettings(updated);
    setState(() => _settings = updated);
  }
}
```

### 2. Provider Pattern Integration

```dart
class SettingsProvider extends ChangeNotifier {
  AppSettings? _settings;
  bool _isLoading = false;
  
  AppSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  
  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _settings = await SettingsService.fetchSettings();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> updateSettings(AppSettings newSettings) async {
    await SettingsService.updateSettings(newSettings);
    _settings = newSettings;
    notifyListeners();
  }
}
```

### 3. Riverpod Integration

```dart
final settingsProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<AppSettings>>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<AsyncValue<AppSettings>> {
  SettingsNotifier() : super(const AsyncValue.loading()) {
    loadSettings();
  }
  
  Future<void> loadSettings() async {
    state = const AsyncValue.loading();
    try {
      final settings = await SettingsService.fetchSettings();
      state = AsyncValue.data(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> updateSettings(AppSettings newSettings) async {
    await SettingsService.updateSettings(newSettings);
    state = AsyncValue.data(newSettings);
  }
}
```

## Testing

### Unit Tests

```dart
void main() {
  group('AppSettings', () {
    test('should create from JSON', () {
      final json = {
        'aiThreshold': 0.5,
        'recommendationWeightVector': [0.8, 0.7, 0.6, 0.9, 0.8, 0.7, 0.6, 0.8, 0.5, 0.4, 0.3, 0.9],
        'transactionFlexibilityEnabled': true,
        'defaultLanguage': 'ar',
        'createdAt': '2024-01-01T00:00:00Z',
        'updatedAt': '2024-01-01T00:00:00Z',
      };
      
      final settings = AppSettings.fromJson(json);
      
      expect(settings.aiThreshold, 0.5);
      expect(settings.transactionFlexibilityEnabled, true);
      expect(settings.defaultLanguage, AppLanguage.ar);
    });
  });
}
```

### Mock Testing

```dart
class MockSettingsService {
  static Future<AppSettings> fetchSettings() async {
    return AppSettings.defaults();
  }
  
  static Future<void> updateSettings(AppSettings settings) async {
    // Mock implementation
  }
}
```

## Best Practices

1. **Always handle errors**: Wrap API calls in try-catch blocks
2. **Use caching**: Leverage the built-in caching for better performance
3. **Validate inputs**: Use validation methods before updating settings
4. **Provide feedback**: Show loading states and success/error messages
5. **Optimistic updates**: Update UI immediately, handle errors gracefully
6. **Test thoroughly**: Include unit tests and integration tests

## Troubleshooting

### Common Issues

1. **Settings not loading**: Check network connectivity and API availability
2. **Cache issues**: Clear cache with `SettingsService.clearCache()`
3. **Validation errors**: Ensure weight vector has exactly 12 values (0.0-1.0)
4. **Language not updating**: Verify language code is valid (ar, fr, en)

### Debug Information

Enable debug logging to troubleshoot issues:

```dart
// Add to your app initialization
if (kDebugMode) {
  print('Settings cache status: ${SettingsService._cachedSettings != null}');
}
```

## Contributing

When contributing to the settings service:

1. Follow the existing code style and patterns
2. Add comprehensive documentation
3. Include unit tests for new features
4. Update this README for any API changes
5. Test with the actual API endpoints

## License

This settings service is part of the Smart Contact real estate application and follows the same licensing terms. 