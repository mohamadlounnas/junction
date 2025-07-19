import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../services/settings_service.dart';
import '../../providers/settings_provider.dart';

class Setting {
  final String id;
  final String key;
  String value;
  final String type;
  final String category;
  final String description;

  Setting({
    required this.id,
    required this.key,
    required this.value,
    required this.type,
    required this.category,
    required this.description,
  });

  factory Setting.fromJson(Map<String, dynamic> json) {
    return Setting(
      id: json['id'],
      key: json['key'],
      value: json['value'],
      type: json['type'],
      category: json['category'],
      description: json['description'],
    );
  }

  /// Get appropriate icon for the setting based on key or category
  IconData get icon {
    final keyLower = key.toLowerCase();
    final categoryLower = category.toLowerCase();

    if (keyLower.contains('notification') ||
        categoryLower.contains('notification')) {
      return Icons.notifications_outlined;
    } else if (keyLower.contains('privacy') ||
        categoryLower.contains('privacy')) {
      return Icons.privacy_tip_outlined;
    } else if (keyLower.contains('theme') ||
        keyLower.contains('dark') ||
        keyLower.contains('light')) {
      return Icons.palette_outlined;
    } else if (keyLower.contains('language') ||
        categoryLower.contains('language')) {
      return Icons.language_outlined;
    } else if (keyLower.contains('sound') || keyLower.contains('audio')) {
      return Icons.volume_up_outlined;
    } else if (keyLower.contains('sync') || keyLower.contains('backup')) {
      return Icons.sync_outlined;
    } else if (keyLower.contains('security') ||
        categoryLower.contains('security')) {
      return Icons.security_outlined;
    } else if (keyLower.contains('performance') ||
        categoryLower.contains('performance')) {
      return Icons.speed_outlined;
    } else if (keyLower.contains('ai') || keyLower.contains('machine')) {
      return Icons.psychology_outlined;
    } else if (keyLower.contains('data') || categoryLower.contains('data')) {
      return Icons.storage_outlined;
    } else {
      return Icons.settings_outlined;
    }
  }

  /// Determine if this is an advanced setting
  bool get isAdvanced {
    final keyLower = key.toLowerCase();
    final categoryLower = category.toLowerCase();

    return keyLower.contains('advanced') ||
        keyLower.contains('debug') ||
        keyLower.contains('experimental') ||
        keyLower.contains('beta') ||
        categoryLower.contains('advanced') ||
        categoryLower.contains('developer') ||
        categoryLower.contains('experimental');
  }

  /// Get the numeric value as double with proper parsing
  double get numericValue {
    if (type != 'NUMBER') return 0.0;
    return double.tryParse(value) ?? 0.0;
  }

  /// Determine appropriate min/max range for this setting
  ({double min, double max}) get range {
    if (type != 'NUMBER') return (min: 0.0, max: 1.0);

    final numValue = numericValue;

    // Adaptive range based on the actual value
    if (numValue <= 1.0) {
      return (min: 0.0, max: 1.0);
    } else if (numValue <= 10.0) {
      return (min: 0.0, max: 10.0);
    } else if (numValue <= 100.0) {
      return (min: 0.0, max: 100.0);
    } else if (numValue <= 1000.0) {
      return (min: 0.0, max: 1000.0);
    } else {
      // For very large values, use a percentage-based approach
      return (min: 0.0, max: numValue * 1.2); // 20% buffer above current value
    }
  }

  /// Get display value for the setting
  String get displayValue {
    if (type == 'NUMBER') {
      final numValue = numericValue;
      final range = this.range;

      if (range.max <= 1.0) {
        return '${(numValue * 100).round()}%';
      } else if (range.max <= 10.0) {
        return numValue.toStringAsFixed(1);
      } else {
        return numValue.round().toString();
      }
    }
    return value;
  }
}

class SettingsService {
  static const String _baseUrl = 'https://junction.feeef.org/api/settings/';

