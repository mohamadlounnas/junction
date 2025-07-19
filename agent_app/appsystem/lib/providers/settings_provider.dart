import 'package:flutter/foundation.dart';
import '../services/settings_service.dart';
import '../services/api_settings_service.dart';

/// Settings Provider for Smart Contact Real Estate Application
///
/// Manages application settings state using ChangeNotifier pattern.
/// Provides loading states, change tracking, and save functionality
/// with proper error handling and state management.
class SettingsProvider extends ChangeNotifier {
  AppSettings? _settings;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasChanges = false;
  String? _errorMessage;

  // Original settings for change detection
  AppSettings? _originalSettings;

  // Getters
  AppSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get hasChanges => _hasChanges;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Load settings from the API
  ///
  /// Fetches current settings and updates the provider state.
  /// Handles loading states and error conditions.
  Future<void> loadSettings() async {
    _setLoading(true);
    _clearError();

    try {
      // Try to load from API first, fallback to local service
      final apiSettings = await ApiSettingsService.getAISettings();
      final settings = AppSettings.fromJson(apiSettings);
      _updateSettings(settings);
      _originalSettings = settings
          .copyWith(); // Store original for change detection
      _hasChanges = false;
    } catch (e) {
      // Fallback to local settings service
      try {
        final settings = await SettingsService.fetchSettings();
        _updateSettings(settings);
        _originalSettings = settings.copyWith();
        _hasChanges = false;
      } catch (fallbackError) {
        _setError('Failed to load settings: $fallbackError');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Save current settings to the API
  ///
  /// Saves the current settings and updates the provider state.
  /// Handles saving states and error conditions.
  Future<bool> saveSettings() async {
    if (_settings == null || !_hasChanges) {
      return false;
    }

    _setSaving(true);
    _clearError();

    try {
      // Try to save to API first, fallback to local service
      final success = await ApiSettingsService.saveAISettings(
        _settings!.toJson(),
      );
      if (success) {
        _originalSettings = _settings!
            .copyWith(); // Update original after successful save
        _hasChanges = false;
        return true;
      } else {
        throw Exception('API save returned false');
      }
    } catch (e) {
      // Fallback to local settings service
      try {
        await SettingsService.updateSettings(_settings!);
        _originalSettings = _settings!.copyWith();
        _hasChanges = false;
        return true;
      } catch (fallbackError) {
        _setError('Failed to save settings: $fallbackError');
        return false;
      }
    } finally {
      _setSaving(false);
    }
  }

  /// Update AI threshold setting
  ///
  /// Updates the AI threshold and marks settings as changed.
  void updateAiThreshold(double value) {
    if (_settings == null) return;

    final updatedSettings = _settings!.copyWith(aiThreshold: value);
    _updateSettings(updatedSettings);
    _checkForChanges();
  }

  /// Update transaction flexibility setting
  ///
  /// Updates the transaction flexibility and marks settings as changed.
  void updateTransactionFlexibility(bool value) {
    if (_settings == null) return;

    final updatedSettings = _settings!.copyWith(
      transactionFlexibilityEnabled: value,
    );
    _updateSettings(updatedSettings);
    _checkForChanges();
  }

  /// Update default language setting
  ///
  /// Updates the default language and marks settings as changed.
  void updateDefaultLanguage(AppLanguage language) {
    if (_settings == null) return;

    final updatedSettings = _settings!.copyWith(defaultLanguage: language);
    _updateSettings(updatedSettings);
    _checkForChanges();
  }

  /// Update recommendation weight vector
  ///
  /// Updates the recommendation weight vector and marks settings as changed.
  void updateRecommendationWeightVector(List<double> weights) {
    if (_settings == null) return;

    if (!SettingsService.isValidWeightVector(weights)) {
      _setError('Invalid weight vector: must be 12 values between 0 and 1');
      return;
    }

    final updatedSettings = _settings!.copyWith(
      recommendationWeightVector: weights,
    );
    _updateSettings(updatedSettings);
    _checkForChanges();
  }

  /// Update a specific weight in the recommendation vector
  ///
  /// Updates a single weight at the specified index and marks settings as changed.
  void updateWeightAtIndex(int index, double value) {
    if (_settings == null || index < 0 || index >= 12) return;

    final newWeights = List<double>.from(_settings!.recommendationWeightVector);
    newWeights[index] = value.clamp(0.0, 1.0);

    updateRecommendationWeightVector(newWeights);
  }

  /// Reset settings to defaults
  ///
  /// Resets all settings to default values and marks as changed.
  void resetToDefaults() {
    final defaultSettings = AppSettings.defaults();
    _updateSettings(defaultSettings);
    _hasChanges = true;
    _clearError();
    notifyListeners();
  }

  /// Discard changes and revert to original settings
  ///
  /// Reverts all changes back to the original settings.
  void discardChanges() {
    if (_originalSettings != null) {
      _updateSettings(_originalSettings!);
      _hasChanges = false;
      _clearError();
      notifyListeners();
    }
  }

  /// Clear the settings cache
  ///
  /// Clears the local cache and forces a fresh load on next fetch.
  void clearCache() {
    SettingsService.clearCache();
  }

  /// Get current weight vector values
  ///
  /// Returns the current recommendation weight vector or empty list if not available.
  List<double> getCurrentWeightVector() {
    return _settings?.recommendationWeightVector ?? [];
  }

  /// Check if a specific setting has changed
  ///
  /// Compares current setting with original setting.
  bool hasSettingChanged<T>(T Function(AppSettings) getter) {
    if (_settings == null || _originalSettings == null) return false;

    final current = getter(_settings!);
    final original = getter(_originalSettings!);

    if (current is List && original is List) {
      return !listEquals(current, original);
    }

    return current != original;
  }

  /// Get AI threshold display text
  ///
  /// Returns the Arabic display text for the current AI threshold.
  String getAiThresholdDisplayText() {
    if (_settings == null) return '';
    return SettingsService.getAiThresholdDisplayText(_settings!.aiThreshold);
  }

  /// Get weight vector dimension names
  ///
  /// Returns the Arabic dimension names for the weight vector.
  List<String> getWeightVectorDimensionNames() {
    return SettingsService.getWeightVectorDimensionNames();
  }

  /// Validate current settings
  ///
  /// Validates all current settings and returns true if valid.
  bool validateSettings() {
    if (_settings == null) return false;

    if (!SettingsService.isValidAiThreshold(_settings!.aiThreshold)) {
      _setError('Invalid AI threshold: must be between 0 and 1');
      return false;
    }

    if (!SettingsService.isValidWeightVector(
      _settings!.recommendationWeightVector,
    )) {
      _setError('Invalid weight vector: must be 12 values between 0 and 1');
      return false;
    }

    return true;
  }

  // Private helper methods

  void _updateSettings(AppSettings newSettings) {
    _settings = newSettings;
    _clearError();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setSaving(bool saving) {
    _isSaving = saving;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _checkForChanges() {
    if (_settings == null || _originalSettings == null) {
      _hasChanges = false;
      return;
    }

    _hasChanges = !_settings!.isEqual(_originalSettings!);
    notifyListeners();
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }
}

/// Extension method to compare AppSettings for equality
extension AppSettingsEquality on AppSettings {
  /// Check if this AppSettings is equal to another
  ///
  /// Compares all fields including the recommendation weight vector.
  bool isEqual(AppSettings other) {
    if (aiThreshold != other.aiThreshold) return false;
    if (transactionFlexibilityEnabled != other.transactionFlexibilityEnabled)
      return false;
    if (defaultLanguage != other.defaultLanguage) return false;
    if (createdAt != other.createdAt) return false;
    if (updatedAt != other.updatedAt) return false;

    // Compare weight vectors
    if (!listEquals(
      recommendationWeightVector,
      other.recommendationWeightVector,
    )) {
      return false;
    }

    return true;
  }
}
