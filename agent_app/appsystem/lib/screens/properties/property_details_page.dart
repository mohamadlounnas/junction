import 'package:appsystem/services/contacts_service.dart' as contacts_service;
import 'package:appsystem/services/quote_service.dart';
import 'package:appsystem/widgets/contact_selection_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../../services/property_service.dart';
import '../../widgets/enhanced_recommendation_cards.dart';

/// صفحة تفاصيل العقار
/// تعرض معلومات العقار مع التوصيات للعملاء المحتملين
/// الميزات:
/// - عرض شامل لتفاصيل العقار
/// - توصيات ذكية للعملاء باستخدام الذكاء الاصطناعي
/// - معرض الصور
/// - معلومات الاتصال والموقع
/// - تقييم المطابقة مع العملاء
class PropertyDetailsPage extends StatefulWidget {
  final String propertyId;

  const PropertyDetailsPage({super.key, required this.propertyId});

  @override
  State<PropertyDetailsPage> createState() => _PropertyDetailsPageState();
}

class _PropertyDetailsPageState extends State<PropertyDetailsPage>
    with TickerProviderStateMixin {
  Property? _property;
  List<ContactRecommendation> _contactRecommendations = [];
  bool _isLoading = true;
  bool _isLoadingRecommendations = true;
  String _error = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPropertyDetails();
    _loadContactRecommendations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// تحميل تفاصيل العقار
  Future<void> _loadPropertyDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final result = await PropertyService().getProperty(widget.propertyId);

      if (result['success'] == true) {
        setState(() {
          _property = Property.fromJson(Map<String, dynamic>.from(result['data'] as Map<dynamic, dynamic>));
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'فشل في تحميل تفاصيل العقار';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ في تحميل تفاصيل العقار';
        _isLoading = false;
      });
    }
  }

  /// تحميل توصيات العملاء للعقار
  Future<void> _loadContactRecommendations() async {
    try {
      setState(() {
        _isLoadingRecommendations = true;
      });

      final result = await PropertyService().getPropertyRecommendations(
        widget.propertyId,
      );

      if (result['success'] == true) {
        setState(() {
          final data = result['data'];
          if (data is List) {
            _contactRecommendations = data
                .whereType<ContactRecommendation>()
                .toList();
          } else {
            _contactRecommendations = [];
          }
          _isLoadingRecommendations = false;
        });

        // Log metadata for debugging
        final metadata = Map<String, dynamic>.from({...?result['metadata']});
        final filters = Map<String, dynamic>.from({...?result['filters']});
        final total = result['total'] as int?;

        print('Property recommendations loaded:');
        print('- Total recommendations: $total');
        print('- Metadata: $metadata');
        print('- Filters: $filters');
      } else {
        setState(() {
          _contactRecommendations = [];
          _isLoadingRecommendations = false;
        });
        print('Failed to load recommendations: ${result['message']}');
      }
    } catch (e) {
      setState(() {
        _contactRecommendations = [];
        _isLoadingRecommendations = false;
      });
      print('Error loading recommendations: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري تحميل تفاصيل العقار...'),
                ],
              ),
            )
          : _error.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.warning_2,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'خطأ',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadPropertyDetails,
                          icon: const Icon(Iconsax.refresh),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                )
              : isDesktop 
                  ? _buildDesktopLayout()
                  : _buildPropertyDetails(),
    );
  }

  /// Desktop layout with recommendations sidebar
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Main content
        Expanded(
          flex: 2,
          child: _buildPropertyDetails(),
        ),
        
        // Recommendations sidebar
        Expanded(
          flex: 1,
          child: _buildRecommendationsSidebar(),
        ),
      ],
    );
  }

  /// Recommendations sidebar for desktop
  Widget _buildRecommendationsSidebar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.people,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'العملاء المحتملون',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_contactRecommendations.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_contactRecommendations.length}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoadingRecommendations
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('جاري تحميل التوصيات...'),
                      ],
                    ),
                  )
                : _contactRecommendations.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 48,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'لا توجد توصيات',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'سيتم إنشاء توصيات ذكية للعملاء المحتملين',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _contactRecommendations.length,
                        itemBuilder: (context, index) {
                          final recommendation = _contactRecommendations[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: EnhancedContactRecommendationCard(
                              recommendation: recommendation,
                              onTap: () {
                                context.go('/dashboard/contact/${recommendation.contact.id}');
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  /// بناء تفاصيل العقار
  Widget _buildPropertyDetails() {
    if (_property == null) return const SizedBox.shrink();

    return CustomScrollView(
      slivers: [
        // شريط التطبيق مع الصورة
        _buildPropertyAppBar(),

        // محتوى العقار
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // معلومات العقار الأساسية
              _buildBasicInfo(),

              // التبويبات
              _buildTabSection(),
            ],
          ),
        ),
      ],
    );
  }

  /// بناء شريط التطبيق مع صورة العقار
  Widget _buildPropertyAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Iconsax.arrow_right, color: Colors.white),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            // TODO: مشاركة العقار
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Iconsax.share, color: Colors.white),
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // صورة العقار
            Image.network(
              _property!.mainImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: Icon(
                    Iconsax.home,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
            // تدرج
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                ),
              ),
            ),
            // شارة نوع المعاملة
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getTransactionTypeColor(),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _property!.transactionTypeDisplayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء المعلومات الأساسية للعقار
  Widget _buildBasicInfo() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان والسعر
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _property!.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Iconsax.location,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${_property!.city}, ${_property!.wilaya}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _property!.formattedPrice,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // المواصفات السريعة
          _buildQuickSpecs(),

          const SizedBox(height: 24),

          // الوصف
          if (_property!.description != null &&
              _property!.description!.isNotEmpty) ...[
            Text(
              'الوصف',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _property!.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  /// بناء المواصفات السريعة
  Widget _buildQuickSpecs() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildSpecItem(
                icon: Iconsax.home_2,
                label: 'المساحة',
                value: '${_property!.area.toStringAsFixed(0)} م²',
              ),
              const SizedBox(width: 24),
              _buildSpecItem(
                icon: Iconsax.profile_2user,
                label: 'الغرف',
                value: '${_property!.rooms}',
              ),
              const SizedBox(width: 24),
              _buildSpecItem(
                icon: Iconsax.buildings,
                label: 'النوع',
                value: _property!.propertyTypeDisplayName,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSpecItem(
                icon: Iconsax.status,
                label: 'الحالة',
                value: _property!.conditionDisplayName,
              ),
              const SizedBox(width: 24),
              _buildSpecItem(
                icon: Iconsax.car,
                label: 'موقف سيارة',
                value: _property!.hasParking ? 'متوفر' : 'غير متوفر',
              ),
              const SizedBox(width: 24),
              _buildSpecItem(
                icon: Iconsax.security_safe,
                label: 'أمان',
                value: _property!.hasSecurity ? 'متوفر' : 'غير متوفر',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// بناء عنصر مواصفات
  Widget _buildSpecItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// بناء قسم التبويبات
  Widget _buildTabSection() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: Theme.of(context).colorScheme.onPrimary,
            unselectedLabelColor: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'التفاصيل'),
              Tab(text: 'العملاء المهتمين'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 600, // ارتفاع ثابت للمحتوى
          child: TabBarView(
            controller: _tabController,
            children: [_buildDetailsTab(), _buildContactRecommendationsTab()],
          ),
        ),
      ],
    );
  }

  /// بناء تبويب التفاصيل
  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // المرافق
          _buildFeaturesSection(),

          const SizedBox(height: 24),

          // معلومات إضافية
          _buildAdditionalInfo(),
        ],
      ),
    );
  }

  /// بناء قسم المرافق
  Widget _buildFeaturesSection() {
    final features = [
      if (_property!.hasParking) {'icon': Iconsax.car, 'label': 'موقف سيارة'},
      if (_property!.hasSecurity)
        {'icon': Iconsax.security_safe, 'label': 'أمان'},
      if (_property!.hasElevator) {'icon': Iconsax.arrow_up_3, 'label': 'مصعد'},
      if (_property!.hasGarden) {'icon': Iconsax.tree, 'label': 'حديقة'},
      if (_property!.hasBalcony)
        {'icon': Iconsax.home_trend_up, 'label': 'شرفة'},
      if (_property!.hasSwimmingPool) {'icon': Iconsax.drop, 'label': 'مسبح'},
    ];

    if (features.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المرافق المتوفرة',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: features.map((feature) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    feature['icon'] as IconData,
                    size: 16,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    feature['label'] as String,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// بناء المعلومات الإضافية
  Widget _buildAdditionalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'معلومات إضافية',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoCard([
          if (_property!.bathrooms != null)
            _buildInfoRow(
              icon: Iconsax.home_wifi,
              label: 'الحمامات',
              value: '${_property!.bathrooms}',
            ),
          if (_property!.floor != null)
            _buildInfoRow(
              icon: Iconsax.level,
              label: 'الطابق',
              value: '${_property!.floor}',
            ),
          if (_property!.totalFloors != null)
            _buildInfoRow(
              icon: Iconsax.buildings,
              label: 'إجمالي الطوابق',
              value: '${_property!.totalFloors}',
            ),
          if (_property!.buildingAge != null)
            _buildInfoRow(
              icon: Iconsax.calendar,
              label: 'عمر البناء',
              value: '${_property!.buildingAge} سنة',
            ),
          _buildInfoRow(
            icon: Iconsax.status,
            label: 'الحالة',
            value: _property!.statusDisplayName,
          ),
        ]),
      ],
    );
  }

  /// بناء بطاقة المعلومات
  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(children: children),
    );
  }

  /// بناء صف معلومات
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء تبويب توصيات العملاء
  Widget _buildContactRecommendationsTab() {
    if (_isLoadingRecommendations) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري تحميل توصيات العملاء...'),
          ],
        ),
      );
    }

    if (_contactRecommendations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.people,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'لا توجد توصيات عملاء',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'لم يتم العثور على عملاء مطابقين لهذا العقار حالياً',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _contactRecommendations.length,
      itemBuilder: (context, index) {
        final recommendation = _contactRecommendations[index];
        return _buildContactRecommendationCard(recommendation);
      },
    );
  }

  /// بناء بطاقة توصية عميل
  Widget _buildContactRecommendationCard(ContactRecommendation recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: EnhancedContactRecommendationCard(
        recommendation: recommendation,
        onTap: () {
          context.go('/dashboard/contact/${recommendation.contact.id}');
        },
      ),
    );
  }

  /// بناء عنصر معلومات العميل
  Widget _buildContactInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// الحصول على لون نوع المعاملة
  Color _getTransactionTypeColor() {
    switch (_property?.transactionType) {
      case 'SALE':
        return Colors.green;
      case 'RENT':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// Show PDF generation dialog
  Future<void> _showPdfGenerationDialog() async {
    if (_property == null) return;
    if (!mounted) return;

    final selectedContact = await showDialog<contacts_service.Contact>(
      context: context,
      barrierDismissible: true,
      builder: (context) => ContactSelectionDialog(
        propertyId: widget.propertyId,
        propertyTitle: _property!.title,
      ),
    );

    if (selectedContact != null) {
      // Add a small delay to ensure the dialog is properly closed
      await Future.delayed(const Duration(milliseconds: 100));
      await _generatePdfQuote(selectedContact);
    }
  }

  /// Generate PDF quote for the selected contact
  Future<void> _generatePdfQuote(contacts_service.Contact contact) async {
    if (_property == null) return;

    // Show loading dialog
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري إنشاء عرض السعر PDF...'),
          ],
        ),
      ),
    );

    try {
      // Create quote request
      final request = QuoteRequest(
        propertyId: widget.propertyId,
        contactId: contact.id,
        language: 'ar',
        companyInfo: QuoteService.getDefaultCompanyInfo(),
      );

      // Generate PDF quote
      final response = await QuoteService.generatePdfQuote(request);

      // Close loading dialog safely
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Add a small delay to ensure the dialog is properly closed
      await Future.delayed(const Duration(milliseconds: 100));

      if (response.success && response.pdf != null) {
        await _showPdfSuccessDialog(response.pdf!);
      } else {
        _showErrorDialog(response.message ?? 'فشل في إنشاء عرض السعر');
      }
    } catch (e) {
      // Close loading dialog safely
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Add a small delay to ensure the dialog is properly closed
      await Future.delayed(const Duration(milliseconds: 100));

      _showErrorDialog('حدث خطأ أثناء إنشاء عرض السعر: $e');
    }
  }

  /// Show PDF success dialog with download options
  Future<void> _showPdfSuccessDialog(QuoteData pdfData) async {
    if (!mounted) return;

    try {
      final result = await showDialog<String>(
        context: context,
        barrierDismissible: true,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Iconsax.tick_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text('تم إنشاء عرض السعر بنجاح'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('رقم العرض: ${pdfData.quote.quoteNumber}'),
              const SizedBox(height: 8),
              Text(
                'المبلغ الإجمالي: ${QuoteService.formatPrice(pdfData.quote.totalAmount)}',
              ),
              const SizedBox(height: 8),
              Text('صالح حتى: ${_formatDate(pdfData.quote.validUntil)}'),
              const SizedBox(height: 16),
              const Text('اختر الإجراء المطلوب:'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('download'),
              child: const Text('فتح في المتصفح'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('share'),
              child: const Text('مشاركة الرابط'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('copy'),
              child: const Text('نسخ الرابط'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('open'),
              child: const Text('فتح الملف'),
            ),
          ],
        ),
      );

      if (result != null) {
        await _handlePdfAction(result, pdfData);
      }
    } catch (e) {
      // Handle any dialog-related errors silently
      print('Dialog error: $e');
    }
  }

  /// Handle PDF action (download, share, copy, open)
  Future<void> _handlePdfAction(String action, QuoteData pdfData) async {
    try {
      switch (action) {
        case 'download':
          await _downloadPdf(pdfData);
          break;
        case 'share':
          await _sharePdf(pdfData);
          break;
        case 'copy':
          await _copyPdfUrl(pdfData);
          break;
        case 'open':
          await _openPdf(pdfData);
          break;
      }
    } catch (e) {
      _showErrorDialog('حدث خطأ أثناء معالجة الملف: $e');
    }
  }

  /// Download PDF file
  Future<void> _downloadPdf(QuoteData pdfData) async {
    try {
      // Open the download URL directly in browser
      final downloadUrl = 'https://junction.feeef.org${pdfData.downloadUrl}';
      await _openUrl(downloadUrl);
      _showSuccessMessage('تم فتح رابط التحميل في المتصفح');
    } catch (e) {
      throw Exception('خطأ في فتح رابط التحميل: $e');
    }
  }

  /// Share PDF file
  Future<void> _sharePdf(QuoteData pdfData) async {
    try {
      // Share the download URL
      final downloadUrl = 'https://junction.feeef.org${pdfData.downloadUrl}';
      await _shareUrl(downloadUrl, pdfData.fileName);
      // Success message is handled inside _shareUrl or its fallback
    } catch (e) {
      throw Exception('خطأ في مشاركة الرابط: $e');
    }
  }

  /// Copy PDF URL to clipboard
  Future<void> _copyPdfUrl(QuoteData pdfData) async {
    try {
      final downloadUrl = 'https://junction.feeef.org${pdfData.downloadUrl}';
      await Clipboard.setData(ClipboardData(text: downloadUrl));
      // Show success message immediately
      _showSuccessMessage('تم نسخ رابط التحميل إلى الحافظة');
    } catch (e) {
      throw Exception('خطأ في نسخ الرابط: $e');
    }
  }

  /// Open PDF file
  Future<void> _openPdf(QuoteData pdfData) async {
    try {
      // Open the download URL directly in browser
      final downloadUrl = 'https://junction.feeef.org${pdfData.downloadUrl}';
      await _openUrl(downloadUrl);
      _showSuccessMessage('تم فتح الملف في المتصفح');
    } catch (e) {
      throw Exception('خطأ في فتح الملف: $e');
    }
  }

  /// Open URL in browser
  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('لا يمكن فتح الرابط');
    }
  }

  /// Share URL
  Future<void> _shareUrl(String url, String fileName) async {
    try {
      await Share.share(
        'عرض السعر: $fileName\n$url',
        subject: 'عرض سعر عقاري - $fileName',
      );
      // Show success message for successful share
      _showSuccessMessage('تم مشاركة رابط التحميل');
    } catch (e) {
      // Fallback: Copy to clipboard and show message
      print('Share failed, falling back to clipboard: $e');
      await _copyToClipboard(url, fileName);
    }
  }

  /// Copy URL to clipboard as fallback
  Future<void> _copyToClipboard(String url, String fileName) async {
    try {
      await Clipboard.setData(ClipboardData(text: url));
      // Add a small delay to ensure the message is displayed
      await Future.delayed(const Duration(milliseconds: 100));
      _showSuccessMessage('تم نسخ الرابط إلى الحافظة');
    } catch (e) {
      // Final fallback: just show the URL
      _showInfoDialog('رابط التحميل:\n$url');
    }
  }

  /// Show error dialog
  void _showErrorDialog(String message) {
    if (!mounted) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Iconsax.warning_2,
                color: Theme.of(context).colorScheme.error,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text('خطأ'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Handle any dialog-related errors silently
      print('Error dialog error: $e');
    }
  }

  /// Show success message
  void _showSuccessMessage(String message) {
    if (!mounted) return;

    // Hide any existing snackbar first
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'حسناً',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show info dialog
  void _showInfoDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Iconsax.info_circle,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('معلومات'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
