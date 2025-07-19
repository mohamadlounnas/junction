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
}

class SettingsService {
  static Future<List<Setting>> fetchSettings() async {
    final response = await http.get(
      Uri.parse('https://junction.feeef.org/api/settings/'),
    );

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      final List data = jsonBody['data'];
      return data.map((e) => Setting.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load settings');
    }
  }
}

class SettingTile extends StatelessWidget {
  final Setting setting;
  final ValueNotifier<String> notifier;

  const SettingTile({super.key, required this.setting, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ListTile(
                title: Text(
                  setting.key,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(setting.description),
              ),
            ),
            ValueListenableBuilder(
              valueListenable: notifier,
              builder: (context, value, _) {
                if (setting.type == 'BOOLEAN') {
                  return Switch(
                    value: value == 'true',
                    onChanged: (newValue) {
                      notifier.value = newValue.toString();
                    },
                  );
                } else if (setting.type == 'NUMBER') {
                  return SizedBox(
                    width: 140,
                    child: Column(
                      children: [
                        Slider(
                          value: double.tryParse(value) ?? 0,
                          min: 0,
                          max: 1,
                          divisions: 100,
                          label: value,
                          onChanged: (val) {
                            notifier.value = val.toStringAsFixed(2);
                          },
                        ),
                        Text(value),
                      ],
                    ),
                  );
                } else {
                  return Text(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Modern Settings Screen for Smart Contact Real Estate Application
///
/// Provides a comprehensive interface for managing application settings
/// using the SettingsProvider with ChangeNotifier pattern for state management.
/// Includes loading states, change tracking, and save functionality.

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Map<String, ValueNotifier<String>> settingNotifiers = {};
  late Future<List<Setting>> settingsFuture;

  @override
  void initState() {
    super.initState();
    settingsFuture = SettingsService.fetchSettings();
  }

  @override
  void dispose() {
    for (var notifier in settingNotifiers.values) {
      notifier.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: FutureBuilder<List<Setting>>(
        future: settingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final settings = snapshot.data!;
          final categories = settings.map((s) => s.category).toSet();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: categories.map((category) {
                final filtered = settings
                    .where((s) => s.category == category)
                    .toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.toUpperCase(),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: filtered.map((setting) {
                        settingNotifiers.putIfAbsent(
                          setting.key,
                          () => ValueNotifier<String>(setting.value),
                        );
                        return SizedBox(
                          width: isWide ? 400 : double.infinity,
                          child: SettingTile(
                            setting: setting,
                            notifier: settingNotifiers[setting.key]!,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