  static Future<List<Setting>> fetchSettings() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        final List data = jsonBody['data'] ?? jsonBody;
        return data.map((e) => Setting.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load settings: ${response.statusCode}');
      }
    } catch (e) {
      // Return mock data for development/demo purposes
      return _getMockSettings();
    }
  }

  /// Update a single setting via POST request
  ///
  /// Sends a POST request to update the setting with the provided data.
  /// Returns true if successful, throws exception on failure.
  static Future<bool> updateSetting(Setting setting) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'key': setting.key,
          'value': setting.value,
          'type': setting.type,
          'category': setting.category,
          'description': setting.description,
          'isPublic': false, // Default value, adjust as needed
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception(
          'Failed to update setting: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Network error while updating setting: $e');
    }
  }

  /// Update multiple settings in batch
  ///
  /// Sends multiple settings updates in sequence.
  /// Returns a map of results for each setting.
  static Future<Map<String, bool>> updateSettingsBatch(
    List<Setting> settings,
  ) async {
    final results = <String, bool>{};

    for (final setting in settings) {
      try {
        final success = await updateSetting(setting);
        results[setting.key] = success;
      } catch (e) {
        results[setting.key] = false;
        print('Failed to update setting ${setting.key}: $e');
      }
    }

    return results;
  }

  /// Mock settings for development/demo
  static List<Setting> _getMockSettings() {
    return [
      Setting(
        id: '1',
        key: 'Dark Mode',
        value: 'false',
        type: 'BOOLEAN',
        category: 'Appearance',
        description: 'Enable dark theme for better viewing in low light',
      ),
      Setting(
        id: '2',
        key: 'Notifications',
        value: 'true',
        type: 'BOOLEAN',
        category: 'Notifications',
        description: 'Receive push notifications for important updates',
      ),
      Setting(
        id: '3',
        key: 'AI Threshold',
        value: '0.75',
        type: 'NUMBER',
        category: 'AI Settings',
        description: 'Adjust the sensitivity of AI recommendations',
      ),
      Setting(
        id: '4',
        key: 'Auto Sync',
        value: 'true',
        type: 'BOOLEAN',
        category: 'Data',
        description: 'Automatically sync data in the background',
      ),
      Setting(
        id: '5',
        key: 'Performance Mode',
        value: '0.5',
        type: 'NUMBER',
        category: 'Performance',
        description: 'Balance between performance and battery life',
      ),
      Setting(
        id: '6',
        key: 'Language',
        value: 'en',
        type: 'STRING',
        category: 'Localization',
        description: 'Choose your preferred language',
      ),
      Setting(
        id: '7',
        key: 'Advanced Analytics',
        value: 'false',
        type: 'BOOLEAN',
        category: 'Advanced',
        description: 'Enable detailed analytics and tracking',
      ),
      Setting(
        id: '8',
        key: 'Cache Size',
        value: '0.8',
        type: 'NUMBER',
        category: 'Advanced',
        description: 'Maximum cache size as percentage of available storage',
      ),
      Setting(
        id: '9',
        key: 'Privacy Mode',
        value: 'true',
        type: 'BOOLEAN',
        category: 'Privacy',
        description: 'Enhanced privacy protection for sensitive data',
      ),
      Setting(
        id: '10',
        key: 'Sound Effects',
        value: '0.6',
        type: 'NUMBER',
        category: 'Audio',
        description: 'Volume level for interface sound effects',
      ),
    ];
  }
}

/// Custom animated switch widget
class AnimatedSettingSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  const AnimatedSettingSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  @override
  State<AnimatedSettingSwitch> createState() => _AnimatedSettingSwitchState();
}

class _AnimatedSettingSwitchState extends State<AnimatedSettingSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Switch.adaptive(
              value: widget.value,
              onChanged: (value) {
                widget.onChanged(value);
                HapticFeedback.lightImpact();
              },
            ),
          );
        },
      ),
    );
  }
}

/// Custom animated slider widget with adaptive range
class AnimatedSettingSlider extends StatefulWidget {
  final Setting setting;
  final ValueChanged<double> onChanged;

  const AnimatedSettingSlider({
    super.key,
    required this.setting,
    required this.onChanged,
  });

