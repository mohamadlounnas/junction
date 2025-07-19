import 'package:flutter/material.dart';
import 'settings_service.dart';

/// Example usage of AppSettings and SettingsService
///
/// This file demonstrates how to integrate the settings service
/// into your Flutter application with proper error handling,
/// loading states, and user feedback.
class SettingsUsageExample extends StatefulWidget {
  const SettingsUsageExample({super.key});

  @override
  State<SettingsUsageExample> createState() => _SettingsUsageExampleState();
}

class _SettingsUsageExampleState extends State<SettingsUsageExample> {
  AppSettings? _settings;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Load settings from the API
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final settings = await SettingsService.fetchSettings();
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load settings: $e';
        _isLoading = false;
      });
    }
  }

  /// Update AI threshold setting
  Future<void> _updateAiThreshold(double newThreshold) async {
    if (_settings == null) return;

    final updatedSettings = _settings!.copyWith(aiThreshold: newThreshold);

    try {
      await SettingsService.updateSettings(updatedSettings);
      setState(() {
        _settings = updatedSettings;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'AI threshold updated to ${(newThreshold * 100).round()}%',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update AI threshold: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Update transaction flexibility setting
  Future<void> _updateTransactionFlexibility(bool enabled) async {
    if (_settings == null) return;

    final updatedSettings = _settings!.copyWith(
      transactionFlexibilityEnabled: enabled,
    );

    try {
      await SettingsService.updateSettings(updatedSettings);
      setState(() {
        _settings = updatedSettings;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled
                  ? 'Transaction flexibility enabled'
                  : 'Transaction flexibility disabled',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update transaction flexibility: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Update default language setting
  Future<void> _updateDefaultLanguage(AppLanguage language) async {
    if (_settings == null) return;

    final updatedSettings = _settings!.copyWith(defaultLanguage: language);

    try {
      await SettingsService.updateSettings(updatedSettings);
      setState(() {
        _settings = updatedSettings;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Default language updated to ${language.displayName}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update language: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Update recommendation weight vector
  Future<void> _updateWeightVector(List<double> newWeights) async {
    if (_settings == null) return;

    if (!SettingsService.isValidWeightVector(newWeights)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Invalid weight vector: must be 12 values between 0 and 1',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final updatedSettings = _settings!.copyWith(
      recommendationWeightVector: newWeights,
    );

    try {
      await SettingsService.updateSettings(updatedSettings);
      setState(() {
        _settings = updatedSettings;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recommendation weights updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update weights: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSettings,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_settings == null) {
      return const Center(child: Text('No settings available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Threshold Section
          _buildAiThresholdSection(),
          const SizedBox(height: 24),

          // Transaction Flexibility Section
          _buildTransactionFlexibilitySection(),
          const SizedBox(height: 24),

          // Language Section
          _buildLanguageSection(),
          const SizedBox(height: 24),

          // Weight Vector Section
          _buildWeightVectorSection(),
          const SizedBox(height: 24),

          // Settings Info
          _buildSettingsInfo(),
        ],
      ),
    );
  }

  Widget _buildAiThresholdSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI Threshold', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              SettingsService.getAiThresholdDisplayText(_settings!.aiThreshold),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Slider(
              value: _settings!.aiThreshold,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: '${(_settings!.aiThreshold * 100).round()}%',
              onChanged: _updateAiThreshold,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('0% (More matches)'),
                Text('100% (Better matches)'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionFlexibilitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction Flexibility',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Allow contacts to match with both RENT and SALE properties',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Transaction Flexibility'),
              subtitle: Text(
                _settings!.transactionFlexibilityEnabled
                    ? 'Contacts can match with multiple transaction types'
                    : 'Contacts match with single transaction type only',
              ),
              value: _settings!.transactionFlexibilityEnabled,
              onChanged: _updateTransactionFlexibility,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Default Language',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...AppLanguage.values.map(
              (language) => RadioListTile<AppLanguage>(
                title: Text(language.displayName),
                value: language,
                groupValue: _settings!.defaultLanguage,
                onChanged: (value) {
                  if (value != null) {
                    _updateDefaultLanguage(value);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightVectorSection() {
    final dimensionNames = SettingsService.getWeightVectorDimensionNames();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommendation Weights',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Adjust the importance of different property characteristics',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ...List.generate(12, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dimensionNames[index],
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Slider(
                      value: _settings!.recommendationWeightVector[index],
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      label:
                          '${(_settings!.recommendationWeightVector[index] * 100).round()}%',
                      onChanged: (value) {
                        final newWeights = List<double>.from(
                          _settings!.recommendationWeightVector,
                        );
                        newWeights[index] = value;
                        _updateWeightVector(newWeights);
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Created', _settings!.createdAt.toString()),
            _buildInfoRow('Last Updated', _settings!.updatedAt.toString()),
            _buildInfoRow('Cache Status', 'Available'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

/// Example of how to use SettingsService in a provider pattern
class SettingsProvider extends ChangeNotifier {
  AppSettings? _settings;
  bool _isLoading = false;
  String? _error;

  AppSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load settings from API
  Future<void> loadSettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _settings = await SettingsService.fetchSettings();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update settings
  Future<void> updateSettings(AppSettings newSettings) async {
    try {
      await SettingsService.updateSettings(newSettings);
      _settings = newSettings;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Clear cache
  void clearCache() {
    SettingsService.clearCache();
    notifyListeners();
  }
}
