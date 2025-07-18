import 'package:appsystem/services/property_service.dart';

/// Test script to verify property API pagination functionality
/// Run this with: dart test_property_api.dart
void main() async {
  print('🧪 Testing Property API Pagination...\n');

  final propertyService = PropertyService();

  try {
    print('📡 Fetching all properties with pagination...');
    final startTime = DateTime.now();

    final properties = await propertyService.getPropertiesList();

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);

    print('✅ Successfully fetched ${properties.length} properties');
    print('⏱️  Total time: ${duration.inMilliseconds}ms');
    print(
      '📊 Average time per property: ${duration.inMilliseconds / properties.length}ms',
    );

    // Show property distribution by type
    final typeCounts = <String, int>{};
    for (final property in properties) {
      final type = property.type.name;
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
    }

    print('\n📈 Property Distribution by Type:');
    typeCounts.forEach((type, count) {
      final percentage = (count / properties.length * 100).toStringAsFixed(1);
      print('  $type: $count (${percentage}%)');
    });

    // Show property distribution by wilaya
    final wilayaCounts = <String, int>{};
    for (final property in properties) {
      final wilaya = property.wilaya ?? 'Unknown';
      wilayaCounts[wilaya] = (wilayaCounts[wilaya] ?? 0) + 1;
    }

    print('\n🗺️  Property Distribution by Wilaya:');
    final sortedWilayas = wilayaCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedWilayas.take(10)) {
      final percentage = (entry.value / properties.length * 100)
          .toStringAsFixed(1);
      print('  ${entry.key}: ${entry.value} (${percentage}%)');
    }

    // Show price statistics
    final prices = properties
        .map(
          (p) =>
              double.tryParse(p.price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0,
        )
        .toList();
    prices.sort();

    if (prices.isNotEmpty) {
      final minPrice = prices.first;
      final maxPrice = prices.last;
      final avgPrice = prices.reduce((a, b) => a + b) / prices.length;

      print('\n💰 Price Statistics:');
      print('  Min: ${_formatPrice(minPrice)}');
      print('  Max: ${_formatPrice(maxPrice)}');
      print('  Avg: ${_formatPrice(avgPrice)}');
    }

    // Test system stats
    print('\n📊 Testing system statistics...');
    final stats = await propertyService.getSystemStats();

    if (stats['success'] == true) {
      print('✅ System stats retrieved successfully');
      final data = stats['data'] as Map<String, dynamic>;

      if (data['properties'] != null) {
        final propsData = data['properties'] as Map<String, dynamic>;
        final totalProps = propsData['total'] ?? 0;
        print('📈 API reports $totalProps total properties');

        if (totalProps == properties.length) {
          print('✅ Property count matches!');
        } else {
          print(
            '⚠️  Property count mismatch: API=$totalProps, Fetched=${properties.length}',
          );
        }
      }
    } else {
      print('❌ Failed to get system stats: ${stats['message']}');
    }
  } catch (e) {
    print('❌ Error during testing: $e');
  } finally {
    propertyService.dispose();
    print('\n🏁 Test completed');
  }
}

String _formatPrice(double price) {
  if (price >= 1000000) {
    return '${(price / 1000000).toStringAsFixed(1)}M دج';
  } else if (price >= 1000) {
    return '${(price / 1000).toStringAsFixed(0)}K دج';
  }
  return '${price.toStringAsFixed(0)} دج';
}
