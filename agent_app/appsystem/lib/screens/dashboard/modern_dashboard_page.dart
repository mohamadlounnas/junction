import 'package:flutter/material.dart';
import 'package:appsystem/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:appsystem/services/statistics_service.dart';
import 'package:appsystem/services/property_service.dart';

/// Modern Dashboard Page with Smart Assistant Integration
///
/// Features:
/// - Professional real estate dashboard
/// - Smart assistant with voice-to-text capabilities
/// - Quick action buttons for common tasks
/// - Floating action button for easy access
/// - Bilingual support (Arabic/English)
/// - Modern UI with animations and gradients
/// - Statistics and analytics display
/// - Property management tools
class ModernDashboardPage extends StatefulWidget {
  const ModernDashboardPage({super.key});

  @override
  State<ModernDashboardPage> createState() => _ModernDashboardPageState();
}

class _ModernDashboardPageState extends State<ModernDashboardPage> {
  StatisticsData? _statistics;
  List<Property>? _properties;
  bool _isLoading = true;
  final PropertyService _propertyService = PropertyService();

  // Design tokens
  static const double _kSpacing = 16.0;
  static const double _kSpacingLarge = 24.0;
  static const double _kSpacingXLarge = 32.0;
  static const double _kBorderRadius = 12.0;
  static const double _kBorderRadiusLarge = 16.0;
  static const double _kCardElevation = 2.0;
  static const double _kIconSize = 24.0;
  static const double _kIconSizeLarge = 32.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final futures = await Future.wait([
        StatisticsService.fetchStatistics(),
        _propertyService.getPropertiesList(limit: 6),
      ]);

