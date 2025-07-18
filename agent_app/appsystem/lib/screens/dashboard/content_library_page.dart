import 'package:flutter/material.dart';
import 'package:appsystem/theme.dart';

class PropertyListPage extends StatelessWidget {
  const PropertyListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A1A), Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context),

              // Property List
              Expanded(child: _buildPropertyList(context)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to add property page
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'إضافة عقار جديد - Add New Property',
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: AppTheme.textWhite,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'قائمة العقارات',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textWhite,
                ),
                textAlign: TextAlign.right,
              ),
              IconButton(
                onPressed: () {
                  // TODO: Show search/filter options
                },
                icon: const Icon(
                  Icons.search,
                  color: AppTheme.textWhite,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Property List',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppTheme.textGrey),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildFilterChip(context, 'الكل', 'All', true),
              const SizedBox(width: 8),
              _buildFilterChip(context, 'للبيع', 'For Sale', false),
              const SizedBox(width: 8),
              _buildFilterChip(context, 'للإيجار', 'For Rent', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String labelAr,
    String labelEn,
    bool isSelected,
  ) {
    return FilterChip(
      label: Text(
        labelAr,
        style: TextStyle(
          color: isSelected ? AppTheme.textWhite : AppTheme.textGrey,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        // TODO: Implement filter logic
      },
      backgroundColor: AppTheme.cardBackground,
      selectedColor: AppTheme.primaryGreen,
      checkmarkColor: AppTheme.textWhite,
      side: BorderSide(
        color: isSelected ? AppTheme.primaryGreen : AppTheme.borderColor,
      ),
    );
  }

  Widget _buildPropertyList(BuildContext context) {
    // Sample property data
    final properties = [
      {
        'title': 'test',
        'date': '12-04-2025',
        'statusAr': 'إعلان جديد',
        'statusEn': 'New Ad',
        'type': 'للبيع',
        'price': '250,000 ريال',
        'location': 'الرياض، السعودية',
      },
      {
        'title': 'tirgoirth rtkjgnttjbg',
        'date': '12-04-2025',
        'statusAr': 'إعلان جديد',
        'statusEn': 'New Ad',
        'type': 'للإيجار',
        'price': '5,000 ريال/شهر',
        'location': 'جدة، السعودية',
      },
      {
        'title': 'فيلا فاخرة في الرياض',
        'date': '11-04-2025',
        'statusAr': 'مباع',
        'statusEn': 'Sold',
        'type': 'للبيع',
        'price': '1,200,000 ريال',
        'location': 'الرياض، السعودية',
      },
      {
        'title': 'شقة حديثة في جدة',
        'date': '10-04-2025',
        'statusAr': 'متاح',
        'statusEn': 'Available',
        'type': 'للإيجار',
        'price': '8,000 ريال/شهر',
        'location': 'جدة، السعودية',
      },
      {
        'title': 'أرض سكنية في الدمام',
        'date': '09-04-2025',
        'statusAr': 'محجوز',
        'statusEn': 'Reserved',
        'type': 'للبيع',
        'price': '450,000 ريال',
        'location': 'الدمام، السعودية',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final property = properties[index];
        return _buildPropertyCard(context, property);
      },
    );
  }

  Widget _buildPropertyCard(
    BuildContext context,
    Map<String, String> property,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to property details
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'عرض تفاصيل العقار - View Property Details',
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      property['title']!,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textWhite,
                      ),
                    ),
                  ),
                  _buildStatusChip(
                    property['statusAr']!,
                    property['statusEn']!,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Property details
              Row(
                children: [
                  Icon(Icons.location_on, color: AppTheme.textGrey, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      property['location']!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Price and type
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    property['price']!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primaryGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      property['type']!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date and actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    property['date']!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          // TODO: Edit property
                        },
                        icon: const Icon(
                          Icons.edit,
                          color: AppTheme.textGrey,
                          size: 20,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          // TODO: Delete property
                        },
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String statusAr, String statusEn) {
    Color statusColor;
    switch (statusAr) {
      case 'إعلان جديد':
      case 'متاح':
        statusColor = AppTheme.primaryGreen;
        break;
      case 'مباع':
        statusColor = Colors.blue;
        break;
      case 'محجوز':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = AppTheme.textGrey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Text(
        statusAr,
        style: TextStyle(
          color: statusColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