  @override
  State<AnimatedSettingSlider> createState() => _AnimatedSettingSliderState();
}

class _AnimatedSettingSliderState extends State<AnimatedSettingSlider>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.setting.numericValue;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final range = widget.setting.range;
    final theme = Theme.of(context);

    // Ensure current value is within bounds
    _currentValue = _currentValue.clamp(range.min, range.max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.setting.displayValue,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            if (range.max <= 1.0)
              Text(
                '${(_currentValue * 100).round()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: theme.colorScheme.primary.withOpacity(0.2),
            thumbColor: theme.colorScheme.primary,
            overlayColor: theme.colorScheme.primary.withOpacity(0.1),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: _currentValue,
            min: range.min,
            max: range.max,
            divisions: range.max <= 10 ? 100 : null,
            onChanged: (value) {
              setState(() {
                _currentValue = value;
              });
              widget.onChanged(value);
            },
            onChangeEnd: (value) {
              _controller.forward().then((_) => _controller.reverse());
            },
          ),
        ),
      ],
    );
  }
}

/// Individual setting tile widget
class SettingTile extends StatelessWidget {
  final Setting setting;
  final ValueNotifier<String> notifier;
  final VoidCallback? onTap;
  final Function(String, String)? onChanged;

  const SettingTile({
    super.key,
    required this.setting,
    required this.notifier,
    this.onTap,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width > 600;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Card(
        elevation: 2,
        shadowColor: theme.colorScheme.shadow.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    setting.icon,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        setting.key,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        setting.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Control
                ValueListenableBuilder<String>(
                  valueListenable: notifier,
                  builder: (context, value, _) {
                    switch (setting.type) {
                      case 'BOOLEAN':
                        return AnimatedSettingSwitch(
                          value: value.toLowerCase() == 'true',
                          onChanged: (newValue) {
                            final newValueStr = newValue.toString();
                            notifier.value = newValueStr;
                            onChanged?.call(setting.key, newValueStr);
                          },
                          label: setting.key,
                        );

                      case 'NUMBER':
                        return SizedBox(
                          width: isWide ? 200 : 160,
                          child: AnimatedSettingSlider(
                            setting: setting,
                            onChanged: (newValue) {
                              final newValueStr = newValue.toStringAsFixed(2);
                              notifier.value = newValueStr;
                              onChanged?.call(setting.key, newValueStr);
                            },
                          ),
                        );

                      default:
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            value,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Category section widget
class CategorySection extends StatelessWidget {
  final String category;
  final List<Setting> settings;
  final Map<String, ValueNotifier<String>> notifiers;
  final bool isWide;
  final Function(String, String)? onSettingChanged;

  const CategorySection({
    super.key,
    required this.category,
    required this.settings,
    required this.notifiers,
    required this.isWide,
    this.onSettingChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Padding(
          padding: const EdgeInsets.only(bottom: 16, top: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                category.toUpperCase(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        // Settings grid/list
        if (isWide)
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: settings.map((setting) {
              notifiers.putIfAbsent(
                setting.key,
                () => ValueNotifier<String>(setting.value),
              );
              return SizedBox(
                width: 400,
                child: SettingTile(
                  setting: setting,
                  notifier: notifiers[setting.key]!,
                  onChanged: onSettingChanged,
                ),
              );
            }).toList(),
          )
        else
          Column(
            children: settings.map((setting) {
              notifiers.putIfAbsent(
                setting.key,
                () => ValueNotifier<String>(setting.value),
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SettingTile(
                  setting: setting,
                  notifier: notifiers[setting.key]!,
                  onChanged: onSettingChanged,
                ),
              );
            }).toList(),
          ),

        const SizedBox(height: 32),
      ],
    );
  }
}

/// Modern Settings Screen for Smart Contact Real Estate Application
///
/// A professional SaaS-level settings interface that fetches dynamic data
/// from the API, groups settings by category, and provides responsive
/// design with smooth animations and modern Material 3 styling.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  final Map<String, ValueNotifier<String>> _settingNotifiers = {};
  final Map<String, Setting> _originalSettings = {};
  final Set<String> _changedSettings = {};

  late Future<List<Setting>> _settingsFuture;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _showAdvanced = false;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _settingsFuture = SettingsService.fetchSettings();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();
    _slideController.forward();
  }

  /// Track changes to settings
  void _onSettingChanged(String key, String newValue) {
    final notifier = _settingNotifiers[key];
    if (notifier != null) {
      notifier.value = newValue;

      // Check if value has changed from original
      final originalSetting = _originalSettings[key];
      if (originalSetting != null && originalSetting.value != newValue) {
        _changedSettings.add(key);
      } else {
        _changedSettings.remove(key);
      }

      setState(() {}); // Rebuild to show/hide save button
    }
  }

  /// Save all changed settings
  Future<void> _saveChanges() async {
    if (_changedSettings.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final settingsToUpdate = _changedSettings
          .map((key) => _originalSettings[key])
          .where((setting) => setting != null)
          .cast<Setting>()
          .map((setting) {
            // Create updated setting with new value
            return Setting(
              id: setting.id,
              key: setting.key,
              value: _settingNotifiers[setting.key]?.value ?? setting.value,
              type: setting.type,
              category: setting.category,
              description: setting.description,
            );
          })
          .toList();

      final results = await SettingsService.updateSettingsBatch(
        settingsToUpdate,
      );

      // Update original settings for successful updates
      for (final setting in settingsToUpdate) {
        if (results[setting.key] == true) {
          _originalSettings[setting.key] = setting;
          _changedSettings.remove(setting.key);
        }
      }

      // Show success/error feedback
      if (results.values.every((success) => success)) {
        _showSnackBar('Settings saved successfully!', isError: false);
      } else {
        final failedCount = results.values.where((success) => !success).length;
        _showSnackBar('Failed to save $failedCount settings', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error saving settings: $e', isError: true);
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  /// Show feedback message
  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Initialize settings tracking
  void _initializeSettingsTracking(List<Setting> settings) {
    _originalSettings.clear();
    _changedSettings.clear();

    for (final setting in settings) {
      _originalSettings[setting.key] = setting;
      _settingNotifiers.putIfAbsent(
        setting.key,
        () => ValueNotifier<String>(setting.value),
      );
    }
  }

  @override
  void dispose() {
    for (var notifier in _settingNotifiers.values) {
      notifier.dispose();
    }
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          // Save button
          if (_changedSettings.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      onPressed: _saveChanges,
                      icon: const Icon(Icons.save),
                      tooltip: 'Save changes',
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.primaryContainer,
                      ),
                    ),
            ),

          // Advanced toggle
          FutureBuilder<List<Setting>>(
            future: _settingsFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final hasAdvanced = snapshot.data!.any((s) => s.isAdvanced);
                if (hasAdvanced) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Basic',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: !_showAdvanced
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: !_showAdvanced
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        Switch.adaptive(
                          value: _showAdvanced,
                          onChanged: (value) {
                            setState(() {
                              _showAdvanced = value;
                            });
                          },
                        ),
                        Text(
                          'Advanced',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _showAdvanced
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: _showAdvanced
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Setting>>(
        future: _settingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Loading settings...',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load settings',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please check your connection and try again',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _settingsFuture = SettingsService.fetchSettings();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final settings = snapshot.data!;

          // Initialize settings tracking on first load
          if (_originalSettings.isEmpty) {
            _initializeSettingsTracking(settings);
          }

          // Filter settings based on advanced toggle
          final filteredSettings = _showAdvanced
              ? settings
              : settings.where((s) => !s.isAdvanced).toList();

          // Group by category
          final categories =
              filteredSettings.map((s) => s.category).toSet().toList()..sort();

          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isWide ? 32 : 16,
                  16,
                  isWide ? 32 : 16,
                  16,
                ),
                child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final categorySettings = filteredSettings
                        .where((s) => s.category == category)
                        .toList();

                    return CategorySection(
                      category: category,
                      settings: categorySettings,
                      notifiers: _settingNotifiers,
                      isWide: isWide,
                      onSettingChanged: _onSettingChanged,
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