      setState(() {
        _statistics = futures[0] as StatisticsData;
        _properties = futures[1] as List<Property>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _propertyService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _buildFloatingActionButton(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(_kSpacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeader(context),
            const SizedBox(height: _kSpacingXLarge),

            // Add Property Button
            _buildAddPropertyButton(context),
            const SizedBox(height: _kSpacingXLarge),

            // Statistics Cards
            _buildStatisticsSection(context),
            const SizedBox(height: _kSpacingXLarge),

            // Client Statistics Section
            _buildClientStatisticsSection(context),
            const SizedBox(height: _kSpacingXLarge),

            // ChatBot Section
            _buildChatBotSection(context),
            const SizedBox(height: _kSpacingXLarge),

            // Recent Properties Section
            _buildRecentPropertiesSection(context),
            const SizedBox(height: _kSpacingLarge),
          ],
        ),
      ),
    );
  }

  /// Header section with title and profile icon
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'وكيل عقارات محترف',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Professional Real Estate Agent',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.textTheme.titleMedium?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        _buildProfileIcon(context),
      ],
    );
  }

  /// Profile icon container
  Widget _buildProfileIcon(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(_kSpacing),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(_kBorderRadiusLarge),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Icon(
        Icons.person,
        color: theme.colorScheme.primary,
        size: _kIconSize,
      ),
    );
  }

  /// Add property button
  Widget _buildAddPropertyButton(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: FilledButton.icon(
        onPressed: () => context.go('/dashboard/add-property'),
        icon: const Icon(Icons.add_circle_outline, size: _kIconSize),
        label: Text(
          'إضافة عقار جديد',
        ),
      ),
    );
  }

  /// Statistics section with cards
  Widget _buildStatisticsSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          'إحصائيات العقارات',
          Icons.analytics_outlined,
        ),
        const SizedBox(height: _kSpacingLarge),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_statistics != null)
          _buildStatisticsContent(context)
        else
          _buildEmptyState(context, 'لا توجد إحصائيات متاحة'),
      ],
    );
  }

  /// Statistics content with cards and breakdowns
  Widget _buildStatisticsContent(BuildContext context) {
    return Column(
      children: [
        // Main statistics row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                _statistics!.totalProperties.toString(),
                'العقارات',
                Icons.home_outlined,
                Colors.blue,
              ),
            ),
            const SizedBox(width: _kSpacing),
            Expanded(
              child: _buildStatCard(
                context,
                _statistics!.totalContacts.toString(),
                'العملاء',
                Icons.people_outlined,
                Colors.green,
              ),
            ),
            const SizedBox(width: _kSpacing),
            Expanded(
              child: _buildStatCard(
                context,
                _getAvailablePropertiesCount(),
                'متاح',
                Icons.check_circle_outlined,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: _kSpacingLarge),
        
        // Property types breakdown
        if (_statistics!.propertyTypeStats.isNotEmpty)
          _buildPropertyTypesBreakdown(context),
        
        const SizedBox(height: _kSpacingLarge),
        
        // Top wilayas
        if (_statistics!.wilayaStats.isNotEmpty)
          _buildTopWilayasBreakdown(context),
      ],
    );
  }

  /// Individual stat card
  Widget _buildStatCard(
    BuildContext context,
    String count,
    String title,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(_kSpacing),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(_kBorderRadius),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: _kIconSizeLarge, color: color),
          const SizedBox(height: _kSpacing),
          Text(
            count,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Property types breakdown
  Widget _buildPropertyTypesBreakdown(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(_kSpacing),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(_kBorderRadius),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'أنواع العقارات',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: _kSpacing),
          Wrap(
            spacing: _kSpacing,
            runSpacing: _kSpacing,
            children: _statistics!.propertyTypeStats
                .map((stat) => _buildPropertyTypeChip(context, stat))
                .toList(),
          ),
        ],
      ),
    );
  }

  /// Top wilayas breakdown
  Widget _buildTopWilayasBreakdown(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(_kSpacing),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(_kBorderRadius),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'أفضل الولايات',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: _kSpacing),
          ..._statistics!.wilayaStats
              .take(3)
              .map((stat) => _buildWilayaStatItem(context, stat))
              .toList(),
        ],
      ),
    );
  }

  /// Client statistics section
  Widget _buildClientStatisticsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          'إحصائيات العملاء',
          Icons.star_outline,
        ),
        const SizedBox(height: _kSpacingLarge),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_statistics != null && _statistics!.contactTypeStats.isNotEmpty)
          _buildClientStatisticsContent(context)
        else
          _buildEmptyState(context, 'لا توجد بيانات عملاء متاحة'),
      ],
    );
  }

  /// Client statistics content
  Widget _buildClientStatisticsContent(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(_kSpacingLarge),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(_kBorderRadiusLarge),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Contact type breakdown
          ..._statistics!.contactTypeStats
              .map((stat) => _buildContactTypeItem(context, stat))
              .toList(),
          const SizedBox(height: _kSpacingLarge),
          
          // Total contacts summary
          _buildTotalContactsSummary(context),
        ],
      ),
    );
  }

  /// Contact type item
  Widget _buildContactTypeItem(BuildContext context, ContactTypeStats stat) {
    final theme = Theme.of(context);
    final color = _getContactTypeColor(stat.type);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _getContactTypeIcon(stat.type),
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: _kSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  StatisticsService.getContactTypeDisplayName(stat.type),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${stat.count} عميل',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(_kBorderRadius),
            ),
            child: Text(
              '${((stat.count / _statistics!.totalContacts) * 100).round()}%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Total contacts summary
  Widget _buildTotalContactsSummary(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(_kSpacing),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(_kBorderRadius),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.people,
            color: theme.colorScheme.primary,
            size: _kIconSize,
          ),
          const SizedBox(width: _kSpacing),
          Expanded(
            child: Text(
              'إجمالي العملاء',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            _statistics!.totalContacts.toString(),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// ChatBot section
  Widget _buildChatBotSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          'المساعد الذكي',
          Icons.chat_bubble_outline,
        ),
        const SizedBox(height: _kSpacingLarge),
        _buildChatBotCard(context),
      ],
    );
  }

  /// ChatBot card
  Widget _buildChatBotCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(_kSpacingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surface.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(_kBorderRadiusLarge),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChatBotHeader(context),
          const SizedBox(height: _kSpacingLarge),
          _buildChatBotDescription(context),
          const SizedBox(height: _kSpacingLarge),
          _buildQuickActionButtons(context),
          const SizedBox(height: _kSpacingLarge),
          _buildChatBotActions(context),
        ],
      ),
    );
  }

  /// ChatBot header
  Widget _buildChatBotHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(
            Icons.smart_toy,
            color: theme.colorScheme.primary,
            size: _kIconSize,
          ),
        ),
        const SizedBox(width: _kSpacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'مساعدك الذكي في العقارات',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildOnlineIndicator(context),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Your Smart Real Estate Assistant',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'متصل - Online',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Online indicator
  Widget _buildOnlineIndicator(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  /// ChatBot description
  Widget _buildChatBotDescription(BuildContext context) {
    final theme = Theme.of(context);
    
    return Text(
      'احصل على مساعدة فورية في:\n• البحث عن العقارات\n• معلومات السوق\n• النصائح الاستثمارية\n• إدارة العملاء',
      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
    );
  }

  /// Quick action buttons
  Widget _buildQuickActionButtons(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                context,
                'البحث عن عقار',
                'Find Property',
                Icons.search,
                () => context.go('/dashboard/chatbot'),
              ),
            ),
            const SizedBox(width: _kSpacing),
            Expanded(
              child: _buildQuickActionButton(
                context,
                'تحليل السوق',
                'Market Analysis',
                Icons.analytics,
                () => context.go('/dashboard/chatbot'),
              ),
            ),
          ],
        ),
        const SizedBox(height: _kSpacing),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                context,
                'نصائح استثمارية',
                'Investment Tips',
                Icons.trending_up,
                () => context.go('/dashboard/chatbot'),
              ),
            ),
            const SizedBox(width: _kSpacing),
            Expanded(
              child: _buildQuickActionButton(
                context,
                'إدارة العملاء',
                'Client Management',
                Icons.people,
                () => context.go('/dashboard/chatbot'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// ChatBot actions
  Widget _buildChatBotActions(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.go('/dashboard/chatbot'),
            icon: const Icon(Icons.chat_bubble_outline, size: 20),
            label: Text(
              'ابدأ المحادثة',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: _kSpacing),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_kBorderRadius),
              ),
            ),
          ),
        ),
        const SizedBox(width: _kSpacing),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(_kBorderRadius),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => context.go('/dashboard/chatbot'),
            icon: const Icon(Icons.mic, size: _kIconSize),
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              padding: const EdgeInsets.all(_kSpacing),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_kBorderRadius),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Recent properties section
  Widget _buildRecentPropertiesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          'العقارات المميزة',
          Icons.real_estate_agent_outlined,
        ),
        const SizedBox(height: _kSpacingLarge),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_properties != null && _properties!.isNotEmpty)
          _buildPropertiesList(context)
        else
          _buildEmptyPropertiesState(context),
      ],
    );
  }

  /// Properties list
  Widget _buildPropertiesList(BuildContext context) {
    return Column(
      children: _properties!
          .map((property) => Padding(
                padding: const EdgeInsets.only(bottom: _kSpacingLarge),
                child: _buildPropertyCard(context, property),
              ))
          .toList(),
    );
  }

  /// Property card
  Widget _buildPropertyCard(BuildContext context, Property property) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(_kBorderRadiusLarge),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPropertyImage(context, property),
          _buildPropertyDetails(context, property),
        ],
      ),
    );
  }

  /// Property image section
  Widget _buildPropertyImage(BuildContext context, Property property) {
    final theme = Theme.of(context);
    
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(_kBorderRadiusLarge),
        ),
      ),
      child: Stack(
        children: [
          if (property.mainImageUrl.isNotEmpty)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(_kBorderRadiusLarge),
                ),
                child: Image.network(
                  property.mainImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildImagePlaceholder(context, property),
                ),
              ),
            )
          else
            _buildImagePlaceholder(context, property),

          // Status badge
          Positioned(
            top: _kSpacing,
            right: _kSpacing,
            child: _buildStatusBadge(context, property),
          ),

          // Price badge
          Positioned(
            top: _kSpacing,
            left: _kSpacing,
            child: _buildPriceBadge(context, property),
          ),

          // Featured badge
          if (property.featured == true)
            Positioned(
              top: _kSpacing,
              left: _kSpacing,
              child: _buildFeaturedBadge(context),
            ),
        ],
      ),
    );
  }

  /// Property details section
  Widget _buildPropertyDetails(BuildContext context, Property property) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(_kSpacingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and type
          Row(
            children: [
              Icon(
                _getPropertyTypeIcon(property.propertyType),
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: _kSpacing),
              Expanded(
                child: Text(
                  property.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Location
          Text(
            '${property.city}, ${property.wilaya}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),

          const SizedBox(height: _kSpacingLarge),

          // Property details row
          Row(
            children: [
              _buildPropertyDetail(
                context,
                Icons.straighten,
                '${property.area} م²',
              ),
              const SizedBox(width: _kSpacingLarge),
              _buildPropertyDetail(
                context,
                Icons.bedroom_parent,
                '${property.rooms} غرف',
              ),
              if (property.bathrooms != null) ...[
                const SizedBox(width: _kSpacingLarge),
                _buildPropertyDetail(
                  context,
                  Icons.bathroom,
                  '${property.bathrooms} حمام',
                ),
              ],
              const Spacer(),
              _buildConditionBadge(context, property),
            ],
          ),

          const SizedBox(height: _kSpacingLarge),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showPropertyDetailsSnackBar(context, property),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: Text(
                    'عرض التفاصيل',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: _kSpacing),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showContactOwnerSnackBar(context, property),
                  icon: const Icon(Icons.phone_outlined, size: 18),
                  label: Text(
                    'اتصال',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Floating action button
  Widget _buildFloatingActionButton(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => context.go('/dashboard/chatbot'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Icon(
          Icons.smart_toy,
          color: theme.colorScheme.onPrimary,
          size: 28,
        ),
      ),
    );
  }

  // Helper methods

  /// Section header
  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: _kIconSize,
        ),
        const SizedBox(width: _kSpacing),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Empty state
  Widget _buildEmptyState(BuildContext context, String message) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(_kSpacingLarge),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(_kBorderRadius),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Center(
        child: Text(
          message,
          style: theme.textTheme.bodyMedium,
        ),
      ),
    );
  }

  /// Empty properties state
  Widget _buildEmptyPropertiesState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(_kSpacingLarge),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(_kBorderRadiusLarge),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.home_work_outlined,
            size: 48,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: _kSpacingLarge),
          Text(
            'العقارات المميزة',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'سيتم عرض العقارات المميزة هنا قريباً\nFeatured properties will be shown here soon',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: _kSpacingLarge),
          ElevatedButton.icon(
            onPressed: () => context.go('/dashboard/properties'),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('عرض جميع العقارات'),
          ),
        ],
      ),
    );
  }

  /// Quick action button
  Widget _buildQuickActionButton(
    BuildContext context,
    String titleAr,
    String titleEn,
    IconData icon,
    VoidCallback onPressed,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(_kBorderRadius),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(_kBorderRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: _kSpacing, horizontal: 8),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  titleAr,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  titleEn,
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Property type chip
  Widget _buildPropertyTypeChip(BuildContext context, PropertyTypeStats stat) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: _kSpacing, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getPropertyTypeIcon(stat.propertyType),
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            '${StatisticsService.getPropertyTypeDisplayName(stat.propertyType)} (${stat.count})',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Wilaya stat item
  Widget _buildWilayaStatItem(BuildContext context, WilayaStats stat) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: _kSpacing),
          Expanded(
            child: Text(
              stat.wilaya,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(_kBorderRadius),
            ),
            child: Text(
              stat.count.toString(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Property detail
  Widget _buildPropertyDetail(
    BuildContext context,
    IconData icon,
    String text,
  ) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.textTheme.bodySmall?.color,
        ),
        const SizedBox(width: 4),
        Text(text, style: theme.textTheme.bodySmall),
      ],
    );
  }

  /// Image placeholder
  Widget _buildImagePlaceholder(BuildContext context, Property property) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getPropertyTypeIcon(property.propertyType),
            size: 48,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            property.propertyTypeDisplayName,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Status badge
  Widget _buildStatusBadge(BuildContext context, Property property) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        property.transactionType == 'SALE' ? 'للبيع' : 'للإيجار',
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Price badge
  Widget _buildPriceBadge(BuildContext context, Property property) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        property.formattedPrice,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Featured badge
  Widget _buildFeaturedBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'مميز',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Condition badge
  Widget _buildConditionBadge(BuildContext context, Property property) {
    final theme = Theme.of(context);
    final color = _getConditionColor(property.condition);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        property.conditionDisplayName,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Utility methods

  String _getAvailablePropertiesCount() {
    return _statistics!.propertyStatusStats
            .where((stat) => stat.status == 'AVAILABLE')
            .firstOrNull
            ?.count
            .toString() ??
        '0';
  }

  Color _getConditionColor(String condition) {
    switch (condition) {
      case 'NEW':
        return Colors.green;
      case 'EXCELLENT':
        return Colors.blue;
      case 'GOOD':
        return Colors.orange;
      case 'FAIR':
        return Colors.yellow.shade700;
      case 'POOR':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getPropertyTypeIcon(String propertyType) {
    switch (propertyType) {
      case 'APARTMENT':
        return Icons.apartment;
      case 'VILLA':
        return Icons.villa;
      case 'HOUSE':
        return Icons.home;
      case 'OFFICE':
        return Icons.business;
      case 'LAND':
        return Icons.landscape;
      default:
        return Icons.home;
    }
  }

  IconData _getContactTypeIcon(String type) {
    switch (type) {
      case 'BUYER':
        return Icons.shopping_cart;
      case 'TENANT':
        return Icons.key;
      case 'INVESTOR':
        return Icons.trending_up;
      default:
        return Icons.person;
    }
  }

  Color _getContactTypeColor(String type) {
    switch (type) {
      case 'BUYER':
        return Colors.blue;
      case 'TENANT':
        return Colors.green;
      case 'INVESTOR':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showAddPropertySnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'إضافة عقار جديد - Add New Property',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _showPropertyDetailsSnackBar(BuildContext context, Property property) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('عرض تفاصيل ${property.title}'),
      ),
    );
  }

  void _showContactOwnerSnackBar(BuildContext context, Property property) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('اتصال بصاحب ${property.title}'),
      ),
    );
  }
}
